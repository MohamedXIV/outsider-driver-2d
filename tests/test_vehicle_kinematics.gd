extends SceneTree

func _initialize() -> void:
	var motion: float=SandboxVehicleKinematics.next_speed(0.0,36.0,0.1)
	assert(motion>0.0 and motion<36.0)
	assert(is_equal_approx(motion,4.8))
	assert(is_equal_approx(SandboxVehicleKinematics.next_speed(36.0,0.0,0.1),26.4))
	assert(SandboxVehicleKinematics.next_speed(6,36,0)==6.0)
	assert(SandboxVehicleKinematics.next_speed(INF,36,.2)==0.0)
	var x: float=120.0
	var speed: float=0.0
	var stopped: bool=false
	var decelerated: bool=false
	var last_speed: float=0.0
	var limit: float=SandboxStreetPriority.stop_line()
	for i in range(480):
		var delta: float=1.0/60.0
		var max_allowed: float=SandboxStreetPriority.vehicle_velocity(x,true,false,delta)
		max_allowed=minf(max_allowed,SandboxVehicleKinematics.braking_speed(limit-x))
		speed=minf(SandboxVehicleKinematics.next_speed(speed,max_allowed,delta),max_allowed)
		x+=speed*delta
		assert(x<=limit+.001, "Predictive braking crossed the protected stop line")
		if last_speed>speed+.01 and x<limit-1.0: decelerated=true
		last_speed=speed
		if absf(limit-x)<.02 and speed<.01:
			stopped=true
			break
	assert(stopped and decelerated,"Car must brake BEFORE the zebra, not snap only at the stop line")
	var reversed_yaw: float=SandboxVehicleKinematics.turn_heading(PI-.1,-PI+.2,0.016)
	assert(absf(angle_difference(PI-.1,reversed_yaw))<=SandboxVehicleKinematics.TURN_RATE*.016+.001)
	assert(SandboxVehicleKinematics.turn_heading(0,PI/2.0,.1)<.3)
	print("VEHICLE_KINEMATICS_PASS acceleration, predictive braking, wrap-safe capped turns, stop boundary")
	quit()
