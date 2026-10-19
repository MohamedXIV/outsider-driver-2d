extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(9)
	var offer: Dictionary={}
	for item in world.open_offers():
		if item["origin"]=="garage" and SandboxPassengerAlight.applicable(item): offer=item;break
	assert(not offer.is_empty() and world.accept(str(offer["id"])))
	var planned: int=world.remaining_minutes
	var population: int=world.residents.size()
	assert(SandboxVehicleExecution.bind(world,"player"))
	assert(not SandboxVehicleExecution.bind(world,"invented"))
	var start: int=world.minute
	assert(world.advance(5))
	assert(world.minute==start+5 and world.remaining_minutes==planned)
	assert(world.residents.size()==population and world.player_position().is_finite())
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(not SandboxVehicleExecution.report(world,"player",3.0,0.0,0.0,"motion"))
	assert(SandboxVehicleExecution.report(world,"player",.6,5.0,0.0,"vehicle"))
	assert(not SandboxVehicleExecution.report(world,"player",.5,5.0,0.0,"vehicle"))
	var copy: SandboxWorld=SandboxWorld.new()
	assert(copy.restore_snapshot(world.snapshot()))
	assert(copy.player_position().distance_to(world.player_position())<.001)
	var forged: Dictionary=world.snapshot()
	forged["vehicle_execution"]["player"]["source"]="fare:invented"
	assert(not SandboxWorld.new().restore_snapshot(forged))
	SandboxVehicleExecution.unbind(world,"player",.6)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.advance(planned+2))
	assert(not world.is_travelling())
	assert(world.events.filter(func(e: Dictionary)->bool:return e["kind"]=="fare_settled" and e["subject"]==offer["id"]).size()==1)
	assert(world.residents.size()==population)
	var municipal: SandboxWorld=SandboxWorld.new(8)
	var shuttle_id: String=""
	for minute in range(100):
		for person in municipal.residents:
			if SandboxWorldTraffic.approaching_zebra(municipal,person): shuttle_id=str(person["id"]);break
		if not shuttle_id.is_empty(): break
		assert(municipal.advance(1))
	assert(not shuttle_id.is_empty())
	var passenger: Dictionary=municipal.resident(shuttle_id)
	var scheduled: int=int(passenger["transit_until"])
	assert(SandboxVehicleExecution.bind(municipal,shuttle_id))
	assert(municipal.advance(3))
	assert(int(passenger["transit_until"])==scheduled+3)
	assert(int(passenger["transit_pause_minutes"])==3)
	assert(SandboxWorld.new().restore_snapshot(municipal.snapshot()))
	var bad_pose: Dictionary=municipal.snapshot()
	bad_pose["vehicle_execution"][shuttle_id]["x"]+=100.0
	assert(not SandboxWorld.new().restore_snapshot(bad_pose))
	SandboxVehicleExecution.unbind(municipal,shuttle_id)
	assert(municipal.advance(int(passenger["transit_until"])-municipal.minute+2))
	assert(SandboxWorld.new().restore_snapshot(municipal.snapshot()))
	print("VEHICLE_EXECUTION_PASS genuine fare, bounded reports, held city ticks, source validation, continuous handoff, once-only settlement")
	quit()
