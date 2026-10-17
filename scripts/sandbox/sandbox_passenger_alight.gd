class_name SandboxPassengerAlight
extends RefCounted

# One real fare settlement can produce one world-owned local onward goal.
# This is an authored Night Clinic sidewalk slice, not a citywide puppet clock.
const SITE: String = "clinic:intake"
const OFFSCREEN_MINUTES: float = 2.0

static func applicable(offer: Dictionary) -> bool:
	return offer.get("destination", "") == "clinic" and offer.get("purpose", "") == "medical"

static func begin(world: SandboxWorld, npc: Dictionary, offer: Dictionary, arrived_from: String) -> bool:
	if not applicable(offer) or npc.is_empty() or str(npc.get("location", "")) != "clinic" \
			or not str(npc.get("taxi_offer", "")).is_empty() \
			or not SandboxRoads.connected(arrived_from, "clinic") \
			or offer.get("status", "") != "completed" or npc.get("id", "") != offer.get("npc_id", ""):
		return false
	if npc.get("passenger_alight", {}).get("status", "") in ["walking", "offscreen"]:
		return false
	var source: String = str(offer["id"])
	var settled: bool = false
	for evt in world.events:
		if evt.get("kind", "") == "fare_settled" and evt.get("subject", "") == source:
			settled = true
	if not settled: return false
	npc["passenger_alight"] = {"status": "walking", "site": SITE,
			"offer_id": source, "from": arrived_from, "started": world.minute}
	world._record("rider_alight_started", str(npc["id"]), {"site": SITE,
			"offer_id": source, "from": arrived_from})
	return true

static func offscreen_progress(world: SandboxWorld, npc_id: String) -> float:
	var trip: Dictionary = world.resident(npc_id).get("passenger_alight", {})
	if trip.get("status", "") != "offscreen": return -1.0
	return clampf(float(trip["handoff_progress"]) + float(world.minute - int(trip["handoff_minute"])) / OFFSCREEN_MINUTES, 0.0, 1.0)

static func handoff(world: SandboxWorld, npc_id: String, fraction: float) -> bool:
	var trip: Dictionary = world.resident(npc_id).get("passenger_alight", {})
	if trip.get("status", "") != "walking" or not is_finite(fraction) or fraction < 0.0 or fraction >= 1.0: return false
	var progress: float = snappedf(fraction, 0.000001)
	trip["status"] = "offscreen"
	trip["handoff_progress"] = progress
	trip["handoff_minute"] = world.minute
	world._record("rider_alight_handoff", npc_id, {"site": SITE, "progress": progress})
	return true

static func resume(world: SandboxWorld, npc_id: String) -> float:
	var trip: Dictionary = world.resident(npc_id).get("passenger_alight", {})
	if trip.get("status", "") != "offscreen": return -1.0
	var progress: float = offscreen_progress(world, npc_id)
	if progress >= 1.0:
		arrive(world, npc_id, Vector2.INF)
		return -1.0
	trip["status"] = "walking"
	world._record("rider_alight_resumed", npc_id, {"site": SITE, "progress": snappedf(progress, 0.000001)})
	return progress

static func arrive(world: SandboxWorld, npc_id: String, where: Vector2) -> bool:
	var trip: Dictionary = world.resident(npc_id).get("passenger_alight", {})
	if trip.get("status", "") not in ["walking", "offscreen"]: return false
	if trip.get("status", "") == "offscreen":
		if offscreen_progress(world, npc_id) < 1.0: return false
	else:
		if not where.is_finite() or where.distance_to(SandboxAlightGeometry.goal(trip)) > 4.0: return false
	trip["status"] = "arrived"
	trip["arrived"] = world.minute
	world._record("rider_alight_arrived", npc_id, {"site": SITE, "offer_id": trip["offer_id"]})
	return true

static func advance_offscreen(world: SandboxWorld) -> void:
	for npc in world.residents:
		var trip: Dictionary = npc.get("passenger_alight", {})
		if trip.get("status", "") == "offscreen" and offscreen_progress(world, str(npc["id"])) >= 1.0:
			arrive(world, str(npc["id"]), Vector2.INF)

static func valid_history(npc: Dictionary, offers: Array, events: Array, minute: int) -> bool:
	var trip: Variant = npc.get("passenger_alight", {})
	if not (trip is Dictionary): return false
	var state: String = ""
	var offer_id: String = ""
	var from: String = ""
	var started: int = -1
	var handoff_minute: int = -1
	var handoff_fraction: float = -1.0
	var arrived: int = -1
	var settled: Dictionary = {}
	for evt in events:
		if evt.get("kind", "") == "fare_settled":
			settled[str(evt.get("subject", ""))] = true
		if evt.get("subject", "") != npc.get("id", ""): continue
		var kind: String = str(evt.get("kind", ""))
		if not kind.begins_with("rider_alight_"): continue
		var detail: Dictionary = evt.get("detail", {})
		var when: int = int(evt.get("minute", -1))
		if when > minute or when < SandboxWorld.START_MINUTE or detail.get("site", "") != SITE: return false
		match kind:
			"rider_alight_started":
				if state not in ["", "arrived"]: return false
				offer_id = str(detail.get("offer_id", ""))
				from = str(detail.get("from", ""))
				if not settled.has(offer_id) or not SandboxRoads.connected(from, "clinic"): return false
				var matching: bool = false
				for offer in offers:
					if offer.get("id", "") == offer_id and offer.get("npc_id", "") == npc.get("id", "") \
							and applicable(offer) and offer.get("status", "") == "completed": matching = true
				if not matching: return false
				state = "walking"
				started = when
				handoff_minute = -1
				handoff_fraction = -1.0
				arrived = -1
			"rider_alight_handoff":
				var progress: Variant = detail.get("progress", null)
				if state != "walking" or not (progress is int or progress is float) \
						or not is_finite(float(progress)) or float(progress) < 0.0 or float(progress) >= 1.0: return false
				state = "offscreen"
				handoff_minute = when
				handoff_fraction = float(progress)
			"rider_alight_resumed":
				var resumed: Variant = detail.get("progress", null)
				var expected: float = snappedf(clampf(handoff_fraction + float(when - handoff_minute) / OFFSCREEN_MINUTES, 0.0, 1.0), 0.000001)
				if state != "offscreen" or not (resumed is int or resumed is float) \
						or not is_finite(float(resumed)) or not is_equal_approx(float(resumed), expected) or expected >= 1.0: return false
				state = "walking"
			"rider_alight_arrived":
				if state not in ["walking", "offscreen"] or detail.get("offer_id", "") != offer_id: return false
				if state == "offscreen" and handoff_fraction + float(when - handoff_minute) / OFFSCREEN_MINUTES < 1.0: return false
				state = "arrived"
				arrived = when
			_:
				return false
	if trip.is_empty(): return state == ""
	if state != str(trip.get("status", "")) or trip.get("site", "") != SITE \
			or trip.get("offer_id", "") != offer_id or trip.get("from", "") != from \
			or int(trip.get("started", -1)) != started: return false
	# Once the real entrance is reached, that resident is allowed to take
	# another job or trip later without invalidating a historical arrival.
	if state in ["walking", "offscreen"] and (npc.get("location", "") != "clinic" \
			or not str(npc.get("taxi_offer", "")).is_empty()): return false
	if handoff_minute >= 0:
		if int(trip.get("handoff_minute", -1)) != handoff_minute \
				or not is_equal_approx(float(trip.get("handoff_progress", -1.0)), handoff_fraction): return false
	if state == "arrived":
		return int(trip.get("arrived", -1)) == arrived and arrived >= started
	return arrived < 0

static func valid_presentation(world: SandboxWorld, state: Variant) -> bool:
	if not (state is Dictionary): return false
	if state.is_empty():
		for npc in world.residents:
			if npc.get("passenger_alight", {}).get("status", "") == "walking": return false
		return true
	var id: String = str(state.get("npc_id", ""))
	var npc: Dictionary = world.resident(id)
	var trip: Dictionary = npc.get("passenger_alight", {})
	if trip.get("status", "") != "walking" or world.is_travelling() or world.player_district != "clinic": return false
	var x: Variant = state.get("x", null)
	var y: Variant = state.get("y", null)
	if not (x is float or x is int) or not (y is float or y is int): return false
	var where: Vector2 = Vector2(float(x), float(y))
	if not where.is_finite(): return false
	return SandboxAlightGeometry.valid_position(trip, where)
