class_name SandboxLocalPedestrianTrip
extends RefCounted

# A genuine resident's local errand belongs to SandboxWorld. Godot agents own
# visible movement; the world validates and records intent and arrival once.
# This bounded experiment does not change city-wide taxi offer/route semantics.
const PATCHWORKS_PARTS: String = "patchworks:parts_counter"

static func candidate(world: SandboxWorld) -> String:
	# Continue an existing errand before picking another resident. No scripted
	# first passenger, duplicate actor, or synthetic extra simulation person.
	for npc in world.residents:
		var active: Dictionary = npc.get("local_pedestrian_trip", {})
		if active.get("site", "") == PATCHWORKS_PARTS and active.get("status", "") in ["walking", "arrived"]:
			return str(npc["id"])
	for npc in world.residents:
		if str(npc.get("location", "")) != "garage" or str(npc.get("activity", "")) != "available":
			continue
		if not ["supplies", "work"].has(str(npc.get("purpose", ""))) or int(npc.get("need", 0)) < 30:
			continue
		if int(npc.get("cooldown_until", 0)) > world.minute or not str(npc.get("taxi_offer", "")).is_empty():
			continue
		var pending: bool = false
		for offer in world.offers:
			if offer.get("npc_id", "") == npc.get("id", "") and offer.get("status", "") in ["open", "accepted"]:
				pending = true
				break
		if not pending:
			return str(npc["id"])
	return ""

static func begin(world: SandboxWorld, npc_id: String, site: String) -> bool:
	if site != PATCHWORKS_PARTS:
		return false
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty() or str(npc.get("location", "")) != "garage" \
			or npc.get("activity", "") != "available":
		return false
	if not npc.get("local_pedestrian_trip", {}).is_empty():
		return false
	if not ["supplies", "work"].has(str(npc.get("purpose", ""))):
		return false
	for offer in world.offers:
		if offer.get("npc_id", "") == npc_id and offer.get("status", "") in ["open", "accepted"]:
			return false
	# A nearby service errand does not erase the resident's independent long
	# distance need or authorize the player to accept a licensed taxi fare.
	npc["local_pedestrian_trip"] = {"site": site, "status": "walking", "started": world.minute}
	world._record("local_pedestrian_departed", npc_id, {"from": "garage", "site": site})
	return true

static func arrive(world: SandboxWorld, npc_id: String, site: String) -> bool:
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty():
		return false
	var trip: Dictionary = npc.get("local_pedestrian_trip", {})
	if trip.get("site", "") != site or trip.get("status", "") != "walking":
		return false
	# This counter is a local site inside the garage's coarse world location.
	# It does not teleport an NPC between dispatch/region graph nodes.
	trip["status"] = "arrived"
	trip["arrived"] = world.minute
	npc["local_pedestrian_trip"] = trip
	world._record("local_pedestrian_arrived", npc_id, {"site": site})
	return true

static func valid_history(npc: Dictionary, events: Array, minute: int) -> bool:
	var trip: Variant = npc.get("local_pedestrian_trip", {})
	if not (trip is Dictionary):
		return false
	if trip.is_empty():
		return true
	if trip.get("site", "") != PATCHWORKS_PARTS or not ["walking", "arrived"].has(trip.get("status", "")):
		return false
	var started: int = int(trip.get("started", -1))
	if started < SandboxWorld.START_MINUTE or started > minute:
		return false
	if trip.get("status") == "walking" and (npc.get("location", "") != "garage" or \
			not str(npc.get("taxi_offer", "")).is_empty()):
		return false
	var departures: int = 0
	var arrivals: int = 0
	for event in events:
		if event.get("subject", "") != npc.get("id", ""):
			continue
		if event.get("kind", "") == "local_pedestrian_departed":
			if event.get("detail", {}).get("site", "") != PATCHWORKS_PARTS \
					or event.get("detail", {}).get("from", "") != "garage" \
					or int(event.get("minute", -1)) != started:
				return false
			departures += 1
		elif event.get("kind", "") == "local_pedestrian_arrived":
			if event.get("detail", {}).get("site", "") != PATCHWORKS_PARTS:
				return false
			arrivals += 1
	if departures != 1:
		return false
	if trip.get("status") == "walking":
		return arrivals == 0
	var arrived: int = int(trip.get("arrived", -1))
	if arrived < started or arrived > minute or arrivals != 1:
		return false
	for event in events:
		if event.get("subject", "") == npc.get("id", "") and event.get("kind", "") == "local_pedestrian_arrived" \
				and int(event.get("minute", -1)) == arrived:
			return true
	return false
