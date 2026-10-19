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
	assert(guide!=null and guide.visible)
	assert(guide.title_label.text.length()>0)
	assert(guide.action_button.custom_minimum_size.y>=44)
	var before: Dictionary=scene._world.snapshot()
	var objective: Dictionary=SandboxPlayerGuidance.describe(
			scene._world,"en",scene._selected_id,false)
	assert(objective.has("title") and objective.has("detail") and objective.has("tab"))
	assert(scene._world.snapshot()==before)
	var target: String=str(objective["tab"])
	assert(guide.action_button.visible==(ui.tab!=target))
	if guide.action_button.visible:
		guide.action_button.pressed.emit()
		assert(ui.tab==target,"Quick action must switch the actual Player Mode tab")
		assert(scene._world.snapshot()==before)
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
	root.size=Vector2i(480,760)
	for frame in range(6): await process_frame
	assert(not guide.visible,"No floating panel over compact touch controls")
	assert(ui._panel.position.x+ui._panel.size.x<=480)
	assert(ui._actions.has("wait") or scene._world.is_travelling())
	assert(ui._body.get_children().any(func(child: Node)->bool:
		return child is Label and str(child.text).contains(str(
			SandboxPlayerGuidance.describe(scene._world,"ar",scene._selected_id,
				scene._conversation!=null)["title"]))))
	ui.toggle_debug();assert(not guide.visible)
	ui.toggle_debug();assert(not guide.visible)
	assert(scene._world.snapshot()==before,"Presentation never mutates the world")
	print("PLAYER_GUIDANCE_SCENE_PASS native read-only objective, tab navigation, RTL and compact layout")
	quit()
