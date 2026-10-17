extends SceneTree

func _initialize() -> void:
	var service: GDScript=load("res://scripts/sandbox/sandbox_local_pedestrian_trip.gd")
	assert(service.has_method("candidates"),"Select two independently eligible world residents")
	var world: SandboxWorld=SandboxWorld.new(12)
	var found: bool=false
	for seed in range(8,150):
		world=SandboxWorld.new(seed)
		var ids: Array=service.call("candidates",world)
		if ids.size()==2:
			found=true
			for id in ids:
				assert(SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
			assert(service.call("reserve",world,ids[0]))
			assert(service.call("reserve",world,ids[1]))
			assert(not service.call("withdraw",world,ids[0],Vector2(320,350)))
			assert(service.call("withdraw",world,ids[0],Vector2(310,313)))
			assert(service.call("reserve",world,ids[0]))
			assert(not service.call("cancel",world,ids[0],Vector2(320,350)),"Cannot cancel a body in the road")
			assert(service.call("cancel",world,ids[0],Vector2(310,313)))
			assert(world.resident(ids[1])["local_pedestrian_trip"]["crossing_state"]=="reserved")
			assert(SandboxWorld.new().restore_snapshot(world.snapshot()),"Independent reservation/cancellation provenance must restore")
			var forged: Dictionary=world.snapshot()
			for npc in forged["residents"]:
				if npc["id"]==ids[1]: npc["local_pedestrian_trip"]["crossing_state"]="cleared"
			assert(not SandboxWorld.new().restore_snapshot(forged))
			print("PEDESTRIAN_RESERVATIONS_PASS seed=%d ids=%s" % [seed,ids])
			break
	assert(found,"A natural seed must supply the two residents; do not invent actors")
	quit()
