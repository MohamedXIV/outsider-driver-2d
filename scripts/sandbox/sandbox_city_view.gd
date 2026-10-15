class_name SandboxCityView
extends Node2D

# Deliberately provisional 2D district projection. Renders the *shared*
# SandboxRoads graph, never a fixed passenger/taxi route.
var world: SandboxWorld


func _point(district: String) -> Vector2:
	return IsoProjection.project(SandboxRoads.map_position(district)) * 0.5 + Vector2(250, 0)


func _draw() -> void:
	if world == null:
		return
	for district in SandboxRoads.DISTRICTS:
		for neighbor in SandboxRoads.LINKS[district]:
			if district > str(neighbor):
				continue
			var a: Vector2 = _point(district)
			var b: Vector2 = _point(str(neighbor))
			draw_line(a + Vector2(0, 9), b + Vector2(0, 9), Color("192c32"), 21)
			draw_line(a, b, Color("778c88"), 14)
			draw_line(a, b, Color("dfc389", 0.7), 1.7)
	for district in SandboxRoads.DISTRICTS:
		var center: Vector2 = _point(district)
		draw_circle(center + Vector2(2, 9), 38, Color("16292e", 0.7))
		draw_circle(center, 32, Color("617a75"))
		draw_circle(center, 25, Color("455d62"))
		var count: int = 0
		for npc in world.residents:
			if npc["location"] == district:
				count += 1
		draw_string(ThemeDB.fallback_font, center + Vector2(0, 6),
				str(count), HORIZONTAL_ALIGNMENT_CENTER, -1, 21, Color("f6e3b4"))
		draw_string(ThemeDB.fallback_font, center + Vector2(-45, -44),
				district.to_upper(), HORIZONTAL_ALIGNMENT_CENTER,
				100, 16, Color("f7e9cc"))
	var taxi: Vector2 = _point(world.player_district)
	draw_circle(taxi + Vector2(-35, 30), 17, Color("f5c87c", 0.18))
	draw_rect(Rect2(taxi + Vector2(-46, 19), Vector2(22, 16)), Color("efbb71"))
	draw_line(taxi + Vector2(-47, 20), taxi + Vector2(-24, 20), Color("fdf0d1"), 2)
	draw_string(ThemeDB.fallback_font, taxi + Vector2(-28, 53), "YOUR TAXI",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("f5dfbc"))
