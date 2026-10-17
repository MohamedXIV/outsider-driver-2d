class_name SandboxStreetModule
extends RefCounted

# The same authored layout drives native sidewalk polygons, crosswalk links,
# lane position, painted street modules, and deterministic offscreen handoff.
# This Patchworks prototype is intentionally 1 street unit, not a global
# traffic grid or a replacement for the city road graph.
const CROSS_X: float = 320.0
const NORTH_Y: float = 313.0
const SOUTH_Y: float = 391.0
const LANE_Y: float = 350.0
const START: Vector2 = Vector2(155.0, NORTH_Y)
const SITE: Vector2 = Vector2(500.0, SOUTH_Y)
const VEHICLE_START: Vector2 = Vector2(110.0, LANE_Y)
const OFFSCREEN_MINUTES: float = 8.0
const NORTH_SIDEWALK: Rect2 = Rect2(100, 300, 460, 26)
const SOUTH_SIDEWALK: Rect2 = Rect2(100, 378, 460, 26)
const ROAD: Rect2 = Rect2(95, 328, 475, 48)
const PEDESTRIAN_RADIUS: float = 7.0
# Clearance is the WHOLE pedestrian collision body beyond the road edge,
# plus a small margin, not merely their center reaching the zebra paint.
const CROSS_CLEAR_Y: float = ROAD.end.y + PEDESTRIAN_RADIUS + 1.0
const FRONTAGES: Array[Rect2] = [
	Rect2(160,235,90,62), Rect2(270,235,80,62),
	Rect2(390,235,110,62), Rect2(450,405,110,66)
]

static func waypoints() -> PackedVector2Array:
	return PackedVector2Array([START,Vector2(CROSS_X,NORTH_Y),
			Vector2(CROSS_X,SOUTH_Y),SITE])

static func position_at(progress: float) -> Vector2:
	var path: PackedVector2Array = waypoints()
	var total: float = 0.0
	for i in range(path.size()-1):
		total += path[i].distance_to(path[i+1])
	var remaining: float = clampf(progress,0,1)*total
	for i in range(path.size()-1):
		var segment_length: float = path[i].distance_to(path[i+1])
		if remaining<=segment_length:
			return path[i].lerp(path[i+1],remaining/segment_length)
		remaining-=segment_length
	return path[path.size()-1]

static func progress_of(where: Vector2) -> float:
	var path: PackedVector2Array = waypoints()
	var total: float = 0.0
	for i in range(path.size()-1):
		total += path[i].distance_to(path[i+1])
	var best_distance: float = INF
	var best_progress: float = 0.0
	var prior: float = 0.0
	for i in range(path.size()-1):
		var segment: Vector2 = path[i+1]-path[i]
		var length: float = segment.length()
		var t: float = clampf((where-path[i]).dot(segment)/segment.length_squared(),0,1)
		var distance: float = where.distance_squared_to(path[i]+segment*t)
		if distance<best_distance:
			best_distance=distance
			best_progress=(prior+t*length)/total
		prior+=length
	return clampf(best_progress,0,1)

static func crossing_started(progress: float) -> bool:
	return progress >= progress_of(Vector2(CROSS_X,NORTH_Y)) - 0.015

static func crossing_clear(where: Vector2) -> bool:
	return where.y >= CROSS_CLEAR_Y

static func crossing_finished(progress: float) -> bool:
	return progress >= progress_of(Vector2(CROSS_X,CROSS_CLEAR_Y))

static func install_navigation(parent: Node2D) -> void:
	_add_sidewalk(parent,NORTH_SIDEWALK,"NorthSidewalk")
	_add_sidewalk(parent,SOUTH_SIDEWALK,"SouthSidewalk")
	var link: NavigationLink2D = NavigationLink2D.new()
	link.name="MarkedCrosswalkOnly"
	link.navigation_layers=1
	link.bidirectional=true
	link.start_position=Vector2(CROSS_X,NORTH_Y)
	link.end_position=Vector2(CROSS_X,SOUTH_Y)
	parent.add_child(link)

static func _add_sidewalk(parent: Node2D, rect: Rect2, label: String) -> void:
	var polygon: NavigationPolygon = NavigationPolygon.new()
	polygon.vertices=PackedVector2Array([
		rect.position,Vector2(rect.end.x,rect.position.y),
		rect.end,Vector2(rect.position.x,rect.end.y)])
	polygon.add_polygon(PackedInt32Array([0,1,2,3]))
	var region: NavigationRegion2D=NavigationRegion2D.new()
	region.name=label
	region.navigation_layers=1
	region.navigation_polygon=polygon
	parent.add_child(region)

static func paint(canvas: Node2D) -> void:
	canvas.draw_rect(ROAD,Color("3f5555"))
	canvas.draw_rect(NORTH_SIDEWALK,Color("80908a"))
	canvas.draw_rect(SOUTH_SIDEWALK,Color("80908a"))
	canvas.draw_line(Vector2(95,353),Vector2(570,353),Color("d1b985"),1.5)
	for x in range(112,570,40):
		if x>300 and x<345:
			continue
		canvas.draw_line(Vector2(x,353),Vector2(x+19,353),Color("e1be85"),2)
	for y in range(330,377,8):
		canvas.draw_rect(Rect2(CROSS_X-13,y,26,4),Color("e5d6a4"))
	var facade_colors: Array[Color] = [
		Color("768987"),Color("9d896f"),Color("768987"),Color("8b7867")]
	for i in range(FRONTAGES.size()):
		canvas.draw_rect(FRONTAGES[i],facade_colors[i])
	canvas.draw_rect(Rect2(462,416,26,36),Color("d2c49f"))
	canvas.draw_string(ThemeDB.fallback_font,Vector2(454,440),"PARTS",
			HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("28383a"))


# Adjacent straight block with a T junction. Deliberately uses the same street
# grammar as the western module; polygons meet by SHARED EDGES instead of
# arbitrary screen overlap. Only explicit links cross vehicle asphalt.
const EAST_BLOCK: Rect2 = Rect2(560, 328, 460, 48)
const T_BRANCH: Rect2 = Rect2(800, 160, 48, 168)
const EAST_CROSS_X: float = 950.0
const BRANCH_CROSS_Y: float = 313.0

static func _crossing(parent: Node2D, label: String, origin: Vector2, goal: Vector2) -> void:
	var link: NavigationLink2D = NavigationLink2D.new()
	link.name = label
	link.navigation_layers = 1
	link.bidirectional = true
	link.start_position = origin
	link.end_position = goal
	parent.add_child(link)

static func install_east_junction(parent: Node2D) -> void:
	# Main avenue: split north sidewalk at the branch and retain a connected
	# south sidewalk. A junction is not a walkable shortcut across asphalt.
	_add_sidewalk(parent, Rect2(560,300,240,26), "EastNorthWest")
	_add_sidewalk(parent, Rect2(848,300,172,26), "EastNorthEast")
	_add_sidewalk(parent, Rect2(560,378,460,26), "EastSouthSidewalk")
	_add_sidewalk(parent, Rect2(774,160,24,140), "BranchWestSidewalk")
	_add_sidewalk(parent, Rect2(850,160,24,140), "BranchEastSidewalk")
	_crossing(parent, "EastMarkedCrosswalk",
			Vector2(EAST_CROSS_X,NORTH_Y),Vector2(EAST_CROSS_X,SOUTH_Y))
	_crossing(parent, "BranchMarkedCrosswalk",
			Vector2(799,BRANCH_CROSS_Y),Vector2(849,BRANCH_CROSS_Y))

static func paint_east_junction(canvas: Node2D) -> void:
	canvas.draw_rect(EAST_BLOCK,Color("3f5555"))
	canvas.draw_rect(T_BRANCH,Color("3f5555"))
	for rect in [Rect2(560,300,240,26),Rect2(848,300,172,26),
			Rect2(560,378,460,26),Rect2(774,160,24,140),
			Rect2(850,160,24,140)]:
		canvas.draw_rect(rect,Color("80908a"))
	for x in range(567,1010,40):
		if (x>787 and x<862) or (x>925 and x<973):
			continue
		canvas.draw_line(Vector2(x,353),Vector2(x+18,353),Color("e1be85"),2.0)
	for y in range(330,376,8):
		canvas.draw_rect(Rect2(EAST_CROSS_X-13,y,26,4),Color("e5d6a4"))
	for x in range(800,847,8):
		canvas.draw_rect(Rect2(x,BRANCH_CROSS_Y-12,4,24),Color("e5d6a4"))
	for lot in [Rect2(578,230,74,65),Rect2(677,230,88,65),
			Rect2(890,223,102,74),Rect2(589,410,100,54),
			Rect2(722,410,91,61),Rect2(887,414,105,55)]:
		canvas.draw_rect(lot,Color("768987"))
	canvas.draw_line(Vector2(824,169),Vector2(824,277),Color("d1b985"),1.5)
