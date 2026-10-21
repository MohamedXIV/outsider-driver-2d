extends SceneTree

# Real Ink and rider-initiated dialogue share the same passenger-first
# presentation. No alternate scripted NPC/fare or World mutation is needed.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for frame in range(4): await process_frame
	var ui: SandboxPlayerUI=scene._player_ui
	assert(ui._actions.has("talk"))
	(ui._actions["talk"] as Button).pressed.emit()
	for frame in range(4): await process_frame
	assert(scene._conversation!=null)
	assert(ui._speech.visible,"Wide viewport uses passenger-owned speech surface")
	assert(ui._speech.speech_label.text==scene._dialogue_text.text)
	assert(ui._speech.portrait.npc==scene._world.resident(
		str(scene._world.offer_by_id(scene._conversation.offer_id).get("npc_id",""))))
	assert(ui._body.get_children().any(func(c: Node)->bool: return c.name=="RepliesSection"))
	assert(ui._body.get_children().any(func(c: Node)->bool: return c.name=="ActionsSection"))
	var reply_style: StyleBoxFlat=(ui._body.get_node("RepliesSection") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	var action_style: StyleBoxFlat=(ui._body.get_node("ActionsSection") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	assert(reply_style.border_color!=action_style.border_color,
		"Player speech choices and other controls need distinguishable physical sections")
	assert(ui._speech.speech_label.get_global_rect().end.x<=ui._speech.portrait.get_global_rect().position.x,
		"English speech and the actual passenger portrait must not overlap")
	assert(not ui._body.get_children().any(func(c: Node)->bool:
		return c is Label and c.text==scene._dialogue_text.text))
	assert(ui._actions.has("choice_0") and ui._actions.has("common"))
	assert(ui._speech.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(ui._speech.speech_label.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	root.size=Vector2i(480,760)
	for frame in range(6): await process_frame
	assert(not ui._speech.visible,"No floating passenger panel over compact city")
	var embedded: Array=ui._body.get_children().filter(
		func(c: Node)->bool: return c is SandboxPassengerSpeech)
	assert(embedded.size()==1 and embedded[0].speech_label.text==scene._dialogue_text.text)
	assert(embedded[0].portrait.npc==ui._speech.portrait.npc)
	assert(ui._actions.has("choice_0") and ui._actions["choice_0"].custom_minimum_size.y>=44)
	var reply: Button=ui._actions["choice_0"]
	var viewport_clip: Rect2=ui._scroll.get_global_rect()
	assert(viewport_clip.has_point(reply.get_global_rect().end-Vector2(4.0,4.0)),
		"Compact passenger portrait and full first real reply must fit before scrolling")
	assert(ui._panel.position.y>=194.0,
		"Compact passenger conversation must not obscure the player tab rows")
	scene._on_language_locale("ar")
	ui.sync()
	for frame in range(3): await process_frame
	var translated: Array=ui._body.get_children().filter(
		func(c: Node)->bool: return c is SandboxPassengerSpeech)
	assert(translated.size()==1)
	assert(translated[0].speech_label.text_direction==Control.TEXT_DIRECTION_LTR,
		"Untranslated alien glyphs must keep native direction in Arabic UI")
	root.size=Vector2i(1280,720)
	for frame in range(5): await process_frame
	assert(ui._speech.visible,"Arabic desktop must keep actual passenger speech")
	assert(not ui._speech.get_global_rect().intersects(ui._panel.get_global_rect()),
		"RTL passenger panel must stand opposite the player reply panel")
	assert(ui._speech.position.x<=30.0,"RTL passenger surface stays on scene's left")
	assert(ui._speech.portrait.get_global_rect().end.x<=ui._speech.speech_label.get_global_rect().position.x,
		"Arabic passenger portrait and speech must remain distinct adjacent zones")
	ui.toggle_debug()
	assert(not ui._speech.visible)
	print("PASSENGER_SPEECH_SCENE_PASS portrait+speech, Replies/Actions, compact, RTL, Debug")
	quit()
