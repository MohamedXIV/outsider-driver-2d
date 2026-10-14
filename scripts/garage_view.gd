class_name GarageView
extends Node2D

# P2.1 rendered, bounded 2D personal space. Coordinates belong to GameSession.
# This is authored scenery, not a second gameplay/world-state authority.
var character_position: Vector2 = GameSession.GARAGE_START
var selected_device: String = ""


func _draw() -> void:
	var floor: PackedVector2Array = _quad(-4.0, -3.35, 4.0, 3.35)
	draw_colored_polygon(floor, Color("68665e"))
	# The back walls share the same projection as the road and character.
	_wall(Vector2(-4, -3.35), Vector2(4, -3.35), 2.35, Color("47555a"))
	_wall(Vector2(-4, 3.35), Vector2(-4, -3.35), 2.35, Color("39484c"))
	draw_colored_polygon(floor, Color("81796b", 0.52))
	for x in range(-4, 5):
		draw_line(IsoProjection.ground(float(x), -3.35),
				IsoProjection.ground(float(x), 3.35), Color("c4b7a0", 0.26), 1.2)
	for z in range(-3, 4):
		draw_line(IsoProjection.ground(-4, float(z)),
				IsoProjection.ground(4, float(z)), Color("d1c4ad", 0.24), 1.2)
	# Functional objects remain visible, but all interaction rules are domain-side.
	_marker(GameSession.WORKBENCH, Color("edbf7f"))
	_marker(GameSession.NOTICEBOARD, Color("9dbdd0"))
	_marker(GameSession.TAXI_DOOR, Color("96c4a2"))
	_fixture(GameSession.WORKBENCH, Color("8d6453"), "WORKBENCH")
	_fixture(GameSession.NOTICEBOARD, Color("738791"), "SHIFT NOTICE")
	_parked_taxi()
	_character()
	_label(Vector2(-3.6, 3.0), "DOCKSIDE  /  GARAGE", Color("f2e1be"))


func _quad(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([
		IsoProjection.ground(x0, z0), IsoProjection.ground(x1, z0),
		IsoProjection.ground(x1, z1), IsoProjection.ground(x0, z1)
	])


func _wall(a: Vector2, b: Vector2, height: float, tint: Color) -> void:
	var left: Vector2 = IsoProjection.ground(a.x, a.y)
	var right: Vector2 = IsoProjection.ground(b.x, b.y)
	var lift: Vector2 = Vector2(0, -height * IsoProjection.LEVEL_HEIGHT)
	draw_colored_polygon(PackedVector2Array([left, right, right + lift, left + lift]), tint)
	draw_line(left + lift, right + lift, tint.lightened(0.22), 4.0)


func _marker(at: Vector2, tint: Color) -> void:
	var center: Vector2 = IsoProjection.ground(at.x, at.y)
	draw_circle(center, 31.0, Color(tint, 0.21))
	draw_arc(center, 29, 0, TAU, 48, Color(tint, 0.82), 2.0)


func _fixture(at: Vector2, tint: Color, text: String) -> void:
	var p: Vector2 = IsoProjection.ground(at.x, at.y)
	var base: PackedVector2Array = PackedVector2Array([
		p + Vector2(-41, -4), p + Vector2(0, 18),
		p + Vector2(41, -4), p + Vector2(0, -27)
	])
	draw_colored_polygon(base, tint.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-41, -21), p + Vector2(0, 1),
		p + Vector2(41, -21), p + Vector2(0, -44)
	]), tint.lightened(0.20))
	draw_line(p + Vector2(-40, -21), p + Vector2(0, 1), tint.lightened(0.42), 2.0)
	_label(at, text, Color("f7e6cb"), Vector2(0, -58))


func _parked_taxi() -> void:
	var p: Vector2 = IsoProjection.ground(3.2, 1.75)
	draw_ellipse_placeholder(p + Vector2(5, 11), Color("233032", 0.55))
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-60, 3), p + Vector2(-8, -34),
		p + Vector2(65, -3), p + Vector2(15, 34)
	]), Color("d6a25c"))
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-33, -6), p + Vector2(-4, -28),
		p + Vector2(39, -8), p + Vector2(10, 13)
	]), Color("38545f"))
	draw_line(p + Vector2(-60, 3), p + Vector2(15, 34), Color("f5ce84"), 3.0)
	_label(GameSession.TAXI_DOOR, "TAXI  /  EXIT", Color("d5f0db"), Vector2(0, 54))


func draw_ellipse_placeholder(center: Vector2, tint: Color) -> void:
	draw_circle(center, 35, tint)


func _character() -> void:
	var foot: Vector2 = IsoProjection.ground(character_position.x, character_position.y)
	draw_circle(foot + Vector2(2, 4), 15, Color("172527", 0.57))
	draw_line(foot + Vector2(0, -5), foot + Vector2(0, -29), Color("d8b889"), 12)
	draw_circle(foot + Vector2(0, -37), 10, Color("ebd5b7"))
	draw_line(foot + Vector2(-7, -3), foot + Vector2(-10, 9), Color("263e47"), 5)
	draw_line(foot + Vector2(7, -3), foot + Vector2(10, 9), Color("263e47"), 5)
	draw_arc(foot, 22, 0, TAU, 40, Color("f8e3b5", 0.8), 1.5)


func _label(at: Vector2, text: String, tint: Color,
		shift: Vector2 = Vector2(0, -17)) -> void:
	draw_string(ThemeDB.fallback_font, IsoProjection.ground(at.x, at.y) + shift,
			text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, tint)
