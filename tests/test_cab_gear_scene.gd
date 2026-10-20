extends SceneTree

# Cab hardware UI is purely a player-owned view over real starter/translator
# and inventory state. Never invent purchases or install state.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for frame in range(4): await process_frame
	var ui: SandboxPlayerUI=scene._player_ui
	var original: Dictionary=scene._world.snapshot()
	ui._tab("gear")
	for frame in range(3): await process_frame
	assert(ui._body.has_node("CabInstrumentsSection"))
	assert(ui._body.has_node("StarterGearSection"))
	assert(ui._body.has_node("FittingGearSection"))
	assert(ui._body.has_node("MarketGearSection"))
	assert(ui._actions.has("gps") and ui._actions.has("module:local") and ui._actions.has("radio"))
	assert(ui._actions.has("buy_local") and ui._actions.has("install_local"))
	assert(ui._actions.has("buy_cant") and ui._actions.has("install_cant"))
	assert(ui._actions.has("ar_buy") and ui._actions.has("ar_wear"))
	assert((ui._tabs.get_node("gear") as Button).button_pressed)
	assert(not (ui._tabs.get_node("settings") as Button).button_pressed)
	var translator: SandboxCabGearPlate=ui._body.get_node(
		"CabInstrumentsSection/Items/Device_translator")
	assert(translator.heading.text.length()>0)
	assert(translator.status.text.contains("Common"))
	assert(translator.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(scene._world.snapshot()==original,"Cab UI must not mutate World on inspection")
	(ui._actions["gps"] as Button).pressed.emit()
	for frame in range(3): await process_frame
	assert(scene._world.starter_device=="gps","Real starter action must remain connected")
	assert(not ui._guide.visible,
		"Routine distant fare guidance must not blanket the equipment/city view")
	assert(not ui._body.has_node("StarterGearSection"))
	assert(ui._body.has_node("CabInstrumentsSection/Items/Device_gps"))
	assert(ui._body.has_node("FittingGearSection") and ui._body.has_node("MarketGearSection"))
	assert(ui._actions.has("buy_local") and ui._actions.has("install_local"))
	# Cross-tab scroll must reset to the top; same-tab model refresh must not.
	ui._tab("settings")
	for frame in range(3): await process_frame
	ui._scroll.scroll_vertical=360
	for frame in range(3): await process_frame
	assert(ui._scroll.scroll_vertical>0,"Settings must be tall enough to scroll")
	ui._tab("gear")
	for frame in range(4): await process_frame
	assert(ui._scroll.scroll_vertical==0,"Opening Gear must show cab instruments first")
	assert((ui._tabs.get_node("gear") as Button).button_pressed)
	assert(not (ui._tabs.get_node("settings") as Button).button_pressed)
	ui._scroll.scroll_vertical=190
	for frame in range(2): await process_frame
	var gear_scroll: int=ui._scroll.scroll_vertical
	assert(gear_scroll>0)
	var credits: int=scene._world.credits
	ui._last_signature=""
	ui.sync()
	for frame in range(3): await process_frame
	assert(ui._scroll.scroll_vertical==gear_scroll,
		"Same-tab equipment status refresh must preserve user scroll position")
	ui._tab("gear")
	for frame in range(4): await process_frame
	assert(ui._scroll.scroll_vertical==0,
		"Explicitly reselecting Gear should return to the instruments")
	assert(scene._world.credits==credits,"Reading device status never charges the player")
	scene._on_language_locale("ar")
	ui._tab("gear")
	for frame in range(3): await process_frame
	var localized: SandboxCabGearPlate=ui._body.get_node(
		"CabInstrumentsSection/Items/Device_translator")
	assert(localized.rtl)
	assert(localized.heading.text=="وحدات اللغة")
	assert(localized.status.text.contains("المثبتة"))
	assert(ui._actions.has("buy_local") and ui._actions.has("ar_buy"))
	root.size=Vector2i(480,760)
	for frame in range(6): await process_frame
	assert(ui._panel.size.y<=760*0.46+1.0,"Cab gear must leave compact city visible")
	assert(ui._body.has_node("MarketGearSection"))
	assert(ui._actions["buy_local"].custom_minimum_size.y>=44)
	ui.toggle_debug()
	assert(not ui._panel.visible)
	print("CAB_GEAR_SCENE_PASS actual starter, instrument plates, fittings, market, RTL, compact")
	quit()
