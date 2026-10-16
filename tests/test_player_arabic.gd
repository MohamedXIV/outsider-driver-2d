extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	scene._on_language_locale("ar")
	for tab in ["requests","map","gear","contacts","settings"]:
		scene._player_ui._tab(tab)
		await process_frame
		_check(scene._player_ui.root)
	assert(scene._player_ui.root.get_theme_font("font").has_char("E".unicode_at(0)),"Arabic theme needs Latin fallback for equipment and English toggle")
	assert(scene._player_ui.root.layout_direction==Control.LAYOUT_DIRECTION_RTL)
	print("PLAYER_ARABIC_PASS inherited Arabic font on actual labels/buttons and RTL")
	quit()
func _check(node: Node) -> void:
	if node is Label or node is Button:
		var font: Font=node.get_theme_font("font")
		var text: String=node.text
		for i in range(text.length()):
			var cp: int=text.unicode_at(i)
			if cp>=0x600 and cp<=0x6ff: assert(font.has_char(cp),"Actual Player control lacks Arabic font: "+str(node.name))
	for child in node.get_children(): _check(child)
