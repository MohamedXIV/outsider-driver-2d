class_name SandboxWorld
extends RefCounted

# One authoritative world snapshot; services calculate/transform domain facts.
# Presentation NEVER owns NPC locations, offer status or fare settlement.
const SCHEMA_VERSION: int = 8
const STEP_MINUTES: int = 10
const START_MINUTE: int = 480

var seed: int = 1
var minute: int = START_MINUTE
var player_district: String = "docks"
var credits: int = 12
var risk: int = 0
var starter_device: String = ""
var knowledge: Array[String] = []
var residents: Array[Dictionary] = []
var offers: Array[Dictionary] = []
var events: Array[Dictionary] = []
var active_offer_id: String = ""
var remaining_minutes: int = 0
var route_nodes: Array[String] = []
var route_segment: int = 0
var route_edge_elapsed: int = 0
var pending_route_nodes: Array[String] = []
var rider_route_request: Dictionary = {}
var meetings: Array[Dictionary] = []


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


func select_starter_device(device: String) -> bool:
	if not starter_device.is_empty() or not SandboxKnowledge.DEVICES.has(device) \
			or not active_offer_id.is_empty() or meeting_in_progress():
		return false
	starter_device = device
	_grant_fact(str(SandboxKnowledge.FIRST_FACT[device]), "starter:%s" % device)
	_record("starter_selected", "player", {"device": device})
	return true


func knows(fact: String) -> bool:
	return SandboxKnowledge.has_fact(knowledge, fact)


func _grant_fact(fact: String, source: String) -> bool:
	if knowledge.has(fact):
		return false
	knowledge.append(fact)
	_record("knowledge_learned", "player", {"fact": fact, "source": source})
	return true


func observe_route_language(offer_id: String) -> bool:
	# Observing a real live response unlocks a single reusable *route marker*.
	# Merely owning a translator is not equivalent to already knowing it.
	var offer: Dictionary = offer_by_id(offer_id)
	if offer.is_empty() or offer.get("status") != "open" \
			or offer.get("origin") != player_district or not active_offer_id.is_empty():
		return false
	var npc: Dictionary = resident(str(offer["npc_id"]))
	if npc.is_empty() or not SandboxKnowledge.can_observe_route(
			starter_device, str(npc.get("language", "")), SandboxKnowledge.ROUTE_MARKER):
		return false
	return _grant_fact(SandboxKnowledge.ROUTE_MARKER, "offer:%s" % offer_id)


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
	if meeting_in_progress() or minutes <= 0 or minutes % STEP_MINUTES != 0:
		return false
	for i in range(minutes / STEP_MINUTES):
		minute += STEP_MINUTES
		_record_changes(SandboxPopulation.step(residents, minute))
		_record_changes(SandboxAutonomy.finish_arrivals(residents, minute))
		_apply_peer_contact(SandboxSocial.pick(residents, minute))
		SandboxMeetings.on_tick(self)
		var expired: Array[String] = SandboxDispatch.expire(residents, offers, minute)
		for id in expired:
			_record("offer_expired", id)
		_record_changes(SandboxAutonomy.begin_expired_trips(residents, offers, expired, minute, seed))
		if not active_offer_id.is_empty():
			_step_player_route()
		SandboxDispatch.refresh(residents, offers, minute, seed)
	return true


# Commit a bounded contact only if two actual residents are co-present and
# mutually intelligible at this tick. Event ID is the fact's provenance.
func _apply_peer_contact(intent: Dictionary) -> void:
	if intent.is_empty():
		return
	var actor: Dictionary = resident(str(intent["actor"]))
	var recipient: Dictionary = resident(str(intent["recipient"]))
	if actor.is_empty() or recipient.is_empty() or actor["location"] != recipient["location"] \
			or actor["language"] != recipient["language"] \
			or actor["activity"] == "travelling" or recipient["activity"] == "travelling":
		return
	var day: int = (minute - START_MINUTE) / 1440
	if int(actor["last_peer_day"]) >= day or int(recipient["last_peer_day"]) >= day:
		return
	var credits_shared: int = 2 if int(actor["cash"]) >= 35 and int(recipient["need"]) >= 53 else 0
	actor["cash"] = int(actor["cash"]) - credits_shared
	recipient["cash"] = int(recipient["cash"]) + credits_shared
	actor["last_peer_day"] = day
	recipient["last_peer_day"] = day
	var a_contacts: Dictionary = actor["contacts"]
	var r_contacts: Dictionary = recipient["contacts"]
	a_contacts[recipient["id"]] = int(a_contacts.get(recipient["id"], 0)) + 1
	r_contacts[actor["id"]] = int(r_contacts.get(actor["id"], 0)) + 1
	var fact: String = "residence:%s" % str(actor["id"])
	_record("npc_peer_contact", str(actor["id"]), {
		"recipient": str(recipient["id"]), "district": actor["location"],
		"language": actor["language"], "fact": fact, "value": actor["home"],
		"credits_shared": credits_shared, "affinity": intent["affinity"],
		"rivalry": intent["rivalry"]
	})
	recipient["peer_knowledge"][fact] = {
		"value": str(actor["home"]), "source": str(events.back()["id"]),
		"speaker": str(actor["id"])
	}


func _record_changes(changes: Array[Dictionary]) -> void:
	for change in changes:
		_record(str(change["kind"]), str(change["subject"]), change["detail"])


func reposition(destination: String) -> bool:
	if meeting_in_progress() or not active_offer_id.is_empty() or not SandboxRoads.DISTRICTS.has(destination) or destination == player_district:
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
	if meeting_in_progress() or offer.is_empty() or offer["status"] != "open":
		return false
	offer["status"] = "declined"
	var npc: Dictionary = resident(str(offer["npc_id"]))
	npc["cooldown_until"] = minute + 30
	_record("offer_declined", offer_id)
	# Only a locally witnessed decline creates a driver memory.
	if npc["location"] == player_district and offer["origin"] == player_district:
		SandboxDriverMemory.remember(npc, SandboxDriverMemory.REFUSED,
			offer_id, str(events.back()["id"]), minute)
	return true


func accept(offer_id: String, waypoint: String = "") -> bool:
	var offer: Dictionary = offer_by_id(offer_id)
	if meeting_in_progress() or not active_offer_id.is_empty() or offer.is_empty() or offer["status"] != "open":
		return false
	if offer["origin"] != player_district or offer["channel"] == "official":
		return false # Illegally resident: no access to licensed ride apps.
	var npc: Dictionary = resident(str(offer["npc_id"]))
	if npc.is_empty() or int(npc["cash"]) < int(offer["fare"]) or npc["location"] != offer["origin"]:
		return false
	var route: Array[String] = SandboxRoads.path(str(offer["origin"]), str(offer["destination"]), waypoint)
	if not SandboxRoads.valid_path(route) or credits < SandboxRoads.path_expense(route):
		return false
	offer["status"] = "accepted"
	active_offer_id = offer_id
	route_nodes = route.duplicate()
	route_segment = 0
	route_edge_elapsed = 0
	remaining_minutes = SandboxRoads.minutes_left(route_nodes, route_segment, route_edge_elapsed)
	pending_route_nodes.clear()
	rider_route_request = SandboxRiderRoutes.request(npc, offer, route)
	_record("offer_accepted", offer_id, {
		"nodes": route.duplicate(), "minutes": remaining_minutes,
		"anticipated_expense": SandboxRoads.path_expense(route)
	})
	return true


# Queue a full remaining suffix, applied only after the current physical edge.
func queue_reroute(via: String = "") -> bool:
	if active_offer_id.is_empty() or route_nodes.size() < 3:
		return false
	var junction: String = route_nodes[route_segment + 1]
	var destination: String = str(offer_by_id(active_offer_id)["destination"])
	if junction == destination:
		return false
	var proposed: Array[String] = SandboxRoads.path(junction, destination, via)
	if not SandboxRoads.valid_path(proposed):
		return false
	var previous: Array[String] = []
	for i in range(route_segment + 1, route_nodes.size()):
		previous.append(route_nodes[i])
	if proposed == previous or proposed == pending_route_nodes:
		return false
	var edge_cost: int = SandboxRoads.edge_expense(route_nodes[route_segment], junction)
	if credits < edge_cost + SandboxRoads.path_expense(proposed):
		return false
	pending_route_nodes = proposed.duplicate()
	remaining_minutes = _route_time_left()
	_record("route_change_queued", active_offer_id, {
		"junction": junction, "via": via, "new_nodes": proposed.duplicate(),
		"requested_by": "player"
	})
	return true


func respond_rider_route(agree: bool) -> bool:
	if active_offer_id.is_empty() or rider_route_request.get("status", "") != "pending":
		return false
	var npc: Dictionary = resident(str(offer_by_id(active_offer_id)["npc_id"]))
	if npc.is_empty():
		return false
	if agree and not queue_reroute(str(rider_route_request["via"])):
		return false
	rider_route_request["status"] = "accepted" if agree else "declined"
	var trust_delta: int = 1 if agree else -1
	npc["trust"] = int(npc["trust"]) + trust_delta
	_record("rider_route_answered", active_offer_id, {
		"npc_id": npc["id"], "via": rider_route_request["via"],
		"answer": rider_route_request["status"], "trust_delta": trust_delta
	})
	return true


func _route_time_left() -> int:
	if pending_route_nodes.is_empty():
		return SandboxRoads.minutes_left(route_nodes, route_segment, route_edge_elapsed)
	return SandboxRoads.edge_minutes(route_nodes[route_segment], route_nodes[route_segment + 1]) \
			- route_edge_elapsed + SandboxRoads.path_minutes(pending_route_nodes)


func _step_player_route() -> void:
	# Advance the same authoritative physical route used by the presenter.
	if route_nodes.size() < 2 or route_segment >= route_nodes.size() - 1:
		return
	var from: String = route_nodes[route_segment]
	var to: String = route_nodes[route_segment + 1]
	route_edge_elapsed += STEP_MINUTES
	if route_edge_elapsed >= SandboxRoads.edge_minutes(from, to):
		route_segment += 1
		route_edge_elapsed = 0
		player_district = to
		var expense: int = SandboxRoads.edge_expense(from, to)
		var exposure: int = SandboxRoads.edge_exposure(from, to)
		credits -= expense
		risk += exposure
		_record("route_segment_completed", active_offer_id, {
			"from": from, "to": to, "expense": expense,
			"exposure": exposure
		})
		if route_segment == route_nodes.size() - 1:
			remaining_minutes = 0
			_complete_active_trip()
			return
		if not pending_route_nodes.is_empty():
			var old_remaining: Array[String] = []
			for i in range(route_segment, route_nodes.size()):
				old_remaining.append(route_nodes[i])
			route_nodes = pending_route_nodes.duplicate()
			pending_route_nodes.clear()
			route_segment = 0
			_record("route_rerouted", active_offer_id, {
				"junction": to, "old_remaining": old_remaining,
				"new_remaining": route_nodes.duplicate()
			})
	remaining_minutes = _route_time_left()


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
	SandboxDriverMemory.remember(npc, SandboxDriverMemory.COMPLETED,
		str(offer["id"]), str(events.back()["id"]), minute)
	# The source remains the actual fare settlement, not a fabricated NPC quest.
	var fare_source: String = str(events.back()["id"])
	SandboxMeetings.maybe_invite(self, npc, fare_source)
	active_offer_id = ""
	route_nodes.clear()
	route_segment = 0
	route_edge_elapsed = 0
	pending_route_nodes.clear()
	rider_route_request.clear()


func snapshot() -> Dictionary:
	return {
		"version": SCHEMA_VERSION, "seed": seed, "minute": minute,
		"player_district": player_district, "credits": credits, "risk": risk,
		"starter_device": starter_device, "knowledge": knowledge.duplicate(),
		"residents": residents.duplicate(true), "offers": offers.duplicate(true),
		"events": events.duplicate(true), "active_offer_id": active_offer_id,
		"remaining_minutes": remaining_minutes, "route_nodes": route_nodes.duplicate(),
		"route_segment": route_segment, "route_edge_elapsed": route_edge_elapsed,
		"pending_route_nodes": pending_route_nodes.duplicate(),
		"rider_route_request": rider_route_request.duplicate(true),
		"meetings": meetings.duplicate(true)
	}


func restore_snapshot(value: Dictionary) -> bool:
	if int(value.get("version", -1)) != SCHEMA_VERSION:
		return false
	if not (value.get("residents") is Array) or not (value.get("offers") is Array) or not (value.get("events") is Array) \
			or not (value.get("meetings") is Array):
		return false
	var district: String = str(value.get("player_district", ""))
	var remaining: int = int(value.get("remaining_minutes", -1))
	var active: String = str(value.get("active_offer_id", ""))
	if not SandboxRoads.DISTRICTS.has(district) or remaining < 0 or int(value.get("minute", -1)) < START_MINUTE:
		return false
	if int(value.get("credits", -1)) < 0 or int(value.get("risk", -1)) < 0:
		return false
	var device: String = str(value.get("starter_device", ""))
	if not (device.is_empty() or SandboxKnowledge.DEVICES.has(device)) \
			or not (value.get("knowledge") is Array):
		return false
	var restored_knowledge: Array[String] = []
	for item in value["knowledge"]:
		if not (item is String) or restored_knowledge.has(item):
			return false
		restored_knowledge.append(item)
	if device.is_empty() and not restored_knowledge.is_empty():
		return false
	if not device.is_empty() and not restored_knowledge.has(str(SandboxKnowledge.FIRST_FACT[device])):
		return false
	if restored_knowledge.has(SandboxKnowledge.ROUTE_MARKER) and device != "translator":
		return false
	if value["residents"].size() != 9:
		return false
	var resident_ids: Dictionary = {}
	for npc in value["residents"]:
		if not (npc is Dictionary) or not SandboxRoads.DISTRICTS.has(npc.get("location", "")) \
				or not SandboxRoads.DISTRICTS.has(npc.get("home", "")) \
				or not SandboxRoads.DISTRICTS.has(npc.get("workplace", "")):
			return false
		var npc_id: String = str(npc.get("id", ""))
		if npc_id.is_empty() or resident_ids.has(npc_id):
			return false
		resident_ids[npc_id] = true
		if not ["available", "resting", "working", "travelling"].has(npc.get("activity")):
			return false
		if not SandboxDriverMemory.valid_history(npc, value["offers"], value["events"],
				int(value["minute"])):
			return false
		if not ["kind:a", "kind:b", "kind:c", "kind:d"].has(npc.get("species")) \
				or not ["harbor", "exchange", "newcomer"].has(npc.get("community")) \
				or not (npc.get("peer_knowledge") is Dictionary) \
				or not (npc.get("contacts") is Dictionary) \
				or int(npc.get("last_peer_day", -2)) < -1:
			return false
		var travel_until: int = int(npc.get("transit_until", -1))
		if travel_until < 0:
			return false
		if travel_until > 0:
			if travel_until <= int(value["minute"]) \
					or not SandboxRoads.DISTRICTS.has(npc.get("transit_to", "")) \
					or str(npc.get("transit_from_offer", "")).is_empty() \
					or not ["walking", "shuttle"].has(npc.get("transit_method", "")) \
					or npc.get("activity") != "travelling":
				return false
		elif not str(npc.get("transit_to", "")).is_empty() \
				or not str(npc.get("transit_from_offer", "")).is_empty() \
				or not str(npc.get("transit_method", "")).is_empty():
			return false
	# A learned fact needs a genuine source in the same world event ledger.
		for fact in npc["peer_knowledge"]:
			var claim: Variant = npc["peer_knowledge"][fact]
			if not (claim is Dictionary) or not str(fact).begins_with("residence:") \
					or not (claim.get("value") is String) or not (claim.get("source") is String):
				return false
			var found_source: bool = false
			for evt in value["events"]:
				if evt.get("kind", "") == "npc_peer_contact" \
						and evt.get("id") == claim["source"] \
						and evt.get("detail", {}).get("recipient") == npc["id"] \
						and evt.get("detail", {}).get("fact") == fact \
						and evt.get("detail", {}).get("value") == claim["value"]:
					found_source = true
					break
			if not found_source:
				return false
	if not SandboxMeetings.valid_history(value["meetings"], value["residents"],
			value["offers"], value["events"], int(value["minute"])):
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
	if not (value.get("route_nodes") is Array) or not (value.get("pending_route_nodes") is Array) \
			or not (value.get("rider_route_request") is Dictionary):
		return false
	var route: Array[String] = []
	for node in value["route_nodes"]:
		if not (node is String):
			return false
		route.append(node)
	var pending: Array[String] = []
	for node in value["pending_route_nodes"]:
		if not (node is String):
			return false
		pending.append(node)
	var request: Dictionary = value["rider_route_request"]
	if not request.is_empty():
		if not ["pending", "accepted", "declined"].has(request.get("status")) \
				or not (request.get("via") is String) \
				or not SandboxRoads.DISTRICTS.has(request.get("via")) \
				or not ["faster", "lower_exposure"].has(request.get("reason")):
			return false
	var segment: int = int(value.get("route_segment", -1))
	var elapsed: int = int(value.get("route_edge_elapsed", -1))
	if active.is_empty():
		if not route.is_empty() or not pending.is_empty() or not request.is_empty() \
				or segment != 0 or elapsed != 0 or remaining != 0:
			return false
	else:
		if not SandboxRoads.valid_path(route):
			return false
		var accepted_offer: Dictionary = {}
		for offer in value["offers"]:
			if offer["id"] == active:
				accepted_offer = offer
				break
		if accepted_offer.is_empty() or route.back() != accepted_offer["destination"] \
				or segment < 0 or segment >= route.size() - 1 \
				or route[segment] != district:
			return false
		if not pending.is_empty():
			if route[segment + 1] == accepted_offer["destination"] \
					or not SandboxRoads.valid_path(pending) \
					or pending[0] != route[segment + 1] \
					or pending.back() != accepted_offer["destination"] \
					or remaining != SandboxRoads.edge_minutes(route[segment], route[segment + 1]) \
							- elapsed + SandboxRoads.path_minutes(pending):
				return false
		elif remaining != SandboxRoads.minutes_left(route, segment, elapsed):
			return false
	seed = int(value.get("seed", 1))
	minute = int(value["minute"])
	player_district = district
	credits = int(value["credits"])
	risk = int(value["risk"])
	starter_device = device
	knowledge = restored_knowledge.duplicate()
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
	route_nodes = route.duplicate()
	route_segment = segment
	route_edge_elapsed = elapsed
	pending_route_nodes = pending.duplicate()
	rider_route_request = request.duplicate(true)
	meetings.clear()
	for meeting in value["meetings"]:
		meetings.append((meeting as Dictionary).duplicate(true))
	return true


# Off-duty social interaction is not a second scene/world authority.
func meeting_by_id(meeting_id: String) -> Dictionary:
	return SandboxMeetings.find(self, meeting_id)


func accept_meeting(meeting_id: String) -> bool:
	return SandboxMeetings.accept(self, meeting_id)


func decline_meeting(meeting_id: String) -> bool:
	return SandboxMeetings.decline(self, meeting_id)


func start_meeting(meeting_id: String) -> bool:
	return SandboxMeetings.start(self, meeting_id)


func finish_meeting(meeting_id: String, choice: String) -> bool:
	return SandboxMeetings.finish(self, meeting_id, choice)


func meeting_in_progress() -> bool:
	for meeting in meetings:
		if meeting.get("status") == "in_progress":
			return true
	return false
