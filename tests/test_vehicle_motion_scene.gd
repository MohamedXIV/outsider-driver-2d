extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var pilot: SandboxStreetPilot=load("res://scenes/street_pilot.tscn").instantiate()
	root.add_child(pilot)
	assert(pilot.car is SandboxTrafficVehicle and pilot.follower is SandboxTrafficVehicle)
	var walker: SandboxPedestrianActor=pilot.pedestrian
	walker.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.NORTH_Y+6)
	walker.crossing_reserved=true
	walker.crossing_completed=false
	walker.set_physics_process(false)
	walker._agent.avoidance_enabled=false
	var accelerating: bool=false
	var braking: bool=false
	var slow_before_line: bool=false
	var previous_speed: float=0.0
	var stopped: bool=false
	for i in range(550):
		await physics_frame
		var speed: float=pilot.car.current_speed
		assert(pilot.follower.position.x<=pilot.car.position.x-SandboxStreetPriority.FOLLOW_SPACING+.3)
		if speed>0.1 and speed<SandboxVehicleKinematics.CRUISE-.1: accelerating=true
		if previous_speed>speed+.01:
			braking=true
			if pilot.car.position.x<SandboxStreetPriority.stop_line()-1.0: slow_before_line=true
		assert(pilot.car.position.x<=SandboxStreetPriority.stop_line()+.2,
				"Physical car crossed the reserved native zebra")
		previous_speed=speed
		if pilot.car.position.x>SandboxStreetPriority.stop_line()-.2 and speed<.01:
			stopped=true
			break
	assert(stopped and accelerating and braking and slow_before_line,
			"Native car must visibly accelerate and brake before the pedestrian's crossing")
	var saved: Dictionary=pilot.visual_snapshot()
	assert(SandboxLocalPedestrianTrip.valid_presentation(pilot.world,saved))
	assert(float(saved["car_speed"])<.01)
	var forged: Dictionary=saved.duplicate(true)
	forged["car_speed"]=INF
	assert(not SandboxLocalPedestrianTrip.valid_presentation(pilot.world,forged),
			"Save must reject fabricated infinite vehicle speed")
	var real_world: SandboxWorld=pilot.world
	pilot.queue_free()
	await process_frame
	var restored: SandboxStreetPilot=load("res://scenes/street_pilot.tscn").instantiate()
	restored.world=real_world
	restored.resume_state=saved
	root.add_child(restored)
	assert(is_equal_approx(restored.car.position.x,float(saved["car_x"])))
	assert(is_equal_approx(restored.car.current_speed,float(saved["car_speed"])))
	assert(is_equal_approx(restored.follower.current_speed,float(saved["follower_speed"])))
	var continued: SandboxPedestrianActor=restored.pedestrian
	continued.position=Vector2(SandboxStreetModule.CROSS_X,SandboxStreetModule.crossing_clear_y())
	continued.crossing_completed=true
	continued.crossing_reserved=true
	continued._agent.avoidance_enabled=true
	continued.set_physics_process(true)
	var first_nonzero: float=0.0
	var resumed: bool=false
	for i in range(340):
		await physics_frame
		assert(restored.follower.position.x<=restored.car.position.x-SandboxStreetPriority.FOLLOW_SPACING+.3)
		if restored.car.current_speed>.1 and first_nonzero==0.0:
			first_nonzero=restored.car.current_speed
		if restored.car.position.x>SandboxStreetPriority.CROSS_X+20:
			resumed=true
			break
	assert(first_nonzero>0.0 and first_nonzero<SandboxVehicleKinematics.CRUISE*.5,
			"Cars cannot snap instantly to max speed after walker clearance")
	assert(resumed,"Restored physical traffic never accelerated after crossing clearance")
	print("VEHICLE_MOTION_SCENE_PASS gradual native acceleration, braking, gap, persisted speed, replay")
	quit()
