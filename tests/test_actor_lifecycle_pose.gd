extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(29)
	var ids: Array[String]=SandboxLocalPedestrianTrip.candidates(world)
	assert(ids.size()==2)
	# Establish both trips before ticking either; ticks now autonomously start
	# eligible residents, so sequential manual setup would duplicate departure.
	for id in ids:
		assert(SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	for id in ids:
		var trip: Dictionary=world.resident(id)["local_pedestrian_trip"]
		var slot: int=int(trip["slot"])
		var phase: float=.23
		var anchor: Vector2=SandboxStreetModule.position_at(phase,slot)+Vector2(2,-1)
		assert(SandboxLocalPedestrianTrip.handoff(world,id,phase,anchor,.6))
		var pose: Dictionary=SandboxActorLifecycle.pose(world,world.resident(id),.6)
		assert(pose["id"]==id and pose["kind"]=="local_pedestrian")
		assert(pose["position"].distance_to(SandboxStreetRouteBinding.street_transform()*anchor)<.001,
				"Unloading must retain the actual collision body anchor")
		var saved: SandboxWorld=SandboxWorld.new()
		assert(saved.restore_snapshot(world.snapshot()))
		assert(SandboxActorLifecycle.pose(saved,saved.resident(id),.6)==pose)
		var forged: Dictionary=world.snapshot()
		for person in forged["residents"]:
			if person["id"]==id: person["local_pedestrian_trip"]["handoff_fraction"] = .2
		assert(not SandboxWorld.new().restore_snapshot(forged),"A restored timestamp must match its source event")
		var last: Vector2=pose["position"]
		for fraction in [.65,.7,.75,.8,.85,.9,.95]:
			var next: Vector2=SandboxActorLifecycle.pose(world,world.resident(id),fraction)["position"]
			assert(next.distance_to(last)<20.0,"Far presentation must interpolate the same route")
			last=next
		world.advance(1)
		var expected: Vector2=SandboxLocalPedestrianTrip.offscreen_position(world,id)
		assert(SandboxActorLifecycle.pose(world,world.resident(id),0.0)["position"].distance_to(
				SandboxStreetRouteBinding.street_transform()*expected)<.001)
		assert(SandboxLocalPedestrianTrip.resume(world,id)>=0.0)
		assert(SandboxLocalPedestrianTrip.handoff(world,id,.99,SandboxStreetModule.position_at(.99,slot)))
	world.advance(20)
	for id in ids:
		var pose: Dictionary=SandboxActorLifecycle.pose(world,world.resident(id))
		assert(pose["position"].distance_to(SandboxStreetRouteBinding.street_transform()*
				SandboxStreetModule.destination(int(world.resident(id)["local_pedestrian_trip"]["slot"])))<.001,
				"Local arrival must not jump back to the district marker")
	assert(world.residents.size()==9)
	print("ACTOR_LIFECYCLE_POSE_PASS anchors, fractional progress, restore, two identities and local arrival")
	quit()
