extends SceneTree

# Two real Godot lane bodies under a deliberately long native crossing
# reservation. The ordinary unfrozen walker navigation is independently
# checked by test_street_pilot_scene.gd.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var pilot: SandboxStreetPilot=load("res://scenes/street_pilot.tscn").instantiate()
	root.add_child(pilot)
	assert(pilot.car is CharacterBody2D)
	assert(pilot.follower is CharacterBody2D)
	assert(pilot.pedestrian is SandboxPedestrianActor)
	assert(pilot.pedestrian.traffic==pilot.car)
	assert(pilot.pedestrian.traffic_following==pilot.follower)
	var gap: float=SandboxStreetPriority.FOLLOW_SPACING
	assert(pilot.follower.position.x<=pilot.car.position.x-gap)
	# A native resident has reserved the legal zebra. Hold its movement only
	# to give the rear vehicle time to reach its safe following stop.
	var walker: SandboxPedestrianActor=pilot.pedestrian
	walker.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.NORTH_Y+6.0)
	walker.crossing_reserved=true
	walker.crossing_completed=false
	walker.set_physics_process(false)
	walker._agent.avoidance_enabled=false
	var both_stopped: bool=false
	for i in range(400):
		await physics_frame
		assert(pilot.follower.position.x<=pilot.car.position.x-gap+0.25,
				"Trailing physical body must not overlap its leader")
		assert(absf(pilot.follower.position.y-pilot.car.position.y)<0.1)
		if pilot.car.velocity.x<0.01 and pilot.follower.velocity.x<0.01:
			both_stopped=true
			break
	assert(both_stopped,"Both physical cars must stop while this crossing remains reserved")
	assert(pilot.car.position.x<=SandboxStreetPriority.stop_line()+0.2)
	assert(pilot.follower.position.x<=pilot.car.position.x-gap+0.25)
	assert(SandboxStreetPriority.pedestrian_may_enter(pilot.car.position.x))
	assert(SandboxStreetPriority.pedestrian_may_enter(pilot.follower.position.x))
	assert(pilot.car_yielded)
	# The collision body exits the road; both vehicles may resume, and the
	# same real resident continues on the native sidewalk toward its site.
	walker.position=Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.crossing_clear_y())
	walker.crossing_completed=true
	walker.set_physics_process(true)
	var resumed_leader: bool=false
	var resumed_follower: bool=false
	var arrived: bool=false
	for i in range(400):
		await physics_frame
		assert(pilot.follower.position.x<=pilot.car.position.x-gap+0.25,
				"Resumed vehicles must still preserve safe following distance")
		if pilot.car.velocity.x>0.1: resumed_leader=true
		if pilot.follower.velocity.x>0.1: resumed_follower=true
		if pilot.world_reported_arrival:
			arrived=true
			break
	assert(resumed_leader and resumed_follower,
			"Both waiting lane vehicles must resume after actual road clearance")
	assert(arrived,"The world-owned resident failed to reach their actual site")
	assert(SandboxStreetModule.crossing_clear(walker.position))
	assert(pilot.world.resident(pilot.walking_npc_id)["local_pedestrian_trip"]["status"]=="arrived")
	var snapshot: Dictionary=pilot.visual_snapshot()
	assert(snapshot.get("npc_id","")==pilot.walking_npc_id)
	assert(absf(float(snapshot["follower_x"])-pilot.follower.position.x)<0.001)
	assert(SandboxWorld.new().restore_snapshot(pilot.world.snapshot()))
	print("STREET_MULTI_VEHICLE_PASS two native cars stop, maintain gap, resume and share one world-owned zebra arrival")
	quit()
