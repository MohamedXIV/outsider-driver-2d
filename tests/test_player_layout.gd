extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	for area in [Vector2i(1280,720),Vector2i(960,540),Vector2i(720,720),Vector2i(640,480),Vector2i(390,844)]:
		root.size=area
		for tab in ["requests","map","gear","contacts","settings"]:
			scene._player_ui._tab(tab)
			await process_frame;await process_frame;await process_frame
			var mode_bounds: Rect2=scene._player_ui._mode.get_global_rect()
			assert(not scene._player_ui._hint.get_global_rect().intersects(mode_bounds),"Status text must not run underneath the mode button")
			for child in scene._player_ui._tabs.get_children():
				assert(not child.get_global_rect().intersects(mode_bounds),"Compact mode control must leave every tab clickable")
			var panel: Control=scene._player_ui._panel
			var bounds: Rect2=panel.get_global_rect()
			assert(bounds.end.x<=root.get_visible_rect().size.x+1,"Panel overflow %s %s: %s" % [area,tab,bounds])
			assert(bounds.end.y<=root.get_visible_rect().size.y+1)
			assert(scene._player_ui._tabs.get_global_rect().end.x<=root.get_visible_rect().size.x,"Tabs overflow %s: %s" % [area,scene._player_ui._tabs.get_global_rect()])
			for action in scene._player_ui._actions.values(): assert(action.size.y>=44)
	root.size=Vector2i(1280,1400);scene._player_ui.toggle_debug()
	await process_frame;await process_frame
	var list: ItemList=scene._offers
	list.add_theme_font_size_override("font_size",60)
	await process_frame;await process_frame
	for rebuilt in [false,true]:
		if rebuilt: scene._on_observe()
		# Large text makes the genuine request list scroll without inventing offers.
		list.force_update_list_size();list.get_v_scroll_bar().value=50
		assert(is_equal_approx(list.get_v_scroll_bar().value,minf(50.0,maxf(0.0,list.get_v_scroll_bar().max_value-list.get_v_scroll_bar().page))))
		var checked: int=0
		for row in scene._debug_offer_bounds():
			if row["y"]<=row["top"]+2 or row["y"]>=row["bottom"]-2: continue
			var at: Vector2=Vector2(row["x"],row["y"])-list.global_position
			assert(list.get_item_at_position(at,true)==row["index"],"Published request bound must hit that real item")
			assert(row["id"]==str(list.get_item_metadata(row["index"])))
			checked+=1
		assert(checked>0)
	print("PLAYER_LAYOUT_PASS 1280x720, 960x540, 720x720, 640x480, 390x844; scrollable tabs and touch actions")
	quit()
