extends SceneTree

func _initialize() -> void:
	var limit: float=SandboxStreetPriority.stop_line()
	assert(limit<SandboxStreetPriority.CROSS_X)
	assert(SandboxStreetPriority.pedestrian_may_enter(limit))
	# Crossing priority must never strand a vehicle that passed its stop line.
	# If a walker reserves late, it waits while the car clears the zebra.
	assert(not SandboxStreetPriority.pedestrian_may_enter(limit+0.01))
	assert(not SandboxStreetPriority.pedestrian_may_enter(limit+2.0))
	assert(not SandboxStreetPriority.pedestrian_may_enter(SandboxStreetPriority.CROSS_X))
	assert(SandboxStreetPriority.pedestrian_may_enter(SandboxStreetPriority.CROSS_X+45.0))
	assert(SandboxStreetPriority.vehicle_velocity(110.0,false,false,0.016)>0)
	assert(SandboxStreetPriority.vehicle_velocity(limit,true,false,0.016)==0.0)
	assert(SandboxStreetPriority.vehicle_velocity(limit,true,true,0.016)>0)
	assert(SandboxStreetPriority.vehicle_velocity(551.0,true,true,0.016)==0.0)
	for dt in [0.016,0.03,0.11,0.3]:
		for x in [115.0,230.0,limit-1.0,limit]:
			var v: float=SandboxStreetPriority.vehicle_velocity(x,true,false,dt)
			assert(x+v*dt <= limit+0.001, "Stop line overshoot at variable frame duration")
	# Reproduce a reservation race: the car is JUST past the line when the
	# pedestrian commits. Its old policy froze inside the crossing forever.
	var clearing_x: float=limit+0.01
	var timestep: float=1.0/30.0
	for _frame in range(120):
		var speed: float=SandboxStreetPriority.vehicle_velocity(
				clearing_x,true,false,timestep)
		assert(speed>0.0,"Late reservation must not stop a car inside the zebra")
		clearing_x+=speed*timestep
		if clearing_x>=SandboxStreetPriority.CROSS_X+SandboxStreetPriority.CLEAR_AHEAD:
			break
	assert(clearing_x>=SandboxStreetPriority.CROSS_X+SandboxStreetPriority.CLEAR_AHEAD,
			"Vehicle never cleared the crossing; pedestrian would deadlock")
	assert(SandboxStreetPriority.pedestrian_may_enter(clearing_x))
	print("STREET_PRIORITY_PASS bounded stop line and late-reservation clearance without deadlock")
	quit()
