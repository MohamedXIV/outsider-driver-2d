extends SceneTree

# Native Godot labels / OFL font coverage and real player locale behavior.
func _initialize() -> void:
	call_deferred("_walkthrough")


func _walkthrough() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/od2d-ink-evidence/sandbox")
	for language in ["local", "cant"]:
		var font: Font = load(SandboxLanguagePresentation.native_font_path(language)) as Font
		assert(font != null)
		for key in SandboxLanguagePresentation.SCRIPT_LINES[language]:
			var sample: String = SandboxLanguagePresentation.source_line(language, str(key))
			assert(not sample.is_empty())
			for i in range(sample.length()):
				var cp: int = sample.unicode_at(i)
				if cp >= 0x1680:
					assert(font.has_char(cp), "Missing script glyph U+%X" % cp)
	var ar_font: Font = load("res://assets/fonts/NotoNaskhArabicUI[wght].ttf") as Font
	assert(ar_font != null and ar_font.has_char("ع".unicode_at(0)))
	assert(SandboxLanguagePresentation.source_line("local", "destination") !=
			SandboxLanguagePresentation.source_line("cant", "destination"))
	var scene: Node2D = (load("res://scenes/sandbox.tscn") as PackedScene).instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var talk: Button = scene.get_node("HUD/DockPanel/Content/Actions/Talk")
	var line: Label = scene.get_node("HUD/DialoguePanel/Content/Line")
	var choices: VBoxContainer = scene.get_node("HUD/DialoguePanel/Content/Choices")
	talk.pressed.emit()
	await process_frame
	var unknown: SandboxConversation = scene.get("_conversation")
	assert(unknown != null and not unknown.understood())
	assert(line.text == str(unknown.current_frame()["text"]))
	assert(not line.text.contains("stranger") and not line.text.contains("taxi"))
	var arabic: Button = scene.get_node("HUD/DialoguePanel/Content/LanguageSettings/Arabic")
	arabic.pressed.emit()
	assert(scene.get("_ui_locale") == "ar" and not line.text.contains("أحتاج"))
	var district: OptionButton = scene.get_node("HUD/DockPanel/Content/Navigation/District")
	district.select(1)
	scene.call("_on_reposition")
	await process_frame
	var residents: ItemList = scene.get_node("HUD/DockPanel/Content/Offers")
	var found: bool = false
	for i in range(residents.item_count):
		if str(residents.get_item_metadata(i)).contains("npc:04"):
			scene.call("_on_selected", i)
			found = true
			break
	assert(found)
	scene.get_node("HUD/GearPanel/Content/MarketBuy/BuyLocal").pressed.emit()
	scene.get_node("HUD/GearPanel/Content/MarketInstall/InstallLocal").pressed.emit()
	talk.pressed.emit()
	await process_frame
	var active: SandboxConversation = scene.get("_conversation")
	assert(active != null and active.understood())
	assert(scene.get("_reveal_pending"))
	assert(line.text == SandboxLanguagePresentation.source_line("local",
			SandboxLanguagePresentation.speech_key(active.current_frame(),
				(scene.get("_world") as SandboxWorld).resident("npc:04"))))
	scene.get_node("HUD/DialoguePanel/Content/SkipTranslation").pressed.emit()
	assert(not scene.get("_reveal_pending"))
	assert(line.text.contains("أ") or line.text.contains("ه"))
	assert((choices.get_child(0) as Button).text == "اسأل عن الوجهة")
	assert(line.text_direction == Control.TEXT_DIRECTION_RTL)
	await RenderingServer.frame_post_draw
	assert(get_root().get_texture().get_image().save_png(
			"/tmp/od2d-ink-evidence/sandbox/languages-arabic-native.png") == OK)
	var reduced: CheckButton = scene.get_node("HUD/DialoguePanel/Content/LanguageSettings/ReducedMotion")
	reduced.set_pressed(true)
	scene.call("_on_dialogue_choice", 0)
	await process_frame
	assert(not scene.get("_reveal_pending"))
	assert(line.text.contains("أنا ذاهب إلى"))
	await RenderingServer.frame_post_draw
	assert(get_root().get_texture().get_image().save_png(
			"/tmp/od2d-ink-evidence/sandbox/languages-arabic-reduced-native.png") == OK)
	scene.get_node("HUD/DialoguePanel/Content/LanguageSettings/English").pressed.emit()
	assert(line.text.contains("heading to"))
	assert((choices.get_child(0) as Button).text == "Agree to the trip.")
	print("SANDBOX_LANGUAGE_SCENE_PASS")
	quit(0)
