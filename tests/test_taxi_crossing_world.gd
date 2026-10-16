extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(SandboxStreetRouteBinding.grounded())
	assert(world.reposition("market","margin_gate"))
	assert(SandboxStreetRouteBinding.on_edge(world))
	assert(not world.begin_crossing_yield(), "No crossing hold before the approach")
	var edge_steps: int=SandboxRoads.edge_minutes("garage","margin_gate")
	assert(edge_steps>=3,"Authored zebra requires multiple world ticks on this road")
	for i in range(edge_steps):
		if SandboxStreetRouteBinding.approaching(world):
			break
		assert(world.advance(1))
	assert(SandboxStreetRouteBinding.approaching(world))
	var elapsed: int=world.route_edge_elapsed
	var before: Vector3=world.player_position()
	var time: int=world.minute
	var distance: int=world.remaining_minutes
	assert(world.begin_crossing_yield())
	assert(not world.begin_crossing_yield())
	assert(world.advance(4),"The city clock and other NPCs keep advancing")
	assert(world.minute==time+4)
	assert(world.route_edge_elapsed==elapsed)
	assert(world.remaining_minutes==distance)
	assert(world.player_position().is_equal_approx(before))
	assert(world.player_position(0.95).is_equal_approx(before),
			"A held taxi must not visually interpolate through the crossing")
	assert(world.route_hold_id==SandboxStreetRouteBinding.CROSSING_ID)
	var saved: SandboxWorld=SandboxWorld.new()
	assert(saved.restore_snapshot(world.snapshot()),"Actual zebra hold must restore from world events")
	var forged: Dictionary=world.snapshot()
	forged["route_hold_id"]=""
	assert(not SandboxWorld.new().restore_snapshot(forged),
			"Cannot remove an active yield latch without a release event")
	assert(world.release_crossing_yield())
	assert(not world.release_crossing_yield())
	assert(world.advance(1))
	assert(world.route_edge_elapsed>elapsed)
	assert(saved.restore_snapshot(world.snapshot()))
	assert(world.route_hold_id.is_empty())
	var started: int=0
	var ended: int=0
	for event in world.events:
		if event["kind"]=="taxi_yield_started":
			started+=1
		elif event["kind"]=="taxi_yield_ended":
			ended+=1
	assert(started==1 and ended==1)
	world.advance(world.remaining_minutes)
	assert(world.player_district=="market" and not world.is_travelling())
	assert(saved.restore_snapshot(world.snapshot()))
	print("TAXI_CROSSING_WORLD_PASS grounded road, clock-without-motion, held display, save events and resumed route")
	quit()
