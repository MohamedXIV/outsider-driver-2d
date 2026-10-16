extends SceneTree
func _initialize() -> void:
	var w: SandboxWorld = SandboxWorld.new(8)
	assert(w.player_district == "garage")
	var origin: Vector3 = w.player_position()
	assert(w.reposition("market"))
	assert(w.is_travelling() and w.player_district == "garage")
	assert(not w.accept("invalid"))
	assert(w.advance(1))
	assert(w.player_position().distance_to(origin)>0)
	var restored: SandboxWorld = SandboxWorld.new()
	assert(restored.restore_snapshot(w.snapshot()))
	assert(restored.player_position().is_equal_approx(w.player_position()))
	w.advance(w.remaining_minutes)
	restored.advance(restored.remaining_minutes)
	assert(w.player_district=="market" and not w.is_travelling())
	assert(w.snapshot()==restored.snapshot())
	var fare_world: SandboxWorld = SandboxWorld.new(8)
	var chosen: Dictionary = {}
	for o in fare_world.open_offers():
		if o["origin"]=="garage" and o["channel"]!="official": chosen=o; break
	assert(not chosen.is_empty(), "No actual local fare in baseline city")
	assert(fare_world.accept(chosen["id"]))
	fare_world.advance(1)
	assert(fare_world.resident(chosen["npc_id"])["activity"]=="travelling")
	assert(fare_world.npc_position(fare_world.resident(chosen["npc_id"])).is_equal_approx(fare_world.player_position()))
	assert(restored.restore_snapshot(fare_world.snapshot()))
	fare_world.advance(fare_world.remaining_minutes)
	restored.advance(restored.remaining_minutes)
	assert(fare_world.snapshot()==restored.snapshot())
	var balance: int = fare_world.credits
	fare_world.advance(1)
	assert(fare_world.credits==balance)
	var bad: Dictionary = restored.snapshot()
	bad["route_nodes"]=["garage","terraces"]
	assert(not SandboxWorld.new().restore_snapshot(bad))
	print("CITY_JOURNEYS_PASS physical relocation, passenger movement, mid-edge replay, once-only settlement")
	quit()
