extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	var shuttle_id: String=""
	for i in range(100):
		for npc in world.residents:
			if SandboxWorldTraffic.approaching_zebra(world,npc):
				shuttle_id=str(npc["id"])
				break
		if not shuttle_id.is_empty(): break
		assert(world.advance(1))
	assert(not shuttle_id.is_empty(),"World ecology did not generate a real garage feeder shuttle")
	var npc: Dictionary=world.resident(shuttle_id)
	var offer_id: String=str(npc["transit_from_offer"])
	var depart: int=int(npc["transit_started"])
	var original_arrival: int=int(npc["transit_until"])
	var original_pose: Vector3=world.npc_position(npc)
	assert(npc["transit_method"]=="shuttle")
	assert(world.begin_shuttle_crossing_yield(shuttle_id))
	var held_before: Dictionary=SandboxWorldTraffic.shuttle_pose(world,npc,0.5)
	assert(not held_before.is_empty() and held_before["render_position"].is_finite())
	assert(not world.begin_shuttle_crossing_yield(shuttle_id))
	assert(world.advance(3))
	npc=world.resident(shuttle_id)
	assert(int(npc["transit_until"])==original_arrival+3)
	assert(int(npc["transit_pause_minutes"])==3)
	assert(world.npc_position(npc).is_equal_approx(original_pose))
	assert(SandboxWorldTraffic.shuttle_pose(world,npc,0.8)["position"].is_equal_approx(original_pose))
	var held_after: Dictionary=SandboxWorldTraffic.shuttle_pose(world,npc,0.8)
	assert(held_after["render_position"].is_equal_approx(held_before["render_position"]),
			"Waiting at the zebra must freeze the directed-lane shuttle position")
	assert(is_equal_approx(float(held_after["render_heading"]),float(held_before["render_heading"])),
			"Waiting at the zebra must not rotate the displayed shuttle")
	var copy: SandboxWorld=SandboxWorld.new()
	assert(copy.restore_snapshot(world.snapshot()))
	var held_copy: Dictionary=SandboxWorldTraffic.shuttle_pose(copy,copy.resident(shuttle_id),0.8)
	assert(held_copy["render_position"].is_equal_approx(held_after["render_position"]))
	assert(is_equal_approx(float(held_copy["render_heading"]),float(held_after["render_heading"])))
	var forged: Dictionary=world.snapshot()
	for resident in forged["residents"]:
		if resident.get("id","")==shuttle_id:
			resident["transit_pause_minutes"]=0
	assert(not SandboxWorld.new().restore_snapshot(forged),
			"An active shuttle hold cannot erase time while its event ledger remains")
	assert(world.release_shuttle_crossing_yield(shuttle_id))
	assert(not world.release_shuttle_crossing_yield(shuttle_id))
	assert(world.advance(1))
	assert(world.npc_position(world.resident(shuttle_id)).distance_to(original_pose)>0.001)
	assert(copy.restore_snapshot(world.snapshot()))
	var leave_at: int=int(world.resident(shuttle_id)["transit_until"])
	assert(leave_at==original_arrival+3)
	assert(world.advance(leave_at-world.minute))
	assert(world.resident(shuttle_id)["transit_method"]=="")
	var started: int=0
	var ended: int=0
	var arrivals: int=0
	for event in world.events:
		if event["subject"]!=shuttle_id: continue
		if event["kind"]=="npc_shuttle_yield_started": started+=1
		if event["kind"]=="npc_shuttle_yield_ended":
			ended+=1
			assert(event["detail"]["wait_minutes"]==3)
		if event["kind"]=="npc_alternative_arrived" \
				and event["detail"]["offer_id"]==offer_id:
			arrivals+=1
	assert(started==1 and ended==1 and arrivals==1)
	assert(copy.restore_snapshot(world.snapshot()))
	assert(int(copy.resident(shuttle_id)["transit_pause_minutes"])==0)
	assert(depart<original_arrival)
	print("SHUTTLE_CROSSING_WORLD_PASS real trip stops, clock continues, save ledger, arrival delayed and exactly-once arrival")
	quit()
