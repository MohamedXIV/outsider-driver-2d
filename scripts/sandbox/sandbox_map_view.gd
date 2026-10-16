class_name SandboxMapView
extends Control
signal stop_selected(stop: String)
var world: SandboxWorld
var selected: String = ""
func _ready() -> void:
	custom_minimum_size=Vector2(200,240)
	mouse_filter=Control.MOUSE_FILTER_STOP
func point(node: String) -> Vector2:
	var p: Vector3 = SandboxRoads.map_position(node)
	return Vector2(25,20)+Vector2((p.x+500)/18500,(p.z+4500)/15500)*(size-Vector2(50,40))
func _draw() -> void:
	if world==null: return
	for key in SandboxCityData.EDGES:
		var pair: PackedStringArray = str(key).split("|")
		draw_line(point(pair[0]),point(pair[1]),Color("607e7b"),2,true)
	var route: Array[String] = world.route_nodes if world.is_travelling() else SandboxRoads.path(world.player_district,selected) if not selected.is_empty() else []
	for i in range(route.size()-1): draw_line(point(route[i]),point(route[i+1]),Color("efc17b"),4,true)
	for stop in SandboxRoads.DISTRICTS:
		draw_circle(point(stop),5,Color("f3cc8e") if stop==selected else Color("99b6a5"))
		draw_string(ThemeDB.fallback_font,point(stop)+Vector2(7,-3),SandboxRoads.location_name(stop),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("dddfcc"))
	draw_circle(point(world.player_district),7,Color("f9dda2"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var nearest: String=""; var distance: float=24
		for stop in SandboxRoads.DISTRICTS:
			var d: float=event.position.distance_to(point(stop))
			if d<distance: nearest=stop; distance=d
		if not nearest.is_empty(): selected=nearest; stop_selected.emit(nearest); queue_redraw()
