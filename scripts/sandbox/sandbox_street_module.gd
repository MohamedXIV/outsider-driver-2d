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

static func crossing_finished(progress: float) -> bool:
	return progress >= progress_of(Vector2(CROSS_X,SOUTH_Y))

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
