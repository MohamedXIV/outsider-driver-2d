class_name SandboxARHints
extends RefCounted

# This is a projection over PlayerKnowledge and sourced world events, NOT
# over private NPC attributes. No inference from npc.home, destination, trust,
# hidden identity, future route state or authoritative peer_knowledge here.
#
# Context is a real live Ink frame: no future destination hint before an
# understood "ask_destination" speech act.
static func contextual(world: SandboxWorld, frame: Dictionary, offer: Dictionary,
		understood: bool) -> Dictionary:
	if not world.ar_equipped or offer.is_empty():
		return {}
	var speaker: String = str(offer.get("npc_id", ""))
	# Hearsay must have a prior explicit PLAYER-heard event. The NPC's
	# private peer knowledge is never inspected by this read-only projection.
	var heard: Array = world.events_of_kind("player_rumor_heard")
	for i in range(heard.size() - 1, -1, -1):
		var event: Dictionary = heard[i]
		if event.get("detail", {}).get("speaker") != speaker:
			continue
		var detail: Dictionary = event["detail"]
		return {
			"term": str(detail["fact"]).trim_prefix("residence:"),
			"kind": "rumor", "certainty": "unverified",
			"text": "Rumor: %s may live in %s." % [
				str(detail["fact"]).trim_prefix("residence:"), str(detail["value"])],
			"source": "%s heard from %s; original contact %s" % [
				str(event["id"]), speaker, str(detail["claim_source"])]
		}
	if not understood or not frame.get("tags", []).has("intent:ask_destination"):
		return {}
	var destination: String = str(offer.get("destination", ""))
	# The engine's offer knows the target, but this projection only returns it
	# when the NPC has actually spoken it and the player understands.
	return known_district(world, destination)


static func known_district(world: SandboxWorld, district: String) -> Dictionary:
	if not world.ar_equipped or not SandboxRoads.DISTRICTS.has(district):
		return {}
	# A GPS-starter fact is already PlayerKnowledge, with event provenance.
	if world.knows("map:district-graph"):
		for event in world.events_of_kind("knowledge_learned"):
			if event.get("detail", {}).get("fact") == "map:district-graph":
				return {
					"term": district, "kind": "verified", "certainty": "verified",
					"text": "%s: known GPS links: %s." % [
						district.capitalize(), ", ".join(SandboxRoads.LINKS[district])],
					"source": "%s / %s" % [str(event["id"]), str(event["detail"]["source"])]
				}
	# A verified visit must have an actual journey event, not an internal
	# NPC position or a destination in an unaccepted offer.
	var reached: Dictionary = _latest_arrival(world, district)
	if not reached.is_empty():
		return {
			"term": district, "kind": "verified", "certainty": "verified",
			"text": "%s: you have personally reached this district." % district.capitalize(),
			"source": str(reached["id"]) + " / " + str(reached["kind"])
		}
	if district == "docks":
		return {
			"term": "docks", "kind": "verified", "certainty": "verified",
			"text": "Docks: your starting district.",
			"source": "start:player:docks"
		}
	return {}


# Most recent real arrival at `district` (a reposition or a settled fare). Scans
# only those two kinds, newest first, and stops at the first match per kind.
static func _latest_arrival(world: SandboxWorld, district: String) -> Dictionary:
	var best: Dictionary = {}
	for kind in ["reposition", "fare_settled"]:
		var list: Array = world.events_of_kind(kind)
		for i in range(list.size() - 1, -1, -1):
			var event: Dictionary = list[i]
			if event.get("detail", {}).get("to") == district:
				if best.is_empty() or _event_number(event) > _event_number(best):
					best = event
				break
	return best


static func _event_number(event: Dictionary) -> int:
	return int(str(event.get("id", "")).trim_prefix("event:"))
