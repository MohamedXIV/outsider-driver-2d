class_name SandboxCityView
extends Node2D

# Deliberately provisional 2D district projection. Renders the *shared*
# SandboxRoads graph, never a fixed passenger/taxi route.
signal waypoint_clicked(district: String)

var world: SandboxWorld
var preview_nodes: Array[String] = []
var visual_fraction: float = 0.0


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
	var highlighted: Array[String] = world.route_nodes if not world.active_offer_id.is_empty() else preview_nodes
	for i in range(highlighted.size() - 1):
		draw_line(_point(highlighted[i]), _point(highlighted[i + 1]), Color("f4cb77"), 6, true)
	if not world.pending_route_nodes.is_empty():
		for i in range(world.pending_route_nodes.size() - 1):
			draw_line(_point(world.pending_route_nodes[i]), _point(world.pending_route_nodes[i+1]),
				Color("7fd5ce"), 5, true)
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
	# Invitation marker is anchored to the NPC's actual graph district.
	# It disappears after expiry or resolution; nothing spawns off-map.
	for meeting in world.meetings:
		if not ["accepted", "in_progress"].has(meeting["status"]):
			continue
		var npc: Dictionary = world.resident(str(meeting["npc_id"]))
		if npc.get("location") != meeting["location"]:
			continue
		var spot: Vector2 = _point(str(meeting["location"]))
		draw_arc(spot, 44, 0.0, TAU, 32, Color("dfb4d9"), 3.0, true)
		draw_string(ThemeDB.fallback_font, spot + Vector2(-45, 64), "MEET HERE",
			HORIZONTAL_ALIGNMENT_CENTER, 90, 14, Color("ffdaef"))
	var taxi: Vector2 = _point(world.player_district)
	if not world.active_offer_id.is_empty() and world.route_segment < world.route_nodes.size() - 1:
		var from: String = world.route_nodes[world.route_segment]
		var to: String = world.route_nodes[world.route_segment + 1]
		var minutes: int = SandboxRoads.edge_minutes(from, to)
		var fraction: float = (float(world.route_edge_elapsed) + visual_fraction * 10.0) / float(minutes)
		taxi = _point(from).lerp(_point(to), clampf(fraction, 0.0, 1.0))
	draw_circle(taxi + Vector2(-35, 30), 17, Color("f5c87c", 0.18))
	draw_rect(Rect2(taxi + Vector2(-46, 19), Vector2(22, 16)), Color("efbb71"))
	draw_line(taxi + Vector2(-47, 20), taxi + Vector2(-24, 20), Color("fdf0d1"), 2)
	draw_string(ThemeDB.fallback_font, taxi + Vector2(-28, 53), "YOUR TAXI",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("f5dfbc"))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not event.pressed \
			or event.button_index != MOUSE_BUTTON_LEFT or world == null:
		return
	var pointer: Vector2 = to_local(get_global_mouse_position())
	for district in SandboxRoads.DISTRICTS:
		if pointer.distance_to(_point(district)) < 28.0:
			waypoint_clicked.emit(district)
			get_viewport().set_input_as_handled()
			return
