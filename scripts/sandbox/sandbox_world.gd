class_name SandboxWorld
extends RefCounted

# One authoritative world snapshot; services calculate/transform domain facts.
# Presentation NEVER owns NPC locations, offer status or fare settlement.
const SCHEMA_VERSION: int = 1
const STEP_MINUTES: int = 10
const START_MINUTE: int = 480

var seed: int = 1
var minute: int = START_MINUTE
var player_district: String = "docks"
var credits: int = 12
var risk: int = 0
var residents: Array[Dictionary] = []
var offers: Array[Dictionary] = []
var events: Array[Dictionary] = []
var active_offer_id: String = ""
var remaining_minutes: int = 0


func _init(world_seed: int = 1) -> void:
	seed = world_seed
	residents = SandboxPopulation.create(seed)
	SandboxDispatch.refresh(residents, offers, minute, seed)


func _record(kind: String, subject: String, detail: Dictionary = {}) -> void:
	events.append({
		"id": "event:%d" % (events.size() + 1),
		"minute": minute,
		"kind": kind,
		"subject": subject,
		"detail": detail.duplicate(true)
	})


func resident(npc_id: String) -> Dictionary:
	for npc in residents:
		if npc["id"] == npc_id:
			return npc
	return {}


func offer_by_id(offer_id: String) -> Dictionary:
	for offer in offers:
		if offer["id"] == offer_id:
			return offer
	return {}


func open_offers() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for offer in offers:
		if offer["status"] == "open":
			visible.append(offer.duplicate(true))
	return visible


func advance(minutes: int) -> bool:
	if minutes <= 0 or minutes % STEP_MINUTES != 0:
		return false
	for i in range(minutes / STEP_MINUTES):
		minute += STEP_MINUTES
		SandboxPopulation.step(residents)
		for id in SandboxDispatch.expire(residents, offers, minute):
			_record("offer_expired", id)
		if not active_offer_id.is_empty():
			remaining_minutes = maxi(0, remaining_minutes - STEP_MINUTES)
			if remaining_minutes == 0:
				_complete_active_trip()
		SandboxDispatch.refresh(residents, offers, minute, seed)
	return true


func reposition(destination: String) -> bool:
	if not active_offer_id.is_empty() or not SandboxRoads.DISTRICTS.has(destination) or destination == player_district:
		return false
	var hops: int = SandboxRoads.hops(player_district, destination)
	var move_cost: int = hops
	if hops <= 0 or credits < move_cost:
		return false
	var previous: String = player_district
	credits -= move_cost
	player_district = destination
	_record("reposition", "player", {"from": previous, "to": destination, "expense": move_cost})
	advance(hops * STEP_MINUTES)
	return true


func decline(offer_id: String) -> bool:
	var offer: Dictionary = offer_by_id(offer_id)
	if offer.is_empty() or offer["status"] != "open":
		return false
	offer["status"] = "declined"
	var npc: Dictionary = resident(str(offer["npc_id"]))
	npc["cooldown_until"] = minute + 30
	_record("offer_declined", offer_id)
	return true


func accept(offer_id: String) -> bool:
	var offer: Dictionary = offer_by_id(offer_id)
	if not active_offer_id.is_empty() or offer.is_empty() or offer["status"] != "open":
		return false
	if offer["origin"] != player_district or offer["channel"] == "official":
		return false # Illegally resident: no access to licensed ride apps.
	var npc: Dictionary = resident(str(offer["npc_id"]))
	if npc.is_empty() or int(npc["cash"]) < int(offer["fare"]) or npc["location"] != offer["origin"]:
		return false
	offer["status"] = "accepted"
	active_offer_id = offer_id
	remaining_minutes = SandboxRoads.travel_minutes(str(offer["origin"]), str(offer["destination"]))
	_record("offer_accepted", offer_id)
	return true


func _complete_active_trip() -> void:
	var offer: Dictionary = offer_by_id(active_offer_id)
	if offer.is_empty() or offer["status"] != "accepted":
		return
	var fare: int = int(offer["fare"])
	credits += fare
	player_district = str(offer["destination"])
	var npc: Dictionary = resident(str(offer["npc_id"]))
	SandboxPopulation.conclude_trip(npc, player_district, fare, minute)
	# Unlicensed work is consequential even when the passenger is satisfied.
	if offer["channel"] == "underground":
		risk += 1
	offer["status"] = "completed"
	_record("fare_settled", str(offer["id"]), {"credits": fare, "npc_id": npc["id"], "to": player_district})
	active_offer_id = ""


func snapshot() -> Dictionary:
	return {
		"version": SCHEMA_VERSION, "seed": seed, "minute": minute,
		"player_district": player_district, "credits": credits, "risk": risk,
		"residents": residents.duplicate(true), "offers": offers.duplicate(true),
		"events": events.duplicate(true), "active_offer_id": active_offer_id,
		"remaining_minutes": remaining_minutes
	}


func restore_snapshot(value: Dictionary) -> bool:
	if int(value.get("version", -1)) != SCHEMA_VERSION:
		return false
	if not (value.get("residents") is Array) or not (value.get("offers") is Array) or not (value.get("events") is Array):
		return false
	var district: String = str(value.get("player_district", ""))
	var remaining: int = int(value.get("remaining_minutes", -1))
	var active: String = str(value.get("active_offer_id", ""))
	if not SandboxRoads.DISTRICTS.has(district) or remaining < 0 or int(value.get("minute", -1)) < START_MINUTE:
		return false
	if int(value.get("credits", -1)) < 0 or int(value.get("risk", -1)) < 0:
		return false
	if value["residents"].size() != 9:
		return false
	var offered: Dictionary = {}
	var actual_active: int = 0
	for offer in value["offers"]:
		if not (offer is Dictionary) or not ["open", "expired", "declined", "accepted", "completed"].has(offer.get("status")):
			return false
		var id: String = str(offer.get("id", ""))
		if id.is_empty() or offered.has(id):
			return false
		offered[id] = true
		if offer["status"] == "accepted":
			actual_active += 1
			if id != active:
				return false
	if actual_active != (1 if not active.is_empty() else 0):
		return false
	seed = int(value.get("seed", 1))
	minute = int(value["minute"])
	player_district = district
	credits = int(value["credits"])
	risk = int(value["risk"])
	residents.clear()
	for npc in value["residents"]:
		residents.append((npc as Dictionary).duplicate(true))
	offers.clear()
	for offer in value["offers"]:
		offers.append((offer as Dictionary).duplicate(true))
	events.clear()
	for event in value["events"]:
		events.append((event as Dictionary).duplicate(true))
	active_offer_id = active
	remaining_minutes = remaining
	return true
