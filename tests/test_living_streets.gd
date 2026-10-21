extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(29)
	var ids: Array[String]=SandboxLocalPedestrianTrip.candidates(world)
	assert(ids.size()==2)
	assert(world.advance(1))
	for id in ids:
		var trip: Dictionary=world.resident(id).get("local_pedestrian_trip",{})
		assert(trip.get("status","")=="offscreen", "World ticks must initiate genuine local errands without a presenter")
		assert(world.resident(id)["activity"]=="travelling")
		assert(SandboxLocalPedestrianTrip.valid_history(world.resident(id),world.events,world.minute))
	var restored: SandboxWorld=SandboxWorld.new()
	assert(restored.restore_snapshot(world.snapshot()))
	assert(restored.advance(2))
	var departures: int=0
	for event in restored.events:
		if event["kind"]=="local_pedestrian_departed": departures+=1
	assert(departures==2, "Ticks must not duplicate errands")
	assert(SandboxStreetModule.destination(1).x>SandboxStreetModule.NORTH_SIDEWALK.end.x,
			"Second resident's physical goal must use the adjacent block")
	assert(restored.advance(20))
	for id in ids:
		assert(restored.resident(id)["local_pedestrian_trip"]["status"]=="arrived")
		assert(int(restored.resident(id)["need"])<30, "Completing a local purpose must relieve the resident's need")
		assert(int(restored.resident(id)["cooldown_until"])>restored.minute)
	print("LIVING_STREETS_PASS world-owned autonomous departures, stable identities, adjacent goal and restore")
	quit()
