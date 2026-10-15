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
			"purpose": kind,
			"destination": destination,
			"need": 30 + posmod(seed * 3 + i * 17, 51),
			"cash": 24 + posmod(seed * 5 + i * 13, 40),
			"trust": 0,
			"cooldown_until": 0,
			"language": "trade" if i % 3 == 0 else "local",
			"temperament": "cautious" if i % 2 == 0 else "urgent"
		})
	return residents


static func destination_for(origin: String, purpose: String) -> String:
	var goal: String = str(GOALS.get(purpose, "market"))
	return "docks" if origin == goal else goal


static func step(residents: Array[Dictionary]) -> void:
	for npc in residents:
		npc["need"] = mini(100, int(npc["need"]) + 5)


static func conclude_trip(npc: Dictionary, destination: String, fare: int, minute: int) -> void:
	npc["location"] = destination
	npc["cash"] = int(npc["cash"]) - fare
	npc["need"] = 10
	npc["trust"] = int(npc["trust"]) + 1
	npc["cooldown_until"] = minute + 30
	var current: int = PURPOSES.find(str(npc["purpose"]))
	npc["purpose"] = PURPOSES[(current + 1) % PURPOSES.size()]
	npc["destination"] = destination_for(destination, str(npc["purpose"]))
