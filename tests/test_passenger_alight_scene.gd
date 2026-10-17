extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._on_new_seed() # Default seed 8 -> real seed 9, real medical fare at garage.
	var world: SandboxWorld = scene._world
	var offer: Dictionary = {}
	for candidate in world.open_offers():
		if candidate["origin"] == "garage" and SandboxPassengerAlight.applicable(candidate):
			offer = candidate
			break
	assert(not offer.is_empty())
	assert(world.accept(str(offer["id"])))
	assert(world.advance(world.remaining_minutes))
	assert(not world.is_travelling() and world.player_district == "clinic")
	scene._sync_passenger_alight()
	assert(scene._alight_view != null and scene._alight_view.walker != null)
	var id: String = str(offer["npc_id"])
	assert(scene._alight_view.npc_id == id)
	var start: Vector2 = scene._alight_view.walker.position
	var trip: Dictionary = world.resident(id)["passenger_alight"]
	assert(SandboxAlightGeometry.valid_position(trip,start))
	assert(start.distance_to(SandboxCityView.project(SandboxRoads.map_position("clinic"))) >= 29.0,
			"Resident must exit on the legal curb, not inside the taxi")
	for frame in range(14): await physics_frame
	var before_save: Vector2 = scene._alight_view.walker.position
	assert(before_save.distance_to(start) > 1.0, "Native Godot walker must physically move toward clinic intake")
	assert(not scene._alight_view.walker._agent.is_navigation_finished())
	scene._on_save()
	assert(scene._notice_text == "Sandbox saved.")
	var balance: int = world.credits
	var source_events: int = world.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "fare_settled" and e.get("subject", "") == offer["id"]).size()
	scene._on_load()
	assert(scene._notice_text == "World, NPC and live dialogue restored.")
	assert(scene._world.credits == balance and source_events == 1)
	assert(scene._alight_view != null and scene._alight_view.npc_id == id)
	assert(scene._alight_view.walker.position.distance_to(before_save) < .1,
			"Native body must resume at its actual physical saved pose")
	var arrived: bool = false
	for frame in range(200):
		await physics_frame
		if scene._world.resident(id)["passenger_alight"]["status"] == "arrived":
			arrived = true
			break
	assert(arrived, "True local navigation must physically arrive at the clinic entrance")
	assert(scene._world.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "rider_alight_arrived" and e.get("subject", "") == id).size() == 1)
	scene._sync_passenger_alight()
	assert(scene._alight_view == null and scene._world.residents.size() == 9)
	scene._on_save()
	scene._on_load()
	assert(scene._world.resident(id)["passenger_alight"]["status"] == "arrived")
	assert(scene._world.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "rider_alight_arrived" and e.get("subject", "") == id).size() == 1)

	# Second independently generated world, genuine fare. Leaving the
	# neighborhood unloads the real body, then the world finishes the same
	# resident trip through its seeded offscreen clock.
	scene._on_new_seed() # seed 10 has different residents; return to 9 by new scene.
	var scene2: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene2)
	await process_frame
	scene2.set_process(false)
	scene2._on_new_seed()
	var other: SandboxWorld = scene2._world
	var next_offer: Dictionary = {}
	for candidate in other.open_offers():
		if candidate["origin"]=="garage" and SandboxPassengerAlight.applicable(candidate):
			next_offer = candidate
			break
	assert(not next_offer.is_empty() and other.accept(str(next_offer["id"])))
	assert(other.advance(other.remaining_minutes))
	scene2._sync_passenger_alight()
	assert(scene2._alight_view != null)
	var second_id: String = str(next_offer["npc_id"])
	assert(other.reposition("docks"))
	scene2._sync_passenger_alight()
	assert(scene2._alight_view == null)
	assert(other.resident(second_id)["passenger_alight"]["status"] == "offscreen")
	assert(other.advance(3))
	assert(other.resident(second_id)["passenger_alight"]["status"] == "arrived")
	assert(other.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "rider_alight_arrived" and e.get("subject", "") == second_id).size() == 1)
	assert(SandboxWorld.new().restore_snapshot(other.snapshot()))
	print("PASSENGER_ALIGHT_SCENE_PASS physical clinic intake, save/restore native body, exactly once, legitimate offscreen handoff")
	quit()
