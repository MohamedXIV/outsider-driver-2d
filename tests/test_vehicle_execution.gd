extends SceneTree

func _initialize() -> void:
	_held_crossing_handoff()
	_native_crosswalk_footprint()
	_fractional_clock()
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
	var bad_handoff: Dictionary=world.snapshot()
	bad_handoff["vehicle_execution"]["player"]["handoff_x"]+=100.0
	assert(not SandboxWorld.new().restore_snapshot(bad_handoff))
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

func _fractional_clock() -> void:
	var world: SandboxWorld=SandboxWorld.new(9)
	assert(world.reposition("clinic"))
	world.vehicle_fraction=.6
	var slices: Array[float]=[]
	world.vehicle_executor=func(seconds: float)->void: slices.append(seconds)
	assert(world.advance(2))
	assert(slices.size()==3 and is_equal_approx(slices[0],.4) and is_equal_approx(slices[1],1.0) and is_equal_approx(slices[2],.6))
	assert(is_equal_approx(world.vehicle_fraction,.6))
	var restored: SandboxWorld=SandboxWorld.new()
	assert(restored.restore_snapshot(world.snapshot()))
	assert(is_equal_approx(restored.vehicle_fraction,.6))
	for invalid in [-.1,1.0,INF,NAN,"0.5"]:
		var corrupt: Dictionary=world.snapshot()
		corrupt["vehicle_fraction"]=invalid
		assert(not SandboxWorld.new().restore_snapshot(corrupt))
	# A legal near-horizon handoff can return beyond base+2 at a late fraction.
	var moving: SandboxWorld=SandboxWorld.new(8)
	assert(moving.reposition("market","margin_gate"))
	assert(SandboxVehicleExecution.bind(moving,"player"))
	assert(SandboxVehicleExecution.report(moving,"player",1.9,1.0,0.0,"motion"))
	SandboxVehicleExecution.unbind(moving,"player",.1)
	assert(moving.advance(1))
	moving.vehicle_fraction=.9
	var before: Vector2=SandboxVehicleExecution.screen(moving,"player",.9)
	assert(SandboxVehicleExecution.bind(moving,"player",.9))
	var cursor: float=float(moving.vehicle_execution["player"]["progress"])
	assert(cursor>3.0)
	assert(SandboxVehicleExecution.report(moving,"player",cursor,1.0,0.0,"motion"))
	assert(SandboxVehicleExecution.screen(moving,"player",.9).distance_to(before)<.001)
	assert(SandboxWorld.new().restore_snapshot(moving.snapshot()))
	var bad_source_clock: Dictionary=world.snapshot()
	for event in bad_source_clock["events"]:
		if event["kind"]=="reposition": event["detail"]["clock_fraction"]=1.0
	assert(not SandboxWorld.new().restore_snapshot(bad_source_clock))
	var legacy: Dictionary=world.snapshot()
	legacy.erase("vehicle_fraction")
	assert(restored.restore_snapshot(legacy) and restored.vehicle_fraction==0.0)

func _native_crosswalk_footprint() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","margin_gate") and world.advance(2))
	assert(SandboxVehicleExecution.bind(world,"player"))
	var travel: Dictionary=SandboxVehicleExecution.trip(world,"player")
	var cross: float=SandboxRoads.edge_minutes("garage","margin_gate")*SandboxStreetRouteBinding.CROSS_FRACTION
	assert(SandboxVehicleExecution.report(world,"player",cross,0.0,SandboxVehicleExecution.tangent(travel,cross).angle(),"motion"))
	assert(SandboxStreetRouteBinding.taxi_occupies_crosswalk(world),"World occupancy must read the accepted native footprint ahead of its integer cursor")
	assert(world.advance(1))
	assert(SandboxVehicleExecution.report(world,"player",5.0,0.0,SandboxVehicleExecution.tangent(travel,5.0).angle(),"motion"))
	assert(not SandboxStreetRouteBinding.taxi_occupies_crosswalk(world),"Whole native taxi cleared the paint despite its earlier integer cursor")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var municipal: SandboxWorld=SandboxWorld.new(8)
	var id: String=""
	for minute in range(100):
		for npc in municipal.residents:
			if npc.get("transit_method","")=="shuttle" and npc.get("transit_nodes",[]).slice(0,2)==["garage","margin_gate"] and int(npc.get("transit_started",-1))==municipal.minute:
				id=str(npc["id"]);break
		if not id.is_empty(): break
		assert(municipal.advance(1))
	assert(not id.is_empty() and municipal.advance(2) and SandboxVehicleExecution.bind(municipal,id))
	travel=SandboxVehicleExecution.trip(municipal,id)
	assert(SandboxVehicleExecution.report(municipal,id,cross,0.0,SandboxVehicleExecution.tangent(travel,cross).angle(),"motion"))
	assert(SandboxWorldTraffic.occupies_zebra(municipal),"Real shuttle footprint must govern pedestrian admission")
	assert(municipal.advance(1))
	assert(SandboxVehicleExecution.report(municipal,id,5.0,0.0,SandboxVehicleExecution.tangent(travel,5.0).angle(),"motion"))
	assert(not SandboxWorldTraffic.occupies_zebra(municipal))
	assert(SandboxWorld.new().restore_snapshot(municipal.snapshot()))

func _held_crossing_handoff() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","margin_gate") and SandboxVehicleExecution.bind(world,"player"))
	var travel: Dictionary=SandboxVehicleExecution.trip(world,"player")
	var facing: float=wrapf(SandboxVehicleExecution.tangent(travel,1.7).angle()+.2,-PI,PI)
	assert(SandboxVehicleExecution.report(world,"player",1.7,0.0,facing,"pedestrian"))
	assert(world.begin_crossing_yield())
	var point: Vector2=SandboxVehicleExecution.screen(world,"player")
	SandboxVehicleExecution.unbind(world,"player")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()),"A sourced early crossing hold must survive presenter unload")
	var forged: Dictionary=world.snapshot()
	forged["events"]=forged["events"].filter(func(e: Dictionary)->bool:return e["kind"]!="vehicle_execution_handoff")
	assert(not SandboxWorld.new().restore_snapshot(forged),"An unloaded held pose requires the matching source handoff event")
	assert(world.advance(2))
	assert(SandboxVehicleExecution.screen(world,"player",.8).distance_to(point)<.001)
	assert(absf(angle_difference(SandboxVehicleExecution.heading(world,"player",.8),facing))<.00001,"Unloaded held taxi must not rotate toward the road tangent")
	assert(SandboxVehicleExecution.bind(world,"player"))
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()),"Reentry must preserve the same early held source")
	assert(absf(angle_difference(SandboxVehicleExecution.heading(world,"player"),facing))<.00001)
