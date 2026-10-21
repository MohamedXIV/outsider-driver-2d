extends SceneTree
# Integration gate: real world resident, live Player Mode, spatially embedded
# Godot actor, no duplicate coarse sprite, and mid-crossing save/load.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	assert(scene._street_pilot == null)
	var original_world: SandboxWorld = scene._world
	assert(not original_world.is_travelling())
	var initial_actor: String = SandboxLocalPedestrianTrip.candidate(original_world)
	assert(not initial_actor.is_empty(), "A real idle Patchworks resident should qualify")
	scene._process(scene.REAL_SECONDS_PER_STEP)
	assert(scene._street_pilot != null, "No embedded street instance")
	assert(scene._street_pilot.embedded)
	assert(scene._street_pilot.world == original_world)
	assert(scene._street_pilot.walking_npc_id == initial_actor)
	assert(original_world.resident(initial_actor)["local_pedestrian_trip"]["status"] == "walking")
	var zebra: Vector2=scene._street_pilot.to_global(Vector2(
			SandboxStreetModule.CROSS_X,SandboxStreetModule.LANE_Y))
	assert(zebra.distance_to(SandboxStreetRouteBinding.crossing_position())<.01,
			"The garage zebra must be on the real ground-level taxi road edge")
	assert(SandboxStreetRouteBinding.grounded())
	var departure_events: int = 0
	for e in original_world.events:
		if e["kind"] == "local_pedestrian_departed":
			departure_events += 1
	assert(departure_events == 1)
	var moving: bool = false
	for i in range(80):
		await physics_frame
		if scene._street_pilot.pedestrian.position.x > 158.0:
			moving = true
	assert(moving, "Embedded actor was not navigated by the Godot physics server")
	await capture("patchworks-walking-in-main-game")
	var visual_saved: Vector2 = scene._street_pilot.pedestrian.position
	scene._on_save()
	scene._on_load()
	assert(scene._world != original_world, "A real save was not loaded")
	assert(scene._street_pilot != null)
	assert(scene._street_pilot.embedded)
	assert(scene._street_pilot.walking_npc_id == initial_actor)
	assert(scene._street_pilot.pedestrian.position.distance_to(visual_saved) < 1.0)
	assert(scene._world.resident(initial_actor)["local_pedestrian_trip"]["status"] == "walking")
	await capture("patchworks-walking-restored")
	for i in range(1600):
		await physics_frame
		if i % 220 == 0:
			var actor: SandboxPedestrianActor = scene._street_pilot.pedestrian
			print("R05_PATCHWORKS_TRACE frame=",i," at=",actor.position,
				" target=",actor.destination," reachable=",actor._agent.is_target_reachable(),
				" path_blocked=",actor.path_blocked," reserved=",actor.crossing_reserved,
				" cleared=",actor.crossing_completed," native_car=",scene._street_pilot.car.position,
				" follower=",scene._street_pilot.follower.position)
		if scene._street_pilot.world_reported_arrival:
			break
	assert(scene._street_pilot.world_reported_arrival, "No arrival after restoring a physical pedestrian")
	assert(scene._street_pilot.pedestrian.position.distance_to(SandboxStreetModule.SITE)<=9.0,
			"Main-scene actor arrived away from the actual service site")
	var arrivals: int = 0
	for e in scene._world.events:
		if e["kind"] == "local_pedestrian_arrived":
			arrivals += 1
	assert(arrivals == 1)
	await capture("patchworks-arrived-once")
	assert(not SandboxLocalPedestrianTrip.arrive(scene._world,initial_actor,scene._street_pilot.SITE))
	var forged: Dictionary = scene._world.snapshot()
	forged["residents"][0]["local_pedestrian_trip"] = {"site":"patchworks:parts_counter","status":"arrived","started":480,"arrived":480}
	assert(not SandboxWorld.new().restore_snapshot(forged), "Forged local arrival must not load without provenance")
	# No second actor is spawned if normal render/update occurs post-arrival.
	scene._process(.15)
	assert(scene._street_pilot.walking_npc_id == initial_actor)
	print("STREET_MAIN_PASS single world-owned NPC in playable city, native actor and restored midwalk position")
	quit()

func capture(label: String) -> void:
	var path: String = "/tmp/od2d-street-evidence"
	DirAccess.make_dir_recursive_absolute(path)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path.path_join(label+".png")) == OK)
