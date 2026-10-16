extends SceneTree
# Real visible Godot NavigationServer2D/NavigationAgent2D/CharacterBody2D
# contract, NOT mocked positions along SandboxRoads.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pilot: SandboxStreetPilot = load("res://scenes/street_pilot.tscn").instantiate()
	root.add_child(pilot)
	assert(pilot.get_node("NorthSidewalk") is NavigationRegion2D)
	assert(pilot.get_node("SouthSidewalk") is NavigationRegion2D)
	assert(pilot.get_node("MarkedCrosswalkOnly") is NavigationLink2D)
	var walker: SandboxPedestrianActor = pilot.pedestrian
	var original: Vector2 = walker.global_position
	assert(pilot.world.resident(pilot.walking_npc_id)["local_pedestrian_trip"]["status"] == "walking")
	var navigated: bool = false
	var crossed: bool = false
	for i in range(1500):
		await physics_frame
		if walker.global_position.distance_to(original)>30.0:
			navigated = true
		if walker.crossing_completed:
			crossed = true
		# Sidewalk motion or legal marked crossing only. Never walk sideways
		# through an arbitrary traffic lane or ride over a simulated vehicle.
		var p: Vector2 = walker.global_position
		if p.y > 330.0 and p.y < 374.0:
			assert(absf(p.x - pilot.CROSS_X)<17.0, "Unmarked road crossing")
		assert(p.distance_to(pilot.car.global_position)>13.0, "Walked through vehicle")
		if pilot.world_reported_arrival:
			break
	assert(navigated, "Godot navigation did not move the NPC")
	assert(crossed, "Pedestrian never used the crosswalk")
	assert(pilot.car_yielded, "Lane vehicle never yielded")
	assert(pilot.world_reported_arrival, "Actor failed to report arrival")
	assert(pilot.world.resident(pilot.walking_npc_id)["local_pedestrian_trip"]["status"]=="arrived")
	assert(not SandboxLocalPedestrianTrip.arrive(pilot.world,pilot.walking_npc_id,pilot.SITE), "Double arrival allowed")
	var arrivals: int = 0
	for event in pilot.world.events:
		if event["kind"]=="local_pedestrian_arrived":
			arrivals+=1
	assert(arrivals==1, "Arrival not recorded exactly once")
	var restored: SandboxWorld = SandboxWorld.new()
	assert(restored.restore_snapshot(pilot.world.snapshot()),"Local errand state not restorable")
	assert(restored.resident(pilot.walking_npc_id)["local_pedestrian_trip"]["status"]=="arrived")
	print("STREET_PILOT_PASS native agent, sidewalks, crosswalk, yielding, one world-owned arrival and restore")
	quit()
