class_name SandboxWorld
extends RefCounted

# One authoritative world snapshot; services calculate/transform domain facts.
# Presentation NEVER owns NPC locations, offer status or fare settlement.
const SCHEMA_VERSION: int = 12
const STEP_MINUTES: int = 1
const START_MINUTE: int = 480

var seed: int = 1
var minute: int = START_MINUTE
var player_district: String = "garage"
var credits: int = 12
var risk: int = 0
var starter_device: String = ""
var knowledge: Array[String] = []
var modules_owned: Array[String] = ["trade"]
var modules_installed: Array[String] = ["trade"]
var market_stock: Dictionary = {"local": 1, "cant": 1}
var common_requests: Dictionary = {}
var ar_owned: bool = false
var ar_equipped: bool = false
var residents: Array[Dictionary] = []
var offers: Array[Dictionary] = []
var events: Array[Dictionary] = []
var active_offer_id: String = ""
var travel_destination: String = ""
var engaged_offer_id: String = ""
var remaining_minutes: int = 0
var route_nodes: Array[String] = []
var route_segment: int = 0
var route_edge_elapsed: int = 0
var pending_route_nodes: Array[String] = []
var rider_route_request: Dictionary = {}
# One world-owned yield latch. World time continues while driving position
# and fare settlement wait for the physical local crossing to clear.
var route_hold_id: String = ""
var meetings: Array[Dictionary] = []
var vehicle_execution: Dictionary={}
var vehicle_parking: Dictionary={}
var vehicle_junctions: Dictionary={}
var vehicle_executor: Callable=Callable()
var vehicle_fraction: float=0.0


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
			or is_travelling() or meeting_in_progress():
		return false
	starter_device = device
	if device == "module:local":
		modules_owned.append("local")
		modules_installed.append("local")
		_record("language_module_installed", "local", {"source": "starter", "price": 0})
	else:
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


# Vendor exists at the market, is available only in trading hours, and has
# finite world-owned physical stock. No remote purchase or silent installation.
func buy_language_module(language: String) -> bool:
	if player_district != "market" or not SandboxKnowledge.market_open(minute) \
			or is_travelling() or meeting_in_progress() \
			or not SandboxKnowledge.MODULE_PRICES.has(language) \
			or modules_owned.has(language) or int(market_stock.get(language, 0)) <= 0:
		return false
	var price: int = int(SandboxKnowledge.MODULE_PRICES[language])
	if credits < price:
		return false
	credits -= price
	market_stock[language] = int(market_stock[language]) - 1
	modules_owned.append(language)
	_record("market_module_purchased", language, {
		"vendor": SandboxKnowledge.MARKET_VENDOR, "district": "market", "price": price
	})
	return true


# Optional Market eyewear. The device adds presentation only, not knowledge,
# translation, route access or an additional simulation service.
const AR_PRICE: int = 5
const AR_VENDOR: String = "vendor:market:optics"


func buy_ar() -> bool:
	if ar_owned or player_district != "market" or not SandboxKnowledge.market_open(minute) \
			or is_travelling() or meeting_in_progress() or credits < AR_PRICE:
		return false
	credits -= AR_PRICE
	ar_owned = true
	_record("ar_purchased", "player", {"vendor": AR_VENDOR, "district": "market", "price": AR_PRICE})
	return true


func set_ar_equipped(equipped: bool) -> bool:
	if not ar_owned or ar_equipped == equipped:
		return false
	ar_equipped = equipped
	_record("ar_equipped" if equipped else "ar_removed", "player", {"equipped": equipped})
	return true


# A rumor becomes player-heard only after this explicit, comprehensible,
# co-present conversation. NPC private peer_knowledge is never a player hint.
func rumor_candidate(offer_id: String) -> Dictionary:
	var offer: Dictionary = offer_by_id(offer_id)
	if offer.is_empty() or offer.get("status") != "open" \
			or offer.get("origin") != player_district or is_travelling() \
			or meeting_in_progress():
		return {}
	var npc: Dictionary = resident(str(offer.get("npc_id", "")))
	if npc.is_empty() or npc.get("location") != player_district \
			or not (modules_installed.has(str(npc.get("language", ""))) \
					or common_requests.get(offer_id, false)):
		return {}
	for fact in npc["peer_knowledge"]:
		var claim: Dictionary = npc["peer_knowledge"][fact]
		if not str(fact).begins_with("residence:") or not SandboxRoads.DISTRICTS.has(claim.get("value", "")):
			continue
		var verified_source: bool = false
		for event in events:
			if event.get("id") == claim.get("source") and event.get("kind") == "npc_peer_contact" \
					and event.get("detail", {}).get("recipient") == npc["id"] \
					and event.get("detail", {}).get("fact") == fact \
					and event.get("detail", {}).get("value") == claim["value"]:
				verified_source = true
				break
		if not verified_source:
			continue
		var already_heard: bool = false
		for event in events:
			if event.get("kind") == "player_rumor_heard" \
					and event.get("subject") == offer_id and event.get("detail", {}).get("fact") == fact:
				already_heard = true
				break
		if not already_heard:
			return {"speaker": str(npc["id"]), "fact": str(fact),
				"value": str(claim["value"]), "claim_source": str(claim["source"])}
	return {}


func hear_rumor(offer_id: String) -> bool:
	var candidate: Dictionary = rumor_candidate(offer_id)
	if candidate.is_empty():
		return false
	_record("player_rumor_heard", offer_id, candidate)
	return true


func install_language_module(language: String) -> bool:
	if not modules_owned.has(language) or modules_installed.has(language) \
			or is_travelling() or meeting_in_progress():
		return false
	modules_installed.append(language)
	_record("language_module_installed", language, {"source": "owned_inventory", "price": 0})
	return true


# Requested language switch is a world-owned, once-per-live-offer social act.
func request_common(offer_id: String) -> bool:
	var offer: Dictionary = offer_by_id(offer_id)
	if offer.is_empty() or common_requests.has(offer_id) or offer.get("status") != "open" \
			or offer.get("origin") != player_district or is_travelling() \
			or meeting_in_progress():
		return false
	var npc: Dictionary = resident(str(offer.get("npc_id", "")))
	if npc.is_empty() or npc.get("location") != player_district \
			or npc.get("language") == "trade":
		return false
	var agreed: bool = SandboxKnowledge.can_switch_to_common(npc)
	common_requests[offer_id] = agreed
	_record("common_language_requested", offer_id, {
		"speaker": str(npc["id"]), "accepted": agreed,
		"has_ability": bool(npc["speaks_common"]),
		"willing": bool(npc["will_use_common"])
	})
	return true


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
	return _advance_minutes(minutes,false)


# The real-time adapter has already supplied the elapsed physical seconds.
# Ordinary advance() remains a complete canonical time-skip operation.
func advance_elapsed(minutes: int) -> bool:
	return _advance_minutes(minutes,true)


func _advance_minutes(minutes: int, physical_elapsed: bool) -> bool:
	if meeting_in_progress() or minutes <= 0 or minutes % STEP_MINUTES != 0:
		return false
	for i in range(minutes / STEP_MINUTES):
		if not physical_elapsed and vehicle_executor.is_valid(): vehicle_executor.call(1.0)
		var execution_ready: bool=SandboxVehicleExecution.before_tick(self)
		minute += STEP_MINUTES
		for npc in residents:
			if npc.get("transit_method","")=="shuttle" \
					and npc.get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID:
				npc["transit_pause_minutes"]=int(npc.get("transit_pause_minutes",0))+1
				npc["transit_until"]=int(npc["transit_until"])+1
		SandboxLocalPedestrianTrip.advance_offscreen(self)
		SandboxPassengerAlight.advance_offscreen(self)
		if minute % 10 == 0:
			_record_changes(SandboxPopulation.step(residents, minute))
		_record_changes(SandboxAutonomy.finish_arrivals(residents, minute))
		_apply_peer_contact(SandboxSocial.pick(residents, minute))
		SandboxMeetings.on_tick(self)
		var expired: Array[String] = SandboxDispatch.expire(residents, offers, minute, engaged_offer_id)
		for id in expired:
			_record("offer_expired", id)
		_record_changes(SandboxAutonomy.begin_expired_trips(residents, offers, expired, minute, seed))
		if is_travelling() and route_hold_id.is_empty() and execution_ready:
			_step_player_route()
		SandboxDispatch.refresh(residents, offers, minute, seed)
		SandboxVehicleExecution.prune(self)
		SandboxVehicleJunctions.release_cleared(self)
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


func is_travelling() -> bool:
	return route_nodes.size() >= 2


func player_position(fraction: float = 0.0) -> Vector3:
	if not is_travelling():
		var parked: Vector2=SandboxVehicleParking.screen(self,player_district)
		if parked.is_finite(): return SandboxIsoPresentation.unproject(parked,SandboxRoads.map_position(player_district).y)
		return SandboxRoads.map_position(player_district)
	if vehicle_execution.has("player"):
		return SandboxVehicleExecution.world_point(SandboxVehicleExecution.trip(self,"player"),SandboxVehicleExecution.progress(self,"player",fraction),SandboxVehicleExecution.screen(self,"player",fraction))
	# Visual interpolation must not drive the taxi through a held zebra.
	if not route_hold_id.is_empty(): fraction = 0.0
	return SandboxRoads.sample_edge(route_nodes[route_segment], route_nodes[route_segment+1],
		(float(route_edge_elapsed)+clampf(fraction,0,1))/float(SandboxRoads.edge_minutes(route_nodes[route_segment],route_nodes[route_segment+1])))


func npc_position(npc: Dictionary, fraction: float = 0.0) -> Vector3:
	if not str(npc.get("taxi_offer", "")).is_empty() and npc["taxi_offer"]==active_offer_id:
		return player_position(fraction)
	if int(npc.get("transit_until",0))>0:
		if vehicle_execution.has(str(npc["id"])):
			return SandboxVehicleExecution.world_point(SandboxVehicleExecution.trip(self,str(npc["id"])),SandboxVehicleExecution.progress(self,str(npc["id"]),fraction),SandboxVehicleExecution.screen(self,str(npc["id"]),fraction))
		var nodes: Array[String] = []
		for node in npc.get("transit_nodes",[]): nodes.append(str(node))
		return SandboxRoads.position_on_path(nodes,maxf(0.0,float(minute-int(npc.get("transit_started",minute))
				-int(npc.get("transit_pause_minutes",0)))+
				(0.0 if not str(npc.get("transit_hold_crossing","")).is_empty() else fraction)),
			float(int(npc["transit_until"])-int(npc["transit_started"])
				-int(npc.get("transit_pause_minutes",0))))
	return SandboxRoads.map_position(str(npc["location"]))


func engage_offer(id: String) -> bool:
	var offer: Dictionary = offer_by_id(id)
	if is_travelling() or offer.get("status", "")!="open" or offer.get("origin", "")!=player_district: return false
	engaged_offer_id = id
	return true


func reposition(destination: String, via: String = "", waypoints: Array[String] = []) -> bool:
	if meeting_in_progress() or is_travelling() or not SandboxRoads.DISTRICTS.has(destination) or destination==player_district:
		return false
	var nodes: Array[String] = SandboxRoads.path(player_district,destination,via) if waypoints.is_empty() else SandboxRoads.path_via(player_district,destination,waypoints)
	var move_cost: int = maxi(1,ceili(SandboxRoads.path_metres(nodes)/5000.0))
	if not SandboxRoads.valid_path(nodes) or credits < move_cost+SandboxRoads.path_expense(nodes): return false
	credits -= move_cost
	engaged_offer_id = ""
	travel_destination = destination
	route_nodes = nodes
	route_segment = 0
	route_edge_elapsed = 0
	remaining_minutes = SandboxRoads.path_minutes(nodes)
	_record("reposition", "player", {"from":player_district,"to":destination,"expense":move_cost,"nodes":nodes.duplicate()})
	return true


func decline(offer_id: String) -> bool:
	var offer: Dictionary = offer_by_id(offer_id)
	if meeting_in_progress() or offer.is_empty() or offer["status"] != "open":
		return false
	offer["status"] = "declined"
	if engaged_offer_id==offer_id: engaged_offer_id=""
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
	if meeting_in_progress() or is_travelling() or offer.is_empty() or offer["status"] != "open":
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
	engaged_offer_id = ""
	npc["taxi_offer"] = offer_id
	npc["activity"] = "travelling"
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


# World-owned municipal shuttle yielding; only one authored zebra.
# The same resident retains transit nodes, fare and route provenance.
func begin_shuttle_crossing_yield(npc_id: String) -> bool:
	var npc: Dictionary=resident(npc_id)
	if npc.is_empty() or not str(npc.get("transit_hold_crossing","")).is_empty() \
			or not SandboxWorldTraffic.approaching_zebra(self,npc):
		return false
	npc["transit_hold_crossing"]=SandboxStreetRouteBinding.CROSSING_ID
	_record("npc_shuttle_yield_started",npc_id,{
		"crossing":SandboxStreetRouteBinding.CROSSING_ID,
		"source_offer":str(npc["transit_from_offer"]),
		"edge":SandboxRoads.edge_key(SandboxStreetRouteBinding.FROM,SandboxStreetRouteBinding.TO)})
	return true


func release_shuttle_crossing_yield(npc_id: String) -> bool:
	var npc: Dictionary=resident(npc_id)
	if npc.is_empty() or npc.get("transit_hold_crossing","")!=SandboxStreetRouteBinding.CROSSING_ID:
		return false
	var started: int=-1
	for i in range(events.size()-1,-1,-1):
		if events[i].get("kind","")=="npc_shuttle_yield_started" \
				and events[i].get("subject","")==npc_id:
			started=int(events[i]["minute"])
			break
	if started<0: return false
	_record("npc_shuttle_yield_ended",npc_id,{
		"crossing":SandboxStreetRouteBinding.CROSSING_ID,
		"source_offer":str(npc["transit_from_offer"]),
		"wait_minutes":minute-started})
	npc["transit_hold_crossing"]=""
	return true


# Right of way is a gameplay event, not a pause of the entire simulation.
# Only a grounded authored crossing on the CURRENT world road can latch.
func begin_crossing_yield() -> bool:
	if not route_hold_id.is_empty() or not SandboxStreetRouteBinding.approaching(self):
		return false
	route_hold_id=SandboxStreetRouteBinding.CROSSING_ID
	_record("taxi_yield_started","player",{
		"crossing":route_hold_id,
		"edge":SandboxRoads.edge_key(SandboxStreetRouteBinding.FROM,
				SandboxStreetRouteBinding.TO),
		"elapsed":route_edge_elapsed})
	return true

func release_crossing_yield() -> bool:
	if route_hold_id!=SandboxStreetRouteBinding.CROSSING_ID:
		return false
	_record("taxi_yield_ended","player",{"crossing":route_hold_id})
	route_hold_id=""
	return true


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
		if not active_offer_id.is_empty():
			resident(str(offer_by_id(active_offer_id)["npc_id"]))["location"] = to
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
			if not active_offer_id.is_empty():
				_complete_active_trip()
			else:
				_record("reposition_arrived", "player", {"to":travel_destination})
				travel_destination=""
				route_nodes.clear()
				route_segment=0
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
	npc["taxi_offer"] = ""
	npc["activity"] = "available"
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
	# The fare is settled only once; its real resident can now walk from the
	# curb toward the authored clinic entrance. This does not create an NPC.
	if route_segment > 0:
		SandboxPassengerAlight.begin(self, npc, offer, route_nodes[route_segment - 1])
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
		"modules_owned": modules_owned.duplicate(), "modules_installed": modules_installed.duplicate(),
		"market_stock": market_stock.duplicate(true), "common_requests": common_requests.duplicate(true),
		"ar_owned": ar_owned, "ar_equipped": ar_equipped,
		"residents": residents.duplicate(true), "offers": offers.duplicate(true),
		"events": events.duplicate(true), "active_offer_id": active_offer_id,
		"travel_destination": travel_destination, "engaged_offer_id": engaged_offer_id,
		"remaining_minutes": remaining_minutes, "route_nodes": route_nodes.duplicate(),
		"route_segment": route_segment, "route_edge_elapsed": route_edge_elapsed,
		"route_hold_id": route_hold_id,
		"vehicle_execution":vehicle_execution.duplicate(true),
		"vehicle_parking":vehicle_parking.duplicate(true),
		"vehicle_junctions":vehicle_junctions.duplicate(true),
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
	for collection in ["residents","offers","events","meetings"]:
		for entry in value[collection]:
			if not (entry is Dictionary): return false
	var district: String = str(value.get("player_district", ""))
	var remaining: int = int(value.get("remaining_minutes", -1))
	var active: String = str(value.get("active_offer_id", ""))
	var relocation: String = str(value.get("travel_destination", ""))
	var engagement: String = str(value.get("engaged_offer_id", ""))
	if not relocation.is_empty() and (not active.is_empty() or not SandboxRoads.DISTRICTS.has(relocation)): return false
	if not SandboxRoads.LINKS.has(district) or remaining < 0 or int(value.get("minute", -1)) < START_MINUTE:
		return false
	if int(value.get("credits", -1)) < 0 or int(value.get("risk", -1)) < 0:
		return false
	var device: String = str(value.get("starter_device", ""))
	if not (device.is_empty() or SandboxKnowledge.DEVICES.has(device)) \
			or not (value.get("knowledge") is Array) \
			or not (value.get("modules_owned") is Array) \
			or not (value.get("modules_installed") is Array) \
			or not (value.get("market_stock") is Dictionary) \
			or not (value.get("common_requests") is Dictionary) \
			or not (value.get("ar_owned") is bool) or not (value.get("ar_equipped") is bool):
		return false
	var purchases: int = 0
	var wear_state: bool = false
	for evt in value["events"]:
		if evt.get("kind") == "ar_purchased":
			if evt.get("subject") != "player" or evt.get("detail", {}).get("vendor") != AR_VENDOR \
					or evt.get("detail", {}).get("district") != "market" \
					or evt.get("detail", {}).get("price") != AR_PRICE:
				return false
			purchases += 1
		elif evt.get("kind") == "ar_equipped" or evt.get("kind") == "ar_removed":
			if purchases != 1 or evt.get("subject") != "player" \
					or evt.get("detail", {}).get("equipped") != (evt["kind"] == "ar_equipped") \
					or wear_state == (evt["kind"] == "ar_equipped"):
				return false
			wear_state = evt["kind"] == "ar_equipped"
	if purchases > 1 or bool(value["ar_owned"]) != (purchases == 1) \
			or bool(value["ar_equipped"]) != wear_state:
		return false
	var restored_knowledge: Array[String] = []
	for item in value["knowledge"]:
		if not (item is String) or restored_knowledge.has(item):
			return false
		restored_knowledge.append(item)
	if restored_knowledge.size() != (0 if device == "" or device == "module:local" else 1):
		return false
	if not device.is_empty() and device != "module:local" \
			and not restored_knowledge.has(str(SandboxKnowledge.FIRST_FACT[device])):
		return false
	var owned: Array[String] = []
	var installed: Array[String] = []
	for item in value["modules_owned"]:
		if not (item is String) or owned.has(item) or not SandboxKnowledge.LANGUAGES.has(item):
			return false
		owned.append(item)
	for item in value["modules_installed"]:
		if not (item is String) or installed.has(item) or not owned.has(item):
			return false
		installed.append(item)
	if not owned.has("trade") or not installed.has("trade") \
			or (device == "module:local" and not installed.has("local")):
		return false
	for language in SandboxKnowledge.MODULE_PRICES:
		var remaining_stock: Variant = value["market_stock"].get(language, -1)
		if not (remaining_stock is int) or remaining_stock < 0 or remaining_stock > 1:
			return false
		var bought: int = 0
		for evt in value["events"]:
			if evt.get("kind") == "market_module_purchased" and evt.get("subject") == language:
				bought += 1
		if bought != 1 - int(remaining_stock) \
				or (bought == 1 and not owned.has(language)) \
				or (owned.has(language) and bought == 0 and device != "module:%s" % language):
			return false
	if value["market_stock"].size() != SandboxKnowledge.MODULE_PRICES.size():
		return false
	for key in value["common_requests"]:
		if not (key is String) or not (value["common_requests"][key] is bool):
			return false
		var sourced: bool = false
		for evt in value["events"]:
			if evt.get("kind") == "common_language_requested" and evt.get("subject") == key \
					and evt.get("detail", {}).get("accepted") == value["common_requests"][key]:
				sourced = true
				break
		if not sourced:
			return false
	# Player hears a rumor only from the genuine recipient of a documented
	# NPC peer claim. The claim is hearsay even if the underlying fact is true.
	for heard in value["events"]:
		if heard.get("kind") != "player_rumor_heard":
			continue
		var detail: Dictionary = heard.get("detail", {})
		var source_ok: bool = false
		var heard_offer_ok: bool = false
		for offer in value["offers"]:
			if offer.get("id") == heard.get("subject") and offer.get("npc_id") == detail.get("speaker"):
				heard_offer_ok = true
				break
		for evt in value["events"]:
			if evt.get("id") == detail.get("claim_source") and evt.get("kind") == "npc_peer_contact" \
					and evt.get("minute", 99999999) <= heard.get("minute", -1) \
					and evt.get("detail", {}).get("recipient") == detail.get("speaker") \
					and evt.get("detail", {}).get("fact") == detail.get("fact") \
					and evt.get("detail", {}).get("value") == detail.get("value"):
				source_ok = true
				break
		if not source_ok or not heard_offer_ok or not str(detail.get("fact", "")).begins_with("residence:") \
				or not SandboxRoads.DISTRICTS.has(detail.get("value", "")):
			return false
	if value["residents"].size() != 9:
		return false
	var resident_ids: Dictionary = {}
	var walking_slots: Dictionary = {}
	for npc in value["residents"]:
		if not (npc is Dictionary) or not SandboxRoads.LINKS.has(npc.get("location", "")) \
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
		var local_trip: Dictionary=npc.get("local_pedestrian_trip",{}) if npc.get("local_pedestrian_trip",{}) is Dictionary else {}
		if local_trip.get("status","") in ["walking","offscreen"]:
			var slot: int=int(local_trip.get("slot",0))
			if walking_slots.has(slot) or walking_slots.size()>=2: return false
			walking_slots[slot]=true
		if not SandboxLocalPedestrianTrip.valid_history(npc, value["events"], int(value["minute"])):
			return false
		if not SandboxPassengerAlight.valid_history(npc, value["offers"], value["events"], int(value["minute"])):
			return false
		if not ["kind:a", "kind:b", "kind:c", "kind:d"].has(npc.get("species")) \
				or not ["harbor", "exchange", "newcomer"].has(npc.get("community")) \
				or not SandboxKnowledge.LANGUAGES.has(npc.get("language", "")) \
				or not (npc.get("speaks_common") is bool) \
				or not (npc.get("will_use_common") is bool) \
				or not (npc.get("peer_knowledge") is Dictionary) \
				or not (npc.get("contacts") is Dictionary) \
				or int(npc.get("last_peer_day", -2)) < -1:
			return false
		if not SandboxWorldTraffic.valid_yield_history(npc,value["events"],int(value["minute"])):
			return false
		var taxi_id: String = str(npc.get("taxi_offer", ""))
		if not taxi_id.is_empty():
			if taxi_id != active or npc.get("activity") != "travelling": return false
			var passenger_matches: bool = false
			for accepted in value["offers"]:
				if accepted.get("id") == taxi_id and accepted.get("npc_id") == npc.get("id"):
					passenger_matches = true
			if not passenger_matches: return false
		var transit: Array[String] = []
		if not (npc.get("transit_nodes") is Array): return false
		for transit_node in npc["transit_nodes"]:
			if not (transit_node is String): return false
			transit.append(transit_node)
		var travel_until: int = int(npc.get("transit_until", -1))
		if travel_until < 0:
			return false
		if travel_until > 0:
			if not taxi_id.is_empty() or not SandboxRoads.valid_path(transit) \
					or transit.front() != npc.get("location") or transit.back() != npc.get("transit_to") \
					or int(npc.get("transit_started", -1)) < 0 \
					or int(npc.get("transit_started", -1)) > int(value["minute"]) \
					or travel_until - int(npc.get("transit_started", -1)) \
					-int(npc.get("transit_pause_minutes",0)) != SandboxRoads.path_minutes(transit) * (1 if npc.get("transit_method") == "shuttle" else 4) \
					or travel_until <= int(value["minute"]) \
					or not SandboxRoads.DISTRICTS.has(npc.get("transit_to", "")) \
					or str(npc.get("transit_from_offer", "")).is_empty() \
					or not ["walking", "shuttle"].has(npc.get("transit_method", "")) \
					or npc.get("activity") != "travelling":
				return false
		elif not transit.is_empty() or int(npc.get("transit_started", -1)) != 0 or not str(npc.get("transit_to", "")).is_empty() \
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
	for accepted in value["offers"]:
		if accepted.get("status")=="accepted":
			var matching: bool=false
			for npc in value["residents"]:
				if npc.get("id")==accepted.get("npc_id") and npc.get("taxi_offer")==active: matching=true
			if not matching: return false
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
				or not SandboxRoads.LINKS.has(request.get("via")) \
				or not ["faster", "lower_exposure"].has(request.get("reason")):
			return false
	var segment: int = int(value.get("route_segment", -1))
	var elapsed: int = int(value.get("route_edge_elapsed", -1))
	var held: Variant=value.get("route_hold_id","")
	if not (held is String) or not ["",SandboxStreetRouteBinding.CROSSING_ID].has(held):
		return false
	# The signed event ledger tracks a matched start/end pair. A save cannot
	# invent an active crossing latch without its arrival in the event log.
	var ledger_hold: String=""
	for evt in value["events"]:
		if evt.get("kind","")=="taxi_yield_started":
			var detail: Dictionary=evt.get("detail",{})
			if ledger_hold!="" or evt.get("subject","")!="player" \
					or detail.get("crossing","")!=SandboxStreetRouteBinding.CROSSING_ID \
					or detail.get("edge","")!=SandboxRoads.edge_key(
							SandboxStreetRouteBinding.FROM,SandboxStreetRouteBinding.TO):
				return false
			ledger_hold=SandboxStreetRouteBinding.CROSSING_ID
		elif evt.get("kind","")=="taxi_yield_ended":
			if ledger_hold!=SandboxStreetRouteBinding.CROSSING_ID \
					or evt.get("subject","")!="player" \
					or evt.get("detail",{}).get("crossing","")!=ledger_hold:
				return false
			ledger_hold=""
	if held!=ledger_hold:
		return false
	if held!="":
		if segment<0 or segment>=route.size()-1:
			return false
		var from_node: String=route[segment]
		var to_node: String=route[segment+1]
		var crossing_fraction: float=SandboxStreetRouteBinding.crossing_fraction(from_node,to_node)
		if crossing_fraction<0.0 or not SandboxStreetRouteBinding.grounded():
			return false
		var edge_minutes: int=SandboxRoads.edge_minutes(from_node,to_node)
		if edge_minutes<=1 or float(elapsed)/float(edge_minutes)>=crossing_fraction \
				or float(elapsed+1)/float(edge_minutes)<crossing_fraction:
			return false
	if active.is_empty() and relocation.is_empty():
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
		if (not active.is_empty() and accepted_offer.is_empty()) or route.back() != (relocation if active.is_empty() else accepted_offer["destination"]) \
				or segment < 0 or segment >= route.size() - 1 \
				or route[segment] != district:
			return false
		if not pending.is_empty():
			if active.is_empty(): return false
			if route[segment + 1] == accepted_offer["destination"] \
					or not SandboxRoads.valid_path(pending) \
					or pending[0] != route[segment + 1] \
					or pending.back() != accepted_offer["destination"] \
					or remaining != SandboxRoads.edge_minutes(route[segment], route[segment + 1]) \
							- elapsed + SandboxRoads.path_minutes(pending):
				return false
		elif remaining != SandboxRoads.minutes_left(route, segment, elapsed):
			return false
	if not engagement.is_empty():
		var valid_engagement: bool = false
		for offer in value["offers"]:
			if offer.get("id")==engagement and offer.get("status")=="open" and offer.get("origin")==district:
				valid_engagement=true
		if not valid_engagement or not active.is_empty() or not relocation.is_empty(): return false

	if not SandboxVehicleParking.valid_snapshot(value) or not SandboxVehicleExecution.valid_snapshot(value) or not SandboxVehicleJunctions.valid_snapshot(value): return false
	seed = int(value.get("seed", 1))
	minute = int(value["minute"])
	player_district = district
	credits = int(value["credits"])
	risk = int(value["risk"])
	starter_device = device
	knowledge = restored_knowledge.duplicate()
	modules_owned = owned.duplicate()
	modules_installed = installed.duplicate()
	market_stock = value["market_stock"].duplicate(true)
	common_requests = value["common_requests"].duplicate(true)
	ar_owned = bool(value["ar_owned"])
	ar_equipped = bool(value["ar_equipped"])
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
	travel_destination = relocation
	engaged_offer_id = engagement
	remaining_minutes = remaining
	route_nodes = route.duplicate()
	route_segment = segment
	route_edge_elapsed = elapsed
	pending_route_nodes = pending.duplicate()
	rider_route_request = request.duplicate(true)
	route_hold_id=held
	vehicle_execution=value.get("vehicle_execution",{}).duplicate(true)
	vehicle_parking=value.get("vehicle_parking",{}).duplicate(true)
	vehicle_junctions=value.get("vehicle_junctions",{}).duplicate(true)
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
