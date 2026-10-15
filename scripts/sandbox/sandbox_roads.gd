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


# Named, physical edges shared by routing and authoritative fare consequences.
# The checkpoint on Market/Shelter is posted but only GPS-equipped drivers
# see its preview; other players discover its consequence by actually using it.
const ROAD_MINUTES: Dictionary = {"depot|shelter": 20}
const ROAD_EXPENSE: Dictionary = {"depot|shelter": 2}
const ROAD_EXPOSURE: Dictionary = {"market|shelter": 1}


static func edge_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


static func connected(a: String, b: String) -> bool:
	return LINKS.has(a) and LINKS[a].has(b)


static func edge_minutes(a: String, b: String) -> int:
	return int(ROAD_MINUTES.get(edge_key(a, b), 10)) if connected(a, b) else -1


static func edge_expense(a: String, b: String) -> int:
	return int(ROAD_EXPENSE.get(edge_key(a, b), 0)) if connected(a, b) else -1


static func edge_exposure(a: String, b: String) -> int:
	return int(ROAD_EXPOSURE.get(edge_key(a, b), 0)) if connected(a, b) else -1


static func path(origin: String, destination: String, via: String = "") -> Array[String]:
	# This compact unweighted authored graph only needs deterministic BFS.
	# Preserve simple connected paths, not a bespoke city-wide pathfinder.
	var first: Array[String] = _shortest(origin, via if not via.is_empty() else destination)
	if first.is_empty() or via.is_empty():
		return first
	var second: Array[String] = _shortest(via, destination)
	if second.is_empty():
		return []
	for node in second.slice(1):
		if first.has(node):
			return [] # A waypoint is not an excuse to drive the same street twice.
		first.append(str(node))
	return first


static func _shortest(origin: String, destination: String) -> Array[String]:
	if not LINKS.has(origin) or not LINKS.has(destination):
		return []
	if origin == destination:
		return [origin]
	var queue: Array[String] = [origin]
	var parents: Dictionary = {origin: ""}
	while not queue.is_empty():
		var here: String = queue.pop_front()
		for neighbor in LINKS[here]:
			var next: String = str(neighbor)
			if parents.has(next):
				continue
			parents[next] = here
			if next == destination:
				var result: Array[String] = [next]
				var cursor: String = here
				while not cursor.is_empty():
					result.push_front(cursor)
					cursor = str(parents[cursor])
				return result
			queue.append(next)
	return []


static func valid_path(nodes: Array[String]) -> bool:
	if nodes.size() < 2:
		return false
	var encountered: Dictionary = {}
	for i in range(nodes.size()):
		if not LINKS.has(nodes[i]) or encountered.has(nodes[i]):
			return false
		encountered[nodes[i]] = true
		if i > 0 and not connected(nodes[i - 1], nodes[i]):
			return false
	return true


static func path_minutes(nodes: Array[String]) -> int:
	if not valid_path(nodes):
		return -1
	var total: int = 0
	for i in range(nodes.size() - 1):
		total += edge_minutes(nodes[i], nodes[i + 1])
	return total


static func path_expense(nodes: Array[String]) -> int:
	if not valid_path(nodes):
		return -1
	var total: int = 0
	for i in range(nodes.size() - 1):
		total += edge_expense(nodes[i], nodes[i + 1])
	return total


static func path_exposure(nodes: Array[String]) -> int:
	if not valid_path(nodes):
		return -1
	var total: int = 0
	for i in range(nodes.size() - 1):
		total += edge_exposure(nodes[i], nodes[i + 1])
	return total


static func minutes_left(nodes: Array[String], segment: int, elapsed: int) -> int:
	if not valid_path(nodes) or segment < 0 or segment >= nodes.size() - 1:
		return -1
	if elapsed < 0 or elapsed >= edge_minutes(nodes[segment], nodes[segment + 1]) or elapsed % 10 != 0:
		return -1
	var left: int = -elapsed
	for i in range(segment, nodes.size() - 1):
		left += edge_minutes(nodes[i], nodes[i + 1])
	return left
