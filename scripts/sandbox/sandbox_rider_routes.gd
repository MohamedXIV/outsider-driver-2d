class_name SandboxRiderRoutes
extends RefCounted

# No passenger-specific scenes. The live passenger's temperament weighs
# *actual* road durations and posted exposure against the driver's route.
static func request(npc: Dictionary, offer: Dictionary, chosen: Array[String]) -> Dictionary:
	var origin: String = str(offer["origin"])
	var destination: String = str(offer["destination"])
	var cautious: bool = str(npc["temperament"]) == "cautious"
	var preferred: Array[String] = SandboxRoads.path(origin, destination)
	var best: int = _score(preferred, cautious)
	for district in SandboxRoads.DISTRICTS:
		if district == origin or district == destination:
			continue
		var route: Array[String] = SandboxRoads.path(origin, destination, district)
		if not SandboxRoads.valid_path(route):
			continue
		var score: int = _score(route, cautious)
		if score < best:
			preferred = route
			best = score
	if preferred == chosen or preferred.size() < 3 or chosen.size() < 3:
		return {}
	var via: String = preferred[1]
	var continuation: Array[String] = SandboxRoads.path(chosen[1], destination, via)
	if not SandboxRoads.valid_path(continuation):
		return {}
	return {"via": via, "reason": "lower_exposure" if cautious else "faster",
		"status": "pending", "npc_id": str(npc["id"])}


static func _score(route: Array[String], cautious: bool) -> int:
	if not SandboxRoads.valid_path(route):
		return 100000
	return SandboxRoads.path_exposure(route) * 100 + SandboxRoads.path_minutes(route) \
			if cautious else SandboxRoads.path_minutes(route) * 10 + SandboxRoads.path_expense(route)
