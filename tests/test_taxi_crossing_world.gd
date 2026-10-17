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
	# Return home on the SAME physical zebra from the opposite direction.
	# The projected crossing stays at 35% garage->feeder but is traversed at
	# 65% feeder->garage. Reverse journeys must obey identical right-of-way.
	assert(is_equal_approx(SandboxStreetRouteBinding.crossing_fraction(
			SandboxStreetRouteBinding.TO,SandboxStreetRouteBinding.FROM),0.65))
	assert(SandboxStreetRouteBinding.crossing_fraction("market","garage")<0.0)
	assert(world.reposition("garage","margin_gate"))
	for i in range(world.remaining_minutes):
		if SandboxStreetRouteBinding.on_edge(world):
			break
		assert(world.advance(1))
	assert(SandboxStreetRouteBinding.on_edge(world),"Return trip missed the Patchworks feeder")
	assert(world.route_nodes[world.route_segment]==SandboxStreetRouteBinding.TO)
	assert(world.route_nodes[world.route_segment+1]==SandboxStreetRouteBinding.FROM)
	assert(SandboxStreetRouteBinding.in_neighborhood(world),
			"Return-leg pedestrian must be physically loaded before reaching the zebra")
	assert(not world.begin_crossing_yield(),"Return taxi cannot yield before the reverse approach")
	for i in range(SandboxRoads.edge_minutes(SandboxStreetRouteBinding.TO,
			SandboxStreetRouteBinding.FROM)):
		if SandboxStreetRouteBinding.approaching(world):
			break
		assert(world.advance(1))
	assert(SandboxStreetRouteBinding.approaching(world),"Reverse route never approached the zebra")
	var reverse_elapsed: int=world.route_edge_elapsed
	var reverse_point: Vector3=world.player_position()
	var reverse_remaining: int=world.remaining_minutes
	assert(world.begin_crossing_yield())
	assert(world.advance(3),"Time and resident ecology should continue while reverse taxi waits")
	assert(world.route_edge_elapsed==reverse_elapsed and world.remaining_minutes==reverse_remaining)
	assert(world.player_position().is_equal_approx(reverse_point))
	assert(SandboxStreetRouteBinding.in_neighborhood(world),
			"An actually held return taxi must retain its local pedestrian actor")
	assert(saved.restore_snapshot(world.snapshot()),"Reverse-direction hold must survive save restore")
	var reverse_forged: Dictionary=world.snapshot()
	reverse_forged["route_hold_id"]=""
	assert(not SandboxWorld.new().restore_snapshot(reverse_forged),
			"Reverse hold cannot be erased without an end event")
	assert(world.release_crossing_yield())
	assert(world.advance(1))
	assert(world.route_edge_elapsed>reverse_elapsed)
	assert(saved.restore_snapshot(world.snapshot()))
	assert(world.advance(world.remaining_minutes))
	assert(world.player_district=="garage" and not world.is_travelling())
	var reverse_starts: int=0
	var reverse_ends: int=0
	for event in world.events:
		if event["kind"]=="taxi_yield_started": reverse_starts+=1
		if event["kind"]=="taxi_yield_ended": reverse_ends+=1
	assert(reverse_starts==2 and reverse_ends==2,
			"Outbound and inbound visits must each have one matched yield pair")
	# Real grade-separation guard: the player can physically travel over the
	# elevated western viaduct. That 160m deck is NOT the grounded Patchworks
	# zebra, even if both shapes are visible in the same 2D projection.
	var bridge_world: SandboxWorld=SandboxWorld.new(8)
	assert(SandboxRoads.connected("bridge_east","bridge_west"))
	assert(SandboxRoads.map_position("bridge_east").y>=100.0)
	assert(SandboxRoads.map_position("bridge_west").y>=100.0)
	assert(bridge_world.reposition("depot","bridge_west"))
	var reached_deck: bool=false
	for _tick in range(bridge_world.remaining_minutes):
		if bridge_world.is_travelling() and \
				bridge_world.route_nodes[bridge_world.route_segment]=="bridge_east" and \
				bridge_world.route_nodes[bridge_world.route_segment+1]=="bridge_west":
			reached_deck=true
			break
		assert(bridge_world.advance(1))
	assert(reached_deck,"The authored viaduct should be reachable by an actual taxi route")
	assert(bridge_world.player_position().y>=100.0)
	assert(not SandboxStreetRouteBinding.on_edge(bridge_world))
	assert(not SandboxStreetRouteBinding.in_neighborhood(bridge_world))
	assert(not SandboxStreetRouteBinding.approaching(bridge_world))
	assert(not SandboxStreetRouteBinding.taxi_occupies_crosswalk(bridge_world))
	assert(not bridge_world.begin_crossing_yield(),
			"Grounded zebra must not stop a taxi driving on an elevated bridge")
	assert(bridge_world.route_hold_id.is_empty())
	assert(bridge_world.advance(1))
	assert(bridge_world.route_hold_id.is_empty())
	print("TAXI_CROSSING_WORLD_PASS bidirectional grounded zebra, grade-separated deck, held clock, save provenance and resumed trips")
	quit()
