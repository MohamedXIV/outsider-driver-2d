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
	for i in range(world.events.size() - 1, -1, -1):
		var event: Dictionary = world.events[i]
		if event.get("kind") != "player_rumor_heard" \
				or event.get("detail", {}).get("speaker") != speaker:
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
		for event in world.events:
			if event.get("kind") == "knowledge_learned" \
					and event.get("detail", {}).get("fact") == "map:district-graph":
				return {
					"term": district, "kind": "verified", "certainty": "verified",
					"text": "%s: known GPS links: %s." % [
						district.capitalize(), ", ".join(SandboxRoads.LINKS[district])],
					"source": "%s / %s" % [str(event["id"]), str(event["detail"]["source"])]
				}
	# A verified visit must have an actual journey event, not an internal
	# NPC position or a destination in an unaccepted offer.
	for i in range(world.events.size() - 1, -1, -1):
		var event: Dictionary = world.events[i]
		var reached: bool = (event.get("kind") == "reposition" \
				or event.get("kind") == "fare_settled") \
				and event.get("detail", {}).get("to") == district
		if reached:
			return {
				"term": district, "kind": "verified", "certainty": "verified",
				"text": "%s: you have personally reached this district." % district.capitalize(),
				"source": str(event["id"]) + " / " + str(event["kind"])
			}
	if district == "docks":
		return {
			"term": "docks", "kind": "verified", "certainty": "verified",
			"text": "Docks: your starting district.",
			"source": "start:player:docks"
		}
	return {}
