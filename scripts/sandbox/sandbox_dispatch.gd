class_name SandboxDispatch
extends RefCounted

# Demand is derived from NPC state at the current tick. Nothing schedules
# a particular passenger or gives a fixed fare to a fixed character.
const MIN_NEED: int = 53


static func refresh(residents: Array[Dictionary], offers: Array[Dictionary], minute: int, seed: int) -> void:
	for npc in residents:
		if int(npc["need"]) < MIN_NEED or int(npc["cooldown_until"]) > minute:
			continue
		var pending: bool = false
		for offer in offers:
			if offer["npc_id"] == npc["id"] and (offer["status"] == "open" or offer["status"] == "accepted"):
				pending = true
				break
		if pending:
			continue
		var origin: String = str(npc["location"])
		var destination: String = str(npc["destination"])
		var hops: int = SandboxRoads.hops(origin, destination)
		if hops <= 0:
			continue
		var fare: int = 4 + hops * 5 + int(npc["need"]) / 25
		if int(npc["cash"]) < fare:
			npc["cooldown_until"] = minute + 40
			continue
		var numeric_id: int = int(str(npc["id"]).trim_prefix("npc:"))
		var channel: String = ["street", "underground", "official"][posmod(seed + numeric_id, 3)]
		offers.append({
			"id": "offer:%s:%d" % [npc["id"], minute],
			"npc_id": npc["id"],
			"origin": origin,
			"destination": destination,
			"purpose": npc["purpose"],
			"fare": fare,
			"channel": channel,
			"created_at": minute,
			"expires_at": minute + 30 + int(npc["need"]) / 5,
			"status": "open"
		})


static func expire(residents: Array[Dictionary], offers: Array[Dictionary], minute: int) -> Array[String]:
	var expired: Array[String] = []
	for offer in offers:
		if offer["status"] != "open" or int(offer["expires_at"]) > minute:
			continue
		offer["status"] = "expired"
		expired.append(str(offer["id"]))
		for npc in residents:
			if npc["id"] == offer["npc_id"]:
				npc["cooldown_until"] = minute + 30
				break
	return expired
