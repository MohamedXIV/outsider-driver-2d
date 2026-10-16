extends SceneTree

func _initialize() -> void:
	assert(SandboxCityData.REGIONS.size() == 6)
	assert(SandboxRoads.LINKS.size() >= 24)
	for a in SandboxRoads.DISTRICTS:
		for b in SandboxRoads.DISTRICTS:
			assert(not SandboxRoads.path(a, b).is_empty(), "Disconnected city stop")
	var short_trip: Array[String] = SandboxRoads.path("garage", "shelter")
	var long_trip: Array[String] = SandboxRoads.path("garage", "terraces")
	assert(SandboxRoads.path_minutes(long_trip) > SandboxRoads.path_minutes(short_trip) * 2)
	assert(SandboxRoads.path_metres(long_trip) > 10000.0)
	assert(SandboxRoads.edge_metres("basin_turn", "market") > SandboxRoads.map_position("basin_turn").distance_to(SandboxRoads.map_position("market")))
	assert(not SandboxRoads.connected("basin_turn", "bridge_west"))
	assert(SandboxRoads.connected("margin_gate", "bridge_east"))
	assert(SandboxRoads.sample_edge("margin_gate", "bridge_east", 0.5).y > 0)
	assert(SandboxRoads.sample_edge("bridge_east", "bridge_west", 0.5).y == 160)
	var route: Array[String] = ["clinic", "basin_turn", "market", "old_square", "margin_gate", "bridge_east", "bridge_west", "worker_gate", "depot"]
	assert(SandboxRoads.valid_path(route))
	for i in range(route.size()-1):
		assert(SandboxRoads.sample_edge(route[i], route[i+1], 0).is_equal_approx(SandboxRoads.map_position(route[i])))
		assert(SandboxRoads.sample_edge(route[i], route[i+1], 1).is_equal_approx(SandboxRoads.map_position(route[i+1])))
	print("CITY_GRAPH_PASS short=%dm long=%dm distance=%.1fkm nodes=%d" % [SandboxRoads.path_minutes(short_trip), SandboxRoads.path_minutes(long_trip), SandboxRoads.path_metres(long_trip)/1000.0, SandboxRoads.LINKS.size()])
	quit()
