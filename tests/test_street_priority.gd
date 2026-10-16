extends SceneTree

func _initialize() -> void:
	var limit: float=SandboxStreetPriority.stop_line()
	assert(limit<SandboxStreetPriority.CROSS_X)
	assert(SandboxStreetPriority.pedestrian_may_enter(limit))
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
	print("STREET_PRIORITY_PASS stop-line braking, non-overlap right of way and bounded delta")
	quit()
