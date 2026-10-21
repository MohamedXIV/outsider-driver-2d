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
const SOUTH_SIDEWALK: Rect2 = Rect2(100, 378, 460, 40)
const ROAD: Rect2 = Rect2(95, 328, 475, 48)
const PEDESTRIAN_RADIUS: float = 7.0
# Clearance is the WHOLE pedestrian collision body beyond the road edge,
# plus a small margin, not merely their center reaching the zebra paint.
const FRONTAGES: Array[Rect2] = [
	Rect2(160,235,90,62), Rect2(270,235,80,62),
	Rect2(390,235,110,62), Rect2(450,425,110,66)
]

static func destination(slot: int=0) -> Vector2:
	return SITE if slot==0 else Vector2(700.0,SOUTH_Y)

static func waypoints(slot: int=0) -> PackedVector2Array:
	return PackedVector2Array([START-Vector2(30*slot,0),Vector2(CROSS_X,NORTH_Y),
			Vector2(CROSS_X,SOUTH_Y),destination(slot)])

static func position_at(progress: float, slot: int=0) -> Vector2:
	var path: PackedVector2Array = waypoints(slot)
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

static func progress_of(where: Vector2, slot: int=0) -> float:
	var path: PackedVector2Array = waypoints(slot)
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

static func crossing_clear_y() -> float:
	return ROAD.end.y + PEDESTRIAN_RADIUS + 1.0

static func crossing_clear(where: Vector2) -> bool:
	return where.y >= crossing_clear_y()

static func crossing_finished(progress: float, slot: int=0) -> bool:
	return progress >= progress_of(Vector2(CROSS_X,crossing_clear_y()),slot)

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
	canvas.draw_rect(Rect2(462,436,26,36),Color("d2c49f"))
	canvas.draw_string(ThemeDB.fallback_font,Vector2(454,460),"PARTS",
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

# A second reusable junction and a right-angle block extend the same local
# pilot avenue. These are ground-level pedestrian modules, not new city-road
# graph edges: only the existing Patchworks zebra binds world vehicle routes.
const EXTENSION_ROADS: Array[Rect2] = [
	Rect2(1020,328,480,48), Rect2(1200,160,48,390),
	Rect2(1452,328,48,272)
]
const EXTENSION_SIDEWALKS: Dictionary = {
	"FourWayNorthWest": Rect2(1020,300,180,26),
	"FourWayNorthEast": Rect2(1248,300,278,26),
	"FourWaySouthWest": Rect2(1020,378,180,26),
	"FourWaySouthEast": Rect2(1248,378,178,26),
	"FourWayUpperWest": Rect2(1174,160,24,140),
	"FourWayUpperEast": Rect2(1250,160,24,140),
	"FourWayLowerWest": Rect2(1174,404,24,146),
	"FourWayLowerEast": Rect2(1250,404,24,146),
	"CornerOuterSidewalk": Rect2(1500,326,26,274),
	"CornerInnerSidewalk": Rect2(1426,378,26,222)
}
const EXTENSION_CROSSINGS: Array[Vector4] = [
	Vector4(1200,313,1248,313), Vector4(1200,391,1248,391),
	Vector4(1100,313,1100,391), Vector4(1262,313,1262,391)
]
const EXTENSION_LOTS: Array[Rect2] = [
	Rect2(1040,235,100,62),Rect2(1310,235,100,62),
	Rect2(1040,410,100,62),Rect2(1320,440,80,90)
]

static func install_extension(parent: Node2D) -> void:
	for label in EXTENSION_SIDEWALKS:
		_add_sidewalk(parent,EXTENSION_SIDEWALKS[label],str(label))
	for i in range(EXTENSION_CROSSINGS.size()):
		var crossing: Vector4=EXTENSION_CROSSINGS[i]
		_crossing(parent,"FourWayCrossing%d" % i,
				Vector2(crossing.x,crossing.y),Vector2(crossing.z,crossing.w))

static func paint_extension(canvas: Node2D) -> void:
	for road in EXTENSION_ROADS:
		canvas.draw_rect(road,Color("3f5555"))
	for sidewalk in EXTENSION_SIDEWALKS.values():
		canvas.draw_rect(sidewalk,Color("80908a"))
	for lot in EXTENSION_LOTS:
		canvas.draw_rect(lot,Color("9d896f"))
		canvas.draw_rect(Rect2(lot.position+Vector2(8,8),Vector2(16,9)),Color("425b58"))
	for crossing in EXTENSION_CROSSINGS:
		var start: Vector2=Vector2(crossing.x,crossing.y)
		var end: Vector2=Vector2(crossing.z,crossing.w)
		var direction: Vector2=(end-start).normalized()
		var normal: Vector2=direction.orthogonal()*11.0
		for step in range(0,int(start.distance_to(end)),8):
			var at: Vector2=start+direction*float(step)
			canvas.draw_line(at-normal,at+normal,Color("e5d6a4"),4.0)
	for x in range(1030,1440,36):
		if x>1170 and x<1270: continue
		canvas.draw_line(Vector2(x,352),Vector2(x+18,352),Color("d1b985"),2.0)
	for y in range(410,590,36):
		canvas.draw_line(Vector2(1476,y),Vector2(1476,y+18),Color("d1b985"),2.0)

# Native curb bodies share the painted sidewalk/road boundaries. Avoidance
# cannot push a pedestrian onto asphalt outside the marked crossing opening.
static func install_curbs(parent: Node2D) -> void:
	var rects: Array[Rect2]=[Rect2(100,298,460,2),Rect2(100,SOUTH_SIDEWALK.end.y,460,2)]
	for y in [326.0,376.0]:
		rects.append(Rect2(100,y,CROSS_X-120.0,2))
		rects.append(Rect2(CROSS_X+20.0,y,560.0-CROSS_X-20.0,2))
	for rect in rects:
		var body: StaticBody2D=StaticBody2D.new();body.collision_layer=8;body.collision_mask=2
		var hitbox: CollisionShape2D=CollisionShape2D.new()
		var shape: RectangleShape2D=RectangleShape2D.new();shape.size=rect.size
		hitbox.shape=shape;hitbox.position=rect.get_center();body.add_child(hitbox);parent.add_child(body)
