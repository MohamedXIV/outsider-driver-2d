class_name SandboxPopulation
extends RefCounted

# Persistent agents. Goals depend on personal needs, not on taxi scenario IDs.
const PURPOSES: Array[String] = ["medical", "supplies", "work", "shelter"]
const GOALS: Dictionary = {
	"medical": "clinic", "supplies": "market",
	"work": "depot", "shelter": "shelter"
}


static func create(seed: int) -> Array[Dictionary]:
	var residents: Array[Dictionary] = []
	for i in range(9):
		var kind: String = PURPOSES[posmod(seed + i * 3, PURPOSES.size())]
		var home: String = SandboxRoads.DISTRICTS[posmod(seed + i * 2, SandboxRoads.DISTRICTS.size())]
		var destination: String = destination_for(home, kind)
		residents.append({
			"id": "npc:%02d" % i,
			"location": home,
			"home": home,
			"workplace": ["depot", "market", "clinic"][i % 3],
			"activity": "available",
			"transit_until": 0,
			"transit_to": "",
			"transit_from_offer": "",
			"transit_method": "",
			"purpose": kind,
			"destination": destination,
			"need": 30 + posmod(seed * 3 + i * 17, 51),
			"cash": 24 + posmod(seed * 5 + i * 13, 40),
			"trust": 0,
			"driver_memories": [],
			"driver_identity_facts": {},
			"cooldown_until": 0,
			# Provisional social identity. Distinct species can share a language,
			# and co-resident communities are not automatic faction clones.
			"species": ["kind:a", "kind:b", "kind:c", "kind:d"][i % 4],
			"community": ["harbor", "exchange", "newcomer"][posmod(seed + i, 3)],
			"peer_knowledge": {},
			"contacts": {},
			"last_peer_day": -1,
			"language": SandboxKnowledge.LANGUAGES[i % 3],
			"speaks_common": i % 4 != 1,
			"will_use_common": i % 3 != 2,
			"temperament": "cautious" if i % 2 == 0 else "urgent"
		})
	return residents


static func destination_for(origin: String, purpose: String) -> String:
	var goal: String = str(GOALS.get(purpose, "market"))
	return "docks" if origin == goal else goal


static func step(residents: Array[Dictionary], minute: int) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	var hour: int = (minute % 1440) / 60
	for npc in residents:
		var next_activity: String = "available"
		if int(npc["transit_until"]) > 0:
			next_activity = "travelling"
		elif (hour >= 22 or hour < 6) and str(npc["location"]) == str(npc["home"]):
			next_activity = "resting"
		elif hour >= 8 and hour < 18 and str(npc["location"]) == str(npc["workplace"]):
			next_activity = "working"
		if str(npc["activity"]) != next_activity:
			changes.append({
				"kind": "npc_routine_changed", "subject": str(npc["id"]),
				"detail": {"from": npc["activity"], "to": next_activity, "district": npc["location"]}
			})
		npc["activity"] = next_activity
		match next_activity:
			"resting":
				npc["need"] = maxi(8, int(npc["need"]) - 7)
			"working":
				npc["need"] = mini(100, int(npc["need"]) + 2)
				if minute % 60 == 0:
					npc["cash"] = int(npc["cash"]) + 2
					changes.append({
						"kind": "npc_work_paid", "subject": str(npc["id"]),
						"detail": {"district": npc["location"], "credits": 2}
					})
			"travelling":
				npc["need"] = mini(100, int(npc["need"]) + 2)
			_:
				npc["need"] = mini(100, int(npc["need"]) + 5)
	return changes


static func finish_goal(npc: Dictionary, destination: String, minute: int) -> void:
	npc["location"] = destination
	npc["need"] = 10
	npc["cooldown_until"] = maxi(int(npc["cooldown_until"]), minute + 30)
	var current: int = PURPOSES.find(str(npc["purpose"]))
	npc["purpose"] = PURPOSES[(current + 1) % PURPOSES.size()]
	npc["destination"] = destination_for(destination, str(npc["purpose"]))


static func conclude_trip(npc: Dictionary, destination: String, fare: int, minute: int) -> void:
	npc["cash"] = int(npc["cash"]) - fare
	npc["trust"] = int(npc["trust"]) + 1
	finish_goal(npc, destination, minute)
