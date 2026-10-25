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
	if not Check.ok(ui._body.has_node("CabInstrumentsSection"), "ui._body.has_node('CabInstrumentsSection')"): return
	if not Check.ok(ui._body.has_node("StarterGearSection"), "ui._body.has_node('StarterGearSection')"): return
	if not Check.ok(ui._body.has_node("FittingGearSection"), "ui._body.has_node('FittingGearSection')"): return
	if not Check.ok(ui._body.has_node("MarketGearSection"), "ui._body.has_node('MarketGearSection')"): return
	if not Check.ok(ui._actions.has("gps") and ui._actions.has("module:local") and ui._actions.has("radio"), "ui._actions.has('gps') and ui._actions.has('module:local') and ui._actions.has('radio')"): return
	if not Check.ok(ui._actions.has("buy_local") and ui._actions.has("install_local"), "ui._actions.has('buy_local') and ui._actions.has('install_local')"): return
	if not Check.ok(ui._actions.has("buy_cant") and ui._actions.has("install_cant"), "ui._actions.has('buy_cant') and ui._actions.has('install_cant')"): return
	if not Check.ok(ui._actions.has("ar_buy") and ui._actions.has("ar_wear"), "ui._actions.has('ar_buy') and ui._actions.has('ar_wear')"): return
	if not Check.ok((ui._tabs.get_node("gear") as Button).button_pressed, "(ui._tabs.get_node('gear') as Button).button_pressed"): return
	if not Check.ok(not (ui._tabs.get_node("settings") as Button).button_pressed, "not (ui._tabs.get_node('settings') as Button).button_pressed"): return
	var translator: SandboxCabGearPlate=ui._body.get_node(
		"CabInstrumentsSection/Items/Device_translator")
	if not Check.ok(translator.heading.text.length()>0, "translator.heading.text.length()>0"): return
	if not Check.ok(translator.status.text.contains("Common"), "translator.status.text.contains('Common')"): return
	if not Check.ok(translator.mouse_filter==Control.MOUSE_FILTER_IGNORE, "translator.mouse_filter==Control.MOUSE_FILTER_IGNORE"): return
	if not Check.ok(scene._world.snapshot()==original, "Cab UI must not mutate World on inspection"): return
	(ui._actions["gps"] as Button).pressed.emit()
	for frame in range(3): await process_frame
	if not Check.ok(scene._world.starter_device=="gps", "Real starter action must remain connected"): return
	if not Check.ok(not ui._guide.visible, "Routine distant fare guidance must not blanket the equipment/city view"): return
	if not Check.ok(not ui._body.has_node("StarterGearSection"), "not ui._body.has_node('StarterGearSection')"): return
	if not Check.ok(ui._body.has_node("CabInstrumentsSection/Items/Device_gps"), "ui._body.has_node('CabInstrumentsSection/Items/Device_gps')"): return
	if not Check.ok(ui._body.has_node("FittingGearSection") and ui._body.has_node("MarketGearSection"), "ui._body.has_node('FittingGearSection') and ui._body.has_node('MarketGearSection')"): return
	if not Check.ok(ui._actions.has("buy_local") and ui._actions.has("install_local"), "ui._actions.has('buy_local') and ui._actions.has('install_local')"): return
	# Cross-tab scroll must reset to the top; same-tab model refresh must not.
	ui._tab("settings")
	for frame in range(3): await process_frame
	ui._scroll.scroll_vertical=360
	for frame in range(3): await process_frame
	if not Check.ok(ui._scroll.scroll_vertical>0, "Settings must be tall enough to scroll"): return
	ui._tab("gear")
	for frame in range(4): await process_frame
	if not Check.ok(ui._scroll.scroll_vertical==0, "Opening Gear must show cab instruments first"): return
	if not Check.ok((ui._tabs.get_node("gear") as Button).button_pressed, "(ui._tabs.get_node('gear') as Button).button_pressed"): return
	if not Check.ok(not (ui._tabs.get_node("settings") as Button).button_pressed, "not (ui._tabs.get_node('settings') as Button).button_pressed"): return
	ui._scroll.scroll_vertical=190
	for frame in range(2): await process_frame
	var gear_scroll: int=ui._scroll.scroll_vertical
	if not Check.ok(gear_scroll>0, "gear_scroll>0"): return
	var credits: int=scene._world.credits
	ui._last_signature=""
	ui.sync()
	for frame in range(3): await process_frame
	if not Check.ok(ui._scroll.scroll_vertical==gear_scroll, "Same-tab equipment status refresh must preserve user scroll position"): return
	ui._tab("gear")
	for frame in range(4): await process_frame
	if not Check.ok(ui._scroll.scroll_vertical==0, "Explicitly reselecting Gear should return to the instruments"): return
	if not Check.ok(scene._world.credits==credits, "Reading device status never charges the player"): return
	scene._on_language_locale("ar")
	ui._tab("gear")
	for frame in range(3): await process_frame
	var localized: SandboxCabGearPlate=ui._body.get_node(
		"CabInstrumentsSection/Items/Device_translator")
	if not Check.ok(localized.rtl, "localized.rtl"): return
	if not Check.ok(localized.heading.text=="وحدات اللغة", "localized.heading.text=='وحدات اللغة'"): return
	if not Check.ok(localized.status.text.contains("المثبتة"), "localized.status.text.contains('المثبتة')"): return
	if not Check.ok(ui._actions.has("buy_local") and ui._actions.has("ar_buy"), "ui._actions.has('buy_local') and ui._actions.has('ar_buy')"): return
	root.size=Vector2i(480,760)
	for frame in range(6): await process_frame
	if not Check.ok(ui._panel.size.y<=760*0.46+1.0, "Cab gear must leave compact city visible"): return
	if not Check.ok(ui._body.has_node("MarketGearSection"), "ui._body.has_node('MarketGearSection')"): return
	if not Check.ok(ui._actions["buy_local"].custom_minimum_size.y>=44, "ui._actions['buy_local'].custom_minimum_size.y>=44"): return
	ui.toggle_debug()
	if not Check.ok(not ui._panel.visible, "not ui._panel.visible"): return
	Check.finish(self, "CAB_GEAR_SCENE actual starter, instrument plates, fittings, market, RTL, compact")
