class_name SandboxRoads
extends RefCounted

# Small authored road GRAPH, not an authored passenger route.
# Nodes and edges are shared between all NPC mobility requests.
const DISTRICTS: Array[String] = ["docks", "market", "clinic", "shelter", "depot"]
const LINKS: Dictionary = {
	"docks": ["market", "depot"],
	"market": ["docks", "clinic", "shelter"],
	"clinic": ["market"],
	"shelter": ["market", "depot"],
	"depot": ["docks", "shelter"]
}
const POSITIONS: Dictionary = {
	"docks": Vector3(-9, 0, 0),
	"market": Vector3(-2, 0, 0),
	"clinic": Vector3(7, 0, -4),
	"shelter": Vector3(6, 0, 9),
	"depot": Vector3(-7, 0, 10)
}


static func hops(origin: String, destination: String) -> int:
	if not LINKS.has(origin) or not LINKS.has(destination):
		return -1
	if origin == destination:
		return 0
	var frontier: Array[String] = [origin]
	var distance: Dictionary = {origin: 0}
	while not frontier.is_empty():
		var here: String = frontier.pop_front()
		for neighbor in LINKS[here]:
			var next: String = str(neighbor)
			if distance.has(next):
				continue
			distance[next] = int(distance[here]) + 1
			if next == destination:
				return int(distance[next])
			frontier.append(next)
	return -1


static func travel_minutes(origin: String, destination: String) -> int:
	return maxi(0, hops(origin, destination)) * 10


static func map_position(district: String) -> Vector3:
	return POSITIONS.get(district, Vector3.ZERO)
