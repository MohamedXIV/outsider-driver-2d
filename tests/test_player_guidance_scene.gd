extends SceneTree

# Contextual guidance never changes World; the actual tab button navigates.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	for frame in range(4): await process_frame
	var ui: SandboxPlayerUI=scene._player_ui
	var guide: SandboxPlayerGuidance=ui._guide
	assert(guide!=null)
	# The initial real fare is on Street already. The guidance panel should
	# not obscure a large section of the city when its target tab is current.
	assert(not guide.visible)
	assert(guide.title_label.text.length()>0)
	# Status is a small instrument cluster, not an all-in-one debug ticker.
	assert(ui._header.text==ui.place(scene._world.player_district))
	assert(not ui._header.text.contains("OUTSIDER"))
	assert(ui._wallet.text=="%d cr"%scene._world.credits)
	assert(not ui._wallet.get_global_rect().intersects(ui._header.get_global_rect()))
	assert(not ui._wallet.get_global_rect().intersects(ui._mode.get_global_rect()))
	assert(ui._actions.has("wait"))
	assert(ui._body.has_node("FaresSection"),"Real visible offers own a separate dispatch list")
	ui._tab("settings")
	for frame in range(3): await process_frame
	assert(guide.visible,"Guide should reappear when its action opens a different tab")
	assert(is_equal_approx(guide.size.y,172.0),
			"Context card must have a bounded height instead of a full-height overlay")
	ui._tab("requests")
	assert(guide.action_button.custom_minimum_size.y>=44)
	assert(guide.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(guide.get_child(0).mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(guide.title_label.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(guide.detail_label.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(guide.action_button.mouse_filter==Control.MOUSE_FILTER_STOP)
	# Chromium camera regression wheels at (1100,650). In desktop mode
	# that canvas point must not be swallowed by non-action HUD controls.
	var where: Vector2=Vector2(1100,650)
	var move: InputEventMouseMotion=InputEventMouseMotion.new()
	move.position=where;move.global_position=where
	Input.parse_input_event(move)
	await process_frame
	assert(root.gui_get_hovered_control()==null,
			"Non-interactive guidance must leave the world wheel target unobstructed")
	var wheel: InputEventMouseButton=InputEventMouseButton.new()
	wheel.position=where;wheel.global_position=where
	wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
	var prior_zoom: float=scene._city.zoom_preference
	Input.parse_input_event(wheel)
	await process_frame
	assert(is_equal_approx(scene._city.zoom_preference,prior_zoom-0.2),
			"Mouse wheel on the scenery must still zoom the native camera")
	var before: Dictionary=scene._world.snapshot()
	var objective: Dictionary=SandboxPlayerGuidance.describe(
			scene._world,"en",scene._selected_id,false)
	assert(objective.has("title") and objective.has("detail") and objective.has("tab"))
	assert(scene._world.snapshot()==before)
	var target: String=str(objective["tab"])
	assert(guide.action_button.visible==(ui.tab!=target))
	assert(guide.visible==(ui.tab!=target))
	if guide.action_button.visible:
		guide.action_button.pressed.emit()
		assert(ui.tab==target,"Quick action must switch the actual Player Mode tab")
		assert(scene._world.snapshot()==before)
	ui._tab("map")
	for frame in range(3): await process_frame
	# Route choices expose the exact World-owned attention delta rather than
	# pretending a slower service road is equivalent to the faster main road.
	var route_preview: Array[String]=SandboxRoads.path(
		scene._world.player_district,ui._map_selected,ui._planned_via)
	assert(SandboxRoads.valid_path(route_preview))
	var exposure_visible: bool=false
	for item in ui._body.find_children("*","Label",true,false):
		if str(item.text).contains("Attention +%d"%SandboxRoads.path_exposure(route_preview)):
			exposure_visible=true
	assert(exposure_visible,"Functional Map must show sourced route attention before driving")
	var waypoint_picker: OptionButton=ui._actions["via"]
	waypoint_picker.get_popup().popup()
	await process_frame
	assert(waypoint_picker.get_popup().visible)
	ui._last_signature=""
	ui.sync()
	assert(is_instance_valid(waypoint_picker) and ui._actions["via"]==waypoint_picker,
		"Open native waypoint dropdown must survive an autonomous UI refresh")
	waypoint_picker.get_popup().hide()
	for frame in range(3): await process_frame
	ui._tab("requests")
	var en: Dictionary=SandboxPlayerGuidance.describe(scene._world,"en","",false)
	var ar: Dictionary=SandboxPlayerGuidance.describe(scene._world,"ar","",false)
	assert(ar["title"]!=en["title"] and ar["tab"]==en["tab"])
	var sample: SandboxWorld=SandboxWorld.new(8)
	sample.rider_initiative={"status":"pending"}
	var cue: Dictionary=SandboxPlayerGuidance.describe(sample,"en","",false)
	assert(cue["tab"]=="requests" and not str(cue["detail"]).contains("accent"))
	scene._on_language_locale("ar");ui.sync()
	assert(ui.root.layout_direction==Control.LAYOUT_DIRECTION_RTL)
	ui._tab("settings")
	for frame in range(4): await process_frame
	assert(guide.visible,"A request or passenger remains actionable from Settings")
	var guide_bounds: Rect2=guide.get_global_rect()
	var sheet_bounds: Rect2=ui._panel.get_global_rect()
	assert(not guide_bounds.intersects(sheet_bounds),
		"Arabic RTL guidance must not obscure Settings controls")
	assert(guide_bounds.end.x+8<sheet_bounds.position.x,
		"Arabic cross-tab guidance must be opposite the real RTL panel")
	assert(guide.size.y<250,"Guide must not blanket the Arabic city view")
	# Regress the real Web failure: after pressing Arabic, a physical click on
	# the rendered English button must be received, not blocked by guidance.
	var english: Button=ui._actions["english"]
	var point: Vector2=english.get_global_rect().get_center()
	assert(not guide_bounds.has_point(point))
	var move_english: InputEventMouseMotion=InputEventMouseMotion.new()
	move_english.position=point;move_english.global_position=point
	Input.parse_input_event(move_english)
	var pressed_english: InputEventMouseButton=InputEventMouseButton.new()
	pressed_english.button_index=MOUSE_BUTTON_LEFT;pressed_english.pressed=true
	pressed_english.position=point;pressed_english.global_position=point
	Input.parse_input_event(pressed_english)
	await process_frame
	var released_english: InputEventMouseButton=InputEventMouseButton.new()
	released_english.button_index=MOUSE_BUTTON_LEFT;released_english.pressed=false
	released_english.position=point;released_english.global_position=point
	Input.parse_input_event(released_english)
	for frame in range(3): await process_frame
	assert(scene._ui_locale=="en","Real English button must work after Arabic RTL")
	scene._on_language_locale("ar");ui._tab("requests")
	root.size=Vector2i(480,760)
	for frame in range(6): await process_frame
	assert(not guide.visible,"No floating panel over compact touch controls")
	assert(ui._panel.position.x+ui._panel.size.x<=480)
	assert(ui._panel.position.y>=380,"Compact bottom sheet should leave visible city under the tabs")
	assert(ui._panel.size.y<=760*0.46+1.0,
		"Compact UI should not expand over the native world when requests change")
	assert(not ui._wallet.get_global_rect().intersects(ui._header.get_global_rect()),
		"Compact wallet must not obscure the stop name")
	assert(ui._actions.has("wait") or scene._world.is_travelling())
	var wait_point: Vector2=ui._actions["wait"].get_global_rect().get_center()
	assert(wait_point.y>=ui._panel.position.y)
	# Real autonomous demand transitions must not relocate the wait button
	# after a scroll-list rebuild (important for touch and Chromium clicks).
	ui._last_signature=""
	ui.sync()
	for frame in range(3): await process_frame
	assert(wait_point.distance_to(ui._actions["wait"].get_global_rect().get_center())<1.0)
	assert(ui._body.has_node("FaresSection") or not scene._world.open_offers().any(
		func(offer: Dictionary)->bool: return offer.get("origin","")==scene._world.player_district),
		"Compact dispatch presents real fares instead of redundant narrator hints")
	ui.toggle_debug();assert(not guide.visible)
	ui.toggle_debug();assert(not guide.visible)
	assert(scene._world.snapshot()==before,"Presentation never mutates the world")
	print("PLAYER_GUIDANCE_SCENE_PASS native read-only objective, tab navigation, RTL and compact layout")
	quit()
