extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","margin_gate"))
	while not SandboxStreetRouteBinding.approaching(world): assert(world.advance(1))
	assert(world.begin_crossing_yield())
	var before: Dictionary=world.snapshot()
	var screen: Vector2=SandboxDirectedLanes.taxi_screen(world,0.0)
	var elapsed: float=SandboxDirectedLanes.taxi_elapsed_minutes(world,0.0)
	for fraction in [0.0,.25,.5,.75,.99]:
		assert(SandboxDirectedLanes.taxi_screen(world,fraction).distance_to(screen)<.001,
				"World-owned crossing hold must freeze the directed taxi pose")
		assert(is_equal_approx(SandboxDirectedLanes.taxi_elapsed_minutes(world,fraction),elapsed),
				"Held heading samples must use the same frozen lane progress")
	assert(world.snapshot()==before,"Presentation cannot release or advance a legitimate hold")
	var restored: SandboxWorld=SandboxWorld.new()
	assert(restored.restore_snapshot(before))
	assert(SandboxDirectedLanes.taxi_screen(restored,.75).distance_to(screen)<.001)
	# All real graph junctions, including transitions to the unprofiled ramp
	# and approaches to the four-lane Freight Spine, must be continuous.
	var checked: int=0
	for a in SandboxRoads.LINKS:
		for b in SandboxRoads.LINKS[a]:
			for c in SandboxRoads.LINKS[b]:
				if a==c: continue
				var route: Array[String]=[str(a),str(b),str(c)]
				var p: Vector3=SandboxDirectedLanes.route_lane_point(route,0,1.0)
				var q: Vector3=SandboxDirectedLanes.route_lane_point(route,1,0.0)
				assert(p.is_finite() and p.distance_to(q)<.01,
						"A legal road boundary cannot pop from lane to centerline: %s"%[route])
				checked+=1
	assert(checked>50)
	assert(world.release_crossing_yield())
	assert(world.advance(world.remaining_minutes))
	assert(world.reposition("clinic"))
	assert(world.advance(world.remaining_minutes))
	var parked: Vector2=SandboxDirectedLanes.taxi_screen(world,0.0)
	assert(world.reposition("docks"))
	assert(SandboxDirectedLanes.taxi_screen(world,0.0).distance_to(parked)<.001,
			"Starting the next legal trip must not teleport across opposing lanes")
	print("DIRECTED_LANE_CONTINUITY_PASS held pose and heading, persisted provenance, %d authored junctions"%checked)
	quit()
