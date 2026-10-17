extends SceneTree

# Two native CharacterBody2D cars follow one physical lane; both obey the
# same world-owned pedestrian's zebra right of way without overlapping.
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
	var stopped_leader: bool=false
	var stopped_follower: bool=false
	var cleared: bool=false
	var arrived: bool=false
	var frames_checked: int=0
	for i in range(1500):
		await physics_frame
		frames_checked+=1
		assert(pilot.follower.position.x<=pilot.car.position.x-gap+0.25,
				"Second live physics car overlapped or overtook the leading body")
		assert(absf(pilot.follower.position.y-pilot.car.position.y)<0.1)
		var reserved: bool=pilot.pedestrian.crossing_reserved and not pilot.pedestrian.crossing_completed
		if reserved:
			if pilot.car.position.x<=SandboxStreetPriority.stop_line()+0.15 \
					and pilot.car.velocity.x<0.01:
				stopped_leader=true
			if pilot.follower.velocity.x<0.01:
				stopped_follower=true
		if pilot.pedestrian.crossing_completed:
			cleared=true
		if pilot.world_reported_arrival:
			arrived=true
			break
	assert(frames_checked>1)
	assert(stopped_leader,"Leading car never yielded to its real walking resident")
	assert(stopped_follower,"Follower never yielded or stopped behind the first car")
	assert(cleared and arrived,"Real pedestrian must clear road and arrive exactly once")
	assert(SandboxStreetModule.crossing_clear(pilot.pedestrian.position))
	assert(pilot.world.resident(pilot.walking_npc_id)["local_pedestrian_trip"]["status"]=="arrived")
	assert(pilot.follower.position.x<=pilot.car.position.x-gap+0.25)
	var saved: Dictionary=pilot.visual_snapshot()
	assert(saved.get("npc_id","")==pilot.walking_npc_id)
	assert(absf(float(saved["car_x"])-pilot.car.position.x)<0.001)
	assert(absf(float(saved["follower_x"])-pilot.follower.position.x)<0.001)
	assert(SandboxWorld.new().restore_snapshot(pilot.world.snapshot()))
	print("STREET_MULTI_VEHICLE_PASS two native lane bodies, safe gap, shared zebra yielding, world-owned arrival and snapshot")
	quit()
