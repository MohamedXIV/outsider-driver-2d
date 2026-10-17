extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	for area in [Vector2i(1280,720),Vector2i(960,540),Vector2i(720,720),Vector2i(640,480),Vector2i(390,844)]:
		root.size=area
		for tab in ["requests","map","gear","contacts","settings"]:
			scene._player_ui._tab(tab)
			await process_frame;await process_frame;await process_frame
			var panel: Control=scene._player_ui._panel
			var bounds: Rect2=panel.get_global_rect()
			assert(bounds.end.x<=root.get_visible_rect().size.x+1,"Panel overflow %s %s: %s" % [area,tab,bounds])
			assert(bounds.end.y<=root.get_visible_rect().size.y+1)
			assert(scene._player_ui._tabs.get_global_rect().end.x<=root.get_visible_rect().size.x,"Tabs overflow %s: %s" % [area,scene._player_ui._tabs.get_global_rect()])
			for action in scene._player_ui._actions.values(): assert(action.size.y>=44)
	print("PLAYER_LAYOUT_PASS 1280x720, 960x540, 720x720, 640x480, 390x844; scrollable tabs and touch actions")
	quit()
