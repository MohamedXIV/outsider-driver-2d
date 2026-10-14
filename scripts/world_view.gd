class_name WorldView
extends Node2D

# Placeholder 2D vector art, not the final asset/rendering system.
# Draw order deliberately demonstrates an elevated deck occluding a ground-level taxi.
var taxi_world: Vector3 = Vector3(-10, 0, 0)
var taxi_heading: Vector2 = Vector2(1, 0)


func _draw() -> void:
	_draw_ground()
	_draw_building(Vector2(-7, -4), Vector2(3.2, 3.4), 2.0, Color("928773"))
	_draw_building(Vector2(9, -4), Vector2(3.0, 2.6), 1.5, Color("7c979c"))
	_draw_building(Vector2(-4, 5), Vector2(2.4, 2.8), 1.4, Color("8d777c"))

	var roadway: Color = Color("485e6c")
	_draw_road(Vector3(-11, 0, 0), Vector3(11, 0, 0), 2.15, roadway)
	_draw_road(Vector3(10, 0, 0), Vector3(10, 0, 6), 2.15, roadway)
	_draw_road(Vector3(10, 0, 6), Vector3(7, 0, 9), 2.15, roadway)
	_draw_road(Vector3(7, 0, 9), Vector3(3, 0, 9), 2.15, roadway)
	_draw_road(Vector3(3, 0, 9), Vector3(2, 1, 6), 2.15, Color("637b80"))
	_draw_road_line(Vector3(-10, 0, 0), Vector3(10, 0, 0), Color("e7c687"))

	# Underpass vehicle is behind deck; elevated vehicle is in front.
	if taxi_world.y < 0.50:
		_draw_taxi()
	_draw_support(Vector3(2, 0, -4))
	_draw_support(Vector3(2, 0, 3))

	# Fade the deck when it occludes the player's ground-level taxi.
	# Correct depth is preserved, but the player does not lose track of the vehicle.
	var deck_color: Color = Color("778c90")
	if taxi_world.y < 0.5:
		var crossing_distance: float = Vector2(taxi_world.x - 2.0, taxi_world.z).length()
		deck_color.a = lerpf(0.42, 1.0, clampf(crossing_distance / 4.0, 0.0, 1.0))
	_draw_road(Vector3(2, 1, -7), Vector3(2, 1, 7), 4.1, deck_color)
	_draw_bridge_skirting(Vector3(2, 1, -7), Vector3(2, 1, 7), 4.1)
	_draw_road_line(Vector3(2, 1, -6), Vector3(2, 1, 6), Color("e6bd74"))
	_draw_bridge_edge(Vector3(2, 1, -7), Vector3(2, 1, 7))
	if taxi_world.y >= 0.50:
		_draw_taxi()


func _draw_ground() -> void:
	var limits: PackedVector2Array = PackedVector2Array([
		IsoProjection.ground(-15, -10),
		IsoProjection.ground(20, -10),
		IsoProjection.ground(20, 15),
		IsoProjection.ground(-15, 15)
	])
	draw_colored_polygon(limits, Color("354344"))
	for x in range(-15, 21):
		draw_line(IsoProjection.ground(float(x), -10), IsoProjection.ground(float(x), 15), Color("607172", 0.22), 1.0)
	for z in range(-10, 16):
		draw_line(IsoProjection.ground(-15, float(z)), IsoProjection.ground(20, float(z)), Color("607172", 0.22), 1.0)


func _draw_road(a: Vector3, b: Vector3, width: float, tint: Color) -> void:
	var corners: PackedVector2Array = IsoProjection.road_quad(a, b, width)
	if corners.is_empty():
		return
	draw_colored_polygon(corners, tint)
	var outline: PackedVector2Array = corners.duplicate()
	outline.append(corners[0])
	draw_polyline(outline, Color("b7b7a0", 0.52), 2.0)


func _draw_road_line(a: Vector3, b: Vector3, tint: Color) -> void:
	draw_line(IsoProjection.project(a), IsoProjection.project(b), tint, 2.0, true)


func _draw_support(base: Vector3) -> void:
	var p: Vector2 = IsoProjection.project(base)
	var top: Vector2 = IsoProjection.project(base + Vector3(0, 1, 0))
	draw_line(p, top, Color("343e45"), 15.0)
	draw_line(p + Vector2(-5, 0), top + Vector2(-5, 0), Color("93a0a0"), 4.0)


# A thin visible side face makes the 2D bridge read as supported infrastructure.
# Geometry stays authored 2D polygons; no mesh or 3D renderer.
func _draw_bridge_skirting(a: Vector3, b: Vector3, width: float) -> void:
	var quad: PackedVector2Array = IsoProjection.road_quad(a, b, width)
	if quad.size() != 4:
		return
	var thickness: Vector2 = Vector2(0, 14)
	var side: PackedVector2Array = PackedVector2Array([
		quad[2], quad[3], quad[3] + thickness, quad[2] + thickness
	])
	draw_colored_polygon(side, Color("52626a"))
	draw_line(quad[2] + thickness, quad[3] + thickness, Color("a4adad"), 2.0)


func _draw_bridge_edge(a: Vector3, b: Vector3) -> void:
	var side: Vector3 = Vector3(2.05, 0, 0)
	var left_a: Vector2 = IsoProjection.project(a - side)
	var left_b: Vector2 = IsoProjection.project(b - side)
	var right_a: Vector2 = IsoProjection.project(a + side)
	var right_b: Vector2 = IsoProjection.project(b + side)
	draw_line(left_a, left_b, Color("bdaca0"), 4.0)
	draw_line(right_a, right_b, Color("bdaca0"), 4.0)


func _draw_building(origin: Vector2, size: Vector2, height: float, tint: Color) -> void:
	var a: Vector3 = Vector3(origin.x, 0, origin.y)
	var b: Vector3 = a + Vector3(size.x, 0, 0)
	var c: Vector3 = a + Vector3(size.x, 0, size.y)
	var d: Vector3 = a + Vector3(0, 0, size.y)
	var rise: Vector3 = Vector3(0, height, 0)
	draw_colored_polygon(PackedVector2Array([
		IsoProjection.project(d), IsoProjection.project(c),
		IsoProjection.project(c + rise), IsoProjection.project(d + rise)
	]), tint.darkened(0.20))
	draw_colored_polygon(PackedVector2Array([
		IsoProjection.project(b), IsoProjection.project(c),
		IsoProjection.project(c + rise), IsoProjection.project(b + rise)
	]), tint.darkened(0.32))
	draw_colored_polygon(PackedVector2Array([
		IsoProjection.project(a + rise), IsoProjection.project(b + rise),
		IsoProjection.project(c + rise), IsoProjection.project(d + rise)
	]), tint.lightened(0.16))


func _draw_taxi() -> void:
	var center: Vector2 = IsoProjection.project(taxi_world) + Vector2(0, -8)
	var heading: Vector2 = taxi_heading.normalized()
	if heading.length_squared() < 0.001:
		heading = Vector2(0.86, 0.5)
	var sideways: Vector2 = Vector2(-heading.y, heading.x)
	var front: Vector2 = center + heading * 28
	var rear: Vector2 = center - heading * 28
	var polygon: PackedVector2Array = PackedVector2Array([
		front + sideways * 13, front - sideways * 13,
		rear - sideways * 13, rear + sideways * 13
	])
	draw_circle(center + Vector2(3, 12), 17.0, Color("071015", 0.35))
	draw_colored_polygon(polygon, Color("eab65c"))
	var outline: PackedVector2Array = polygon.duplicate()
	outline.append(polygon[0])
	draw_polyline(outline, Color("fbe4a9"), 2.5)
	draw_colored_polygon(PackedVector2Array([
		center + heading * 11 + sideways * 10,
		center + heading * 11 - sideways * 10,
		center - heading * 8 - sideways * 10,
		center - heading * 8 + sideways * 10
	]), Color("233a46"))
	draw_line(front - sideways * 9, front + sideways * 9, Color("fff2be"), 3.5)
