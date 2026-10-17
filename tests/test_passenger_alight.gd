extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: SandboxWorld = SandboxWorld.new(9)
	var offer: Dictionary = {}
	for candidate in world.open_offers():
		if candidate["origin"] == "garage" and SandboxPassengerAlight.applicable(candidate):
			offer = candidate
			break
	assert(not offer.is_empty(), "Use a real seeded medical resident and actual garage fare")
	assert(world.accept(str(offer["id"])))
	var minutes: int = world.remaining_minutes
	assert(minutes > 1 and world.advance(minutes))
	assert(offer["status"] == "completed")
	var npc: Dictionary = world.resident(str(offer["npc_id"]))
	var trip: Dictionary = npc.get("passenger_alight", {})
	assert(trip.get("status", "") == "walking" and trip.get("site", "") == SandboxPassengerAlight.SITE)
	assert(npc["location"] == "clinic" and npc["taxi_offer"] == "")
	assert(world.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "fare_settled" and e.get("subject", "") == offer["id"]).size() == 1)
	assert(world.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "rider_alight_started" and e.get("subject", "") == npc["id"]).size() == 1)
	var restored: SandboxWorld = SandboxWorld.new()
	assert(restored.restore_snapshot(world.snapshot()), "Walking alight must survive world restore")
	var id: String = str(npc["id"])
	assert(SandboxPassengerAlight.handoff(world,id,.4))
	assert(not SandboxPassengerAlight.handoff(world,id,.6), "No duplicate offscreen transitions")
	assert(world.advance(1))
	assert(is_equal_approx(SandboxPassengerAlight.offscreen_progress(world,id),.9))
	assert(SandboxPassengerAlight.resume(world,id) > .89)
	assert(world.resident(id)["passenger_alight"]["status"] == "walking")
	assert(world.advance(1))
	assert(SandboxPassengerAlight.arrive(world,id,SandboxAlightGeometry.goal(world.resident(id)["passenger_alight"])))
	assert(not SandboxPassengerAlight.arrive(world,id,Vector2.ZERO))
	assert(world.resident(id)["passenger_alight"]["status"] == "arrived")
	assert(world.events.filter(func(e: Dictionary) -> bool:
		return e.get("kind", "") == "rider_alight_arrived" and e.get("subject", "") == id).size() == 1)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()), "Finished sourced arrival must restore")
	var forged: Dictionary = world.snapshot()
	for fake in forged["residents"]:
		if fake["id"] == id: fake["passenger_alight"]["arrived"] = world.minute - 1
	assert(not SandboxWorld.new().restore_snapshot(forged), "Tampered arrival time must not pass")
	var second: SandboxWorld = SandboxWorld.new(9)
	assert(second.accept(str(offer["id"])) == false, "An offer is not shared between independent worlds")
	print("PASSENGER_ALIGHT_PASS real medical fare, sourced lifecycle, offscreen progress, replay and tamper guard")
	quit()
