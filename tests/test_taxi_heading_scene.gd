extends SceneTree

# R05 regression: the player-facing heading is a persistent presentation pose,
# resolved from genuine road tangents/events, NEVER a new movement authority.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	var city: SandboxCityView = scene._city
	var world: SandboxWorld = scene._world
	city._process(0.0)
	var initial: float = SandboxCityView.world_road_heading(world)
	assert(absf(angle_difference(initial, city.saved_taxi_heading())) < .001,
			"Freshly parked taxi must align with a grounded road, not global angle zero")
	var before: Dictionary = world.snapshot()
	city.restore_taxi_heading()
	assert(world.snapshot() == before, "Changing visual facing must not mutate SandboxWorld")
	scene._on_save()
	assert(scene._notice_text == "Sandbox saved.")
	# Reservation reconciliation during Save is a legitimate world event: only
	# compare against the actual canonical snapshot written to the save file.
	var persisted: Dictionary = scene._world.snapshot()
	city._heading = 0.0
	scene._on_load()
	assert(scene._notice_text == "World, NPC and live dialogue restored.")
	assert(absf(angle_difference(initial, city._heading)) < .001)
	# Restoring physically nearby pedestrians may legitimately emit independent
	# handoff/resume events. Taxi presentation does not own those world events.
	assert(scene._world.seed == int(persisted["seed"]))
	assert(scene._world.credits == int(persisted["credits"]))
	assert(scene._world.risk == int(persisted["risk"]))
	assert(scene._world.player_district == str(persisted["player_district"]))
	assert(scene._world.route_nodes == persisted["route_nodes"])

	world = scene._world
	assert(world.reposition("clinic"), "Taxi must genuinely drive toward Night Clinic")
	world.advance(3)
	city._process(.12)
	var heading_before: float = city.saved_taxi_heading()
	assert(city._heading_initialized and world.is_travelling())
	scene._on_save()
	assert(scene._notice_text == "Sandbox saved.")
	city._heading = 0.0
	scene._on_load()
	assert(absf(angle_difference(heading_before, city._heading)) < .001,
			"Mid-curve Save/Load must retain the exact smoothed facing")
	world = scene._world
	world.advance(world.remaining_minutes)
	city._process(0.0)
	assert(world.player_district == "clinic" and not world.is_travelling())
	var clinic_facing: float = SandboxCityView.world_road_heading(world)
	assert(absf(angle_difference(clinic_facing, city._heading)) < .001,
			"Night Clinic arrival must face the last real road tangent")
	var parked_snapshot: Dictionary = world.snapshot()
	scene._on_save()
	assert(scene._notice_text == "Sandbox saved.")
	city._heading = 0.0
	scene._on_load()
	assert(absf(angle_difference(clinic_facing, city._heading)) < .001)
	assert(scene._world.seed == int(parked_snapshot["seed"]))
	assert(scene._world.player_district == "clinic")
	assert(scene._world.credits == int(parked_snapshot["credits"]))
	assert(not scene._world.is_travelling())

	# Reverse road direction is not the same orientation (and must survive
	# independent city travel after the first fareless reposition).
	world = scene._world
	assert(world.reposition("docks"))
	world.advance(world.remaining_minutes)
	city._process(0.0)
	var back_facing: float = SandboxCityView.world_road_heading(world)
	assert(absf(angle_difference(back_facing, city._heading)) < .001)
	assert(absf(angle_difference(back_facing, clinic_facing)) > .05)
	scene._on_save()
	assert(scene._notice_text == "Sandbox saved.")
	city._heading = 0.0
	scene._on_load()
	assert(absf(angle_difference(back_facing, city._heading)) < .001)

	var tampered: Dictionary = {"taxi_heading": INF}
	assert(not SandboxSave.save_world(scene._world,"user://r05-tamper.json",{},tampered),
			"Non-finite heading must not enter a save")
	print("TAXI_HEADING_SCENE_PASS new seed, live curve, parked clinic, reverse arrival, save/load, world invariance")
	quit()
