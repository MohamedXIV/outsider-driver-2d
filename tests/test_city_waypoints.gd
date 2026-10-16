extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","depot"))
	assert(world.route_nodes==SandboxRoads.path("garage","market","depot"),"Relocation must honor its previewed waypoint")
	world=SandboxWorld.new(8)
	world.player_district="clinic" # Independent authored route fixture with initial funds.
	var via: Array[String]=["basin_turn","market","margin_gate","bridge_east","bridge_west"]
	assert(world.reposition("depot","",via))
	assert(world.route_nodes==["clinic","basin_turn","market","old_square","margin_gate","bridge_east","bridge_west","worker_gate","depot"])
	print("CITY_WAYPOINTS_PASS single waypoint and playable under-ramp-deck sequence")
	quit()
