extends SceneTree

# Proves one world resident changes movement fidelity across a player-
# proximity boundary, including progress continuity and event provenance.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node2D=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var world: SandboxWorld=scene._world
	scene._process(.25)
	assert(scene._street_pilot!=null)
	var npc_id: String=scene._street_pilot.walking_npc_id
	for i in range(85):
		await physics_frame
	var phase: float=SandboxStreetModule.progress_of(scene._street_pilot.pedestrian.position)
	assert(phase>0.02 and phase<1.0)
	# Proximity boundary is exercised directly; normal game travel reaches
	# the same boundary through repositioning and route ticks.
	world.player_district="shelter"
	scene._sync_local_pedestrian()
	assert(scene._street_pilot==null)
	assert(scene._city.local_active_npc_id.is_empty())
	assert(world.resident(npc_id)["local_pedestrian_trip"]["status"]=="offscreen")
	var first: float=SandboxLocalPedestrianTrip.offscreen_progress(world,npc_id)
	assert(absf(first-phase)<0.005)
	assert(not SandboxLocalPedestrianTrip.handoff(world,npc_id,phase))
	var saved: SandboxWorld=SandboxWorld.new()
	assert(saved.restore_snapshot(world.snapshot()))
	world.advance(2)
	assert(SandboxLocalPedestrianTrip.offscreen_progress(world,npc_id)>first)
	assert(world.resident(npc_id)["local_pedestrian_trip"]["status"]=="offscreen")
	# Player reenters while the world resident is still travelling.
	world.player_district="garage"
	scene._sync_local_pedestrian()
	assert(scene._street_pilot!=null)
	assert(scene._street_pilot.walking_npc_id==npc_id)
	assert(scene._street_pilot.world==world)
	assert(world.resident(npc_id)["local_pedestrian_trip"]["status"]=="walking")
	var resumed: float=SandboxStreetModule.progress_of(scene._street_pilot.pedestrian.position)
	assert(resumed>first+0.10,"Offscreen handoff lost travel progress")
	assert(resumed<1.0)
	assert(saved.restore_snapshot(world.snapshot()))
	var back: Vector2=scene._street_pilot.pedestrian.position
	# Leave again without allowing local physics to complete; the world alone
	# will resolve the distance while the region has no active agent.
	world.player_district="shelter"
	scene._sync_local_pedestrian()
	assert(scene._street_pilot==null)
	world.advance(20)
	assert(world.resident(npc_id)["local_pedestrian_trip"]["status"]=="arrived")
	assert(SandboxLocalPedestrianTrip.candidate(world)!=npc_id)
	assert(SandboxLocalPedestrianTrip.offscreen_progress(world,npc_id)<0.0)
	var arrivals: int=0
	for evt in world.events:
		if evt.get("subject","")==npc_id and evt.get("kind","")=="local_pedestrian_arrived":
			arrivals+=1
	assert(arrivals==1)
	world.advance(10)
	assert(not SandboxLocalPedestrianTrip.arrive(world,npc_id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(saved.restore_snapshot(world.snapshot()))
	var tampered: Dictionary=world.snapshot()
	for npc in tampered["residents"]:
		if npc.get("id","")==npc_id:
			npc["local_pedestrian_trip"]["handoff_progress"]=0.01
	assert(not SandboxWorld.new().restore_snapshot(tampered),
			"A save may not silently change prior movement handoff provenance")
	print("STREET_HANDOFF_PASS nearby native, offscreen progress, return continuity, exactly-once arrival and provenance")
	quit()
