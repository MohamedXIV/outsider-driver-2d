class_name SandboxAutonomy
extends RefCounted

# Independent transport is a timed, world-owned NPC trip, never an invisible
# change to the player's fare timer or an invented named ride provider.
# These transitions return causal events; SandboxWorld assigns event IDs.

static func begin_expired_trips(residents: Array[Dictionary], offers: Array[Dictionary],
		expired_ids: Array[String], minute: int, seed: int) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for offer_id in expired_ids:
		var offer: Dictionary = {}
		for candidate in offers:
			if candidate["id"] == offer_id:
				offer = candidate
				break
		if offer.is_empty():
			continue
		var npc: Dictionary = {}
		for candidate in residents:
			if candidate["id"] == offer["npc_id"]:
				npc = candidate
				break
		if npc.is_empty() or int(npc.get("transit_until", 0)) > 0:
			continue
		if str(npc["location"]) != str(offer["origin"]) or str(offer["status"]) != "expired":
			continue
		var hops: int = SandboxRoads.hops(str(npc["location"]), str(offer["destination"]))
		if hops <= 0:
			continue
		# Affordable municipal shuttle vs walking: seed and character create
		# stable, independent choices; no disposable 'NPC cab driver' appears.
		var numeric_id: int = int(str(npc["id"]).trim_prefix("npc:"))
		var nodes: Array[String] = SandboxRoads.path(str(npc["location"]),str(offer["destination"]))
		var shuttle_cost: int = maxi(1,ceili(SandboxRoads.path_metres(nodes)/4000.0))
		var use_shuttle: bool = hops > 1 and int(npc["cash"]) >= shuttle_cost \
				and posmod(seed + numeric_id + int(minute / 10), 3) != 0
		var method: String = "shuttle" if use_shuttle else "walking"
		var cost: int = shuttle_cost if use_shuttle else 0
		var duration: int = SandboxRoads.path_minutes(nodes) * (1 if use_shuttle else 4)
		npc["cash"] = int(npc["cash"]) - cost
		npc["transit_until"] = minute + duration
		npc["transit_started"] = minute
		npc["transit_nodes"] = nodes.duplicate()
		npc["transit_to"] = str(offer["destination"])
		npc["transit_from_offer"] = offer_id
		npc["transit_method"] = method
		npc["transit_pause_minutes"] = 0
		npc["transit_hold_crossing"] = ""
		npc["activity"] = "travelling"
		npc["cooldown_until"] = maxi(int(npc["cooldown_until"]), minute + duration + 30)
		changes.append({
			"kind": "npc_alternative_departed", "subject": str(npc["id"]),
			"detail": {
				"offer_id": offer_id, "from": offer["origin"], "to": offer["destination"],
				"method": method, "cost": cost, "arrival_at": minute + duration
			}
		})
	return changes


static func finish_arrivals(residents: Array[Dictionary], minute: int) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for npc in residents:
		var arrival: int = int(npc.get("transit_until", 0))
		if arrival <= 0 or arrival > minute:
			continue
		var destination: String = str(npc["transit_to"])
		var departed_from: String = str(npc["location"])
		var source: String = str(npc["transit_from_offer"])
		var method: String = str(npc["transit_method"])
		npc["transit_until"] = 0
		npc["transit_started"] = 0
		npc["transit_nodes"] = []
		npc["transit_to"] = ""
		npc["transit_from_offer"] = ""
		npc["transit_method"] = ""
		npc["transit_pause_minutes"] = 0
		npc["transit_hold_crossing"] = ""
		npc["activity"] = "available"
		SandboxPopulation.finish_goal(npc, destination, minute)
		changes.append({
			"kind": "npc_alternative_arrived", "subject": str(npc["id"]),
			"detail": {
				"offer_id": source, "from": departed_from, "to": destination,
				"method": method
			}
		})
	return changes
