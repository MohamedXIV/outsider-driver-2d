extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(29)
	var id: String=SandboxLocalPedestrianTrip.candidate(world)
	assert(SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(SandboxLocalPedestrianTrip.handoff(world,id,.98,SandboxStreetModule.position_at(.98),.6))
	assert(is_equal_approx(SandboxLocalPedestrianTrip.offscreen_progress(world,id,.6),.98))
	assert(SandboxLocalPedestrianTrip.resume(world,id,.8)<0.0)
	assert(world.resident(id)["local_pedestrian_trip"]["status"]=="arrived")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	# Fractional arrival before the next integer minute is a sourced arrival,
	# not a body that claims arrival while its World trip remains offscreen.
	var medical: SandboxWorld=SandboxWorld.new(9)
	var offer: Dictionary={}
	for item in medical.open_offers():
		if item["origin"]=="garage" and SandboxPassengerAlight.applicable(item): offer=item;break
	assert(not offer.is_empty() and medical.accept(str(offer["id"])))
	assert(medical.advance(medical.remaining_minutes))
	var rider: String=str(offer["npc_id"])
	var trip: Dictionary=medical.resident(rider)["passenger_alight"]
	var anchor: Vector2=SandboxAlightGeometry.at(trip,.95)+Vector2(1,-1)
	assert(SandboxPassengerAlight.handoff(medical,rider,.95,anchor,.6))
	assert(SandboxPassengerAlight.offscreen_position(medical,rider,.6).distance_to(anchor)<.001)
	assert(SandboxPassengerAlight.resume(medical,rider,.8)<0.0)
	assert(trip["status"]=="arrived" and is_equal_approx(float(trip["arrived_fraction"]),.8))
	assert(SandboxWorld.new().restore_snapshot(medical.snapshot()))
	var forged: Dictionary=medical.snapshot()
	for person in forged["residents"]:
		if person["id"]==rider: person["passenger_alight"]["arrived_fraction"] = .7
	assert(not SandboxWorld.new().restore_snapshot(forged))
	assert(medical.events.filter(func(e: Dictionary)->bool: return e["kind"]=="fare_settled" and e["subject"]==offer["id"]).size()==1)
	# Version-12 snapshots without fractional stamps retain their old policy.
	var legacy: SandboxWorld=SandboxWorld.new(29)
	var old_id: String=SandboxLocalPedestrianTrip.candidate(legacy)
	assert(SandboxLocalPedestrianTrip.begin(legacy,old_id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(SandboxLocalPedestrianTrip.handoff(legacy,old_id,.3))
	var old: Dictionary=legacy.snapshot()
	for person in old["residents"]:
		if person["id"]==old_id: person["local_pedestrian_trip"].erase("handoff_fraction")
	for event in old["events"]:
		if event["kind"]=="local_pedestrian_handoff": event["detail"].erase("fraction")
	assert(SandboxWorld.new().restore_snapshot(old))
	print("HANDOFF_CLOCK_PASS nonzero anchors, fractional arrival, provenance, version-12 compatibility, one genuine settlement")
	quit()
