extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	var world: SandboxWorld=SandboxWorld.new(8)
	scene._world=world
	scene._city.world=world
	scene._vehicle_corridor.attach(world)
	for block in range(4):
		assert(world.advance(360))
		scene._render_debug()
		var totals: Dictionary={}
		for event in world.events:
			var kind: String=str(event["kind"])
			totals[kind]=int(totals.get(kind,0))+1
		for kind in ["npc_alternative_departed","npc_alternative_arrived","npc_peer_contact","fare_settled"]:
			assert(scene._count_events(kind)==int(totals.get(kind,0)))
		assert(scene._event_metrics_seen==world.events.size())
		var elapsed: int=Time.get_ticks_usec()
		for repeat in range(15): scene._render_debug()
		print("EVENT_HISTORY_SAMPLE ",JSON.stringify({"minute":world.minute,"events":world.events.size(),
			"refresh_mean_usec":float(Time.get_ticks_usec()-elapsed)/15.0}))
	var replacement: SandboxWorld=SandboxWorld.new(29)
	scene._world=replacement
	scene._render_debug()
	assert(scene._count_events("npc_alternative_departed")==0)
	assert(scene._event_metrics_world==replacement)
	print("EVENT_HISTORY_CACHE_PASS")
	quit()
