extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	var found: Dictionary={}
	for seed in range(1,65):
		var world: SandboxWorld=SandboxWorld.new(seed)
		for fare in world.open_offers():
			if fare.get("origin","")!="garage" or fare.get("channel","")=="official": continue
			if SandboxRoads.travel_minutes("garage",str(fare["destination"]))<9: continue
			if world.accept(str(fare["id"])) and world.rider_initiative.get("status","")=="scheduled":
				found={"world":world,"offer_id":str(fare["id"])}
				break
		if not found.is_empty(): break
	assert(not found.is_empty())
	scene._reset_local_pedestrian()
	scene._reset_passenger_alight()
	scene._world=found["world"]
	scene._city.world=scene._world
	scene._player_ui.tab="requests"
	var delay: int=int(scene._world.rider_initiative["due"])-scene._world.minute
	assert(scene._world.advance(delay))
	scene._render()
	assert(scene._world.rider_initiative.get("status")=="pending")
	var mode: SandboxPlayerUI=scene._player_ui
	mode.debug_mode=false
	mode.sync()
	assert(mode._actions.has("reply_silent"))
	assert(mode._body.get_children().any(func(c: Node)->bool:
		return c is Label and str(c.text).contains("passenger") or (
			c is Label and str(c.text).contains("راكب"))))
	scene._on_save()
	assert(scene._notice_text=="Sandbox saved.")
	scene._on_load()
	assert(scene._world.rider_initiative.get("status")=="pending")
	mode.sync()
	assert(mode._actions.has("reply_silent"))
	(mode._actions["reply_silent"] as Button).pressed.emit()
	assert(scene._world.rider_initiative.get("status")=="answered")
	assert(not mode._actions.has("reply_silent"))
	assert(scene._world.events.filter(func(e: Dictionary)->bool:
		return e.get("kind","")=="rider_initiative_answered").size()==1)
	print("RIDER_INITIATIVE_SCENE_PASS auto-speaking passenger, accessible Player Mode controls, saved pending response")
	quit()
