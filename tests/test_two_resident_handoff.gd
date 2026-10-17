extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(29)
	var ids: Array[String]=SandboxLocalPedestrianTrip.candidates(world)
	assert(ids.size()==2)
	for i in range(2):
		assert(SandboxLocalPedestrianTrip.begin(world,ids[i],SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
		assert(SandboxLocalPedestrianTrip.reserve(world,ids[i]))
		assert(SandboxLocalPedestrianTrip.handoff(world,ids[i],.35+.30*i))
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	world.advance(1)
	var a: float=SandboxLocalPedestrianTrip.resume(world,ids[0])
	var b: float=SandboxLocalPedestrianTrip.resume(world,ids[1])
	assert(b>a+.25 and a>0.35)
	assert(SandboxLocalPedestrianTrip.handoff(world,ids[0],a))
	assert(SandboxLocalPedestrianTrip.handoff(world,ids[1],b))
	world.advance(20)
	for id in ids:
		var arrivals: int=0
		for evt in world.events:
			if evt["subject"]==id and evt["kind"]=="local_pedestrian_arrived": arrivals+=1
		assert(arrivals==1)
		assert(world.resident(id)["local_pedestrian_trip"]["status"]=="arrived")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	# Presentation flags cannot impersonate a world-owned arrival or another resident.
	var bad: Dictionary={"actors":{ids[0]:{"npc_id":ids[0],"pedestrian_x":320.0,"pedestrian_y":350.0,"crossing_reserved":true,"crossing_completed":true,"did_arrive":true}}}
	assert(not SandboxLocalPedestrianTrip.valid_presentation(world,bad))
	print("TWO_RESIDENT_HANDOFF_PASS distinct progress, independent ledgers, resume, offscreen once-only arrivals and forged-view rejection")
	quit()
