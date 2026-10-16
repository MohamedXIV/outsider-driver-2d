class_name SandboxRoads
extends RefCounted

# Historical API name DISTRICTS now enumerates service/pickup stops. Regions
# are independent; LINKS includes real intermediate junctions and ramps.
const DISTRICTS: Array[String] = SandboxCityData.STOPS
const LINKS: Dictionary = SandboxCityData.LINKS
static var _curves: Dictionary = {}
static var _lengths: Dictionary = {}

static func district_for(node: String) -> String:
	return str(SandboxCityData.NODES.get(node, {}).get("region", ""))

static func location_name(node: String) -> String:
	return str(SandboxCityData.NODES.get(node, {}).get("name", node.capitalize()))

static func map_position(node: String) -> Vector3:
	return SandboxCityData.NODES.get(node, {}).get("position", Vector3.ZERO)

static func edge_key(a: String, b: String) -> String:
	return "%s|%s" % [a,b] if a < b else "%s|%s" % [b,a]

static func connected(a: String, b: String) -> bool:
	return LINKS.has(a) and LINKS[a].has(b)

static func edge_data(a: String, b: String) -> Dictionary:
	return SandboxCityData.EDGES.get(edge_key(a,b), {})

static func curve(a: String, b: String) -> Curve2D:
	var key: String = edge_key(a,b)
	if _curves.has(key):
		return _curves[key]
	var pair: PackedStringArray = key.split("|")
	var p: Vector3 = map_position(pair[0])
	var q: Vector3 = map_position(pair[1])
	var start: Vector2 = Vector2(p.x, p.z)
	var finish: Vector2 = Vector2(q.x, q.z)
	var delta: Vector2 = finish-start
	var bend: Vector2 = delta.orthogonal() * float(edge_data(a,b).get("bend", 0.0))
	var result: Curve2D = Curve2D.new()
	result.bake_interval = 15.0
	result.add_point(start, Vector2.ZERO, delta/3.0+bend)
	result.add_point(finish, -delta/3.0+bend, Vector2.ZERO)
	_curves[key] = result
	return result

static func sample_edge(a: String, b: String, fraction: float) -> Vector3:
	if not connected(a,b):
		return map_position(a)
	var t: float = clampf(fraction, 0.0, 1.0)
	var c: Curve2D = curve(a,b)
	var xy: Vector2 = c.sample_baked(c.get_baked_length()*(t if a<b else 1.0-t), true)
	var height: float = lerpf(map_position(a).y, map_position(b).y, smoothstep(0.0,1.0,t))
	return Vector3(xy.x,height,xy.y)

static func edge_metres(a: String, b: String) -> float:
	if not connected(a,b): return -1.0
	var key: String = edge_key(a,b)
	if not _lengths.has(key):
		var length: float = 0.0
		var previous: Vector3 = sample_edge(a,b,0)
		for i in range(1,65):
			var p: Vector3 = sample_edge(a,b,float(i)/64.0)
			length += previous.distance_to(p)
			previous = p
		_lengths[key] = length
	return float(_lengths[key])

static func edge_minutes(a: String, b: String) -> int:
	return maxi(1, ceili(edge_metres(a,b)/float(edge_data(a,b)["speed"])*0.06)) if connected(a,b) else -1

static func edge_expense(a: String, b: String) -> int:
	return int(edge_data(a,b).get("toll",0)) if connected(a,b) else -1

static func edge_exposure(a: String, b: String) -> int:
	return int(edge_data(a,b).get("exposure",0)) if connected(a,b) else -1

static func _shortest(origin: String, destination: String, blocked: Array[String] = []) -> Array[String]:
	if not LINKS.has(origin) or not LINKS.has(destination): return []
	var distances: Dictionary = {origin:0}
	var parents: Dictionary = {origin:""}
	var frontier: Array[String] = [origin]
	while not frontier.is_empty():
		var here: String = frontier[0]
		for candidate in frontier:
			if int(distances[candidate]) < int(distances[here]): here = candidate
		frontier.erase(here)
		if here == destination:
			var result: Array[String] = [here]
			while not str(parents[here]).is_empty():
				here = str(parents[here])
				result.push_front(here)
			return result
		for neighbor in LINKS[here]:
			var next: String = str(neighbor)
			if blocked.has(next): continue
			var cost: int = int(distances[here])+edge_minutes(here,next)
			if not distances.has(next) or cost < int(distances[next]):
				distances[next] = cost
				parents[next] = here
				if not frontier.has(next): frontier.append(next)
	return []

static func path(origin: String, destination: String, via: String = "") -> Array[String]:
	if via.is_empty() or via==origin or via==destination: return _shortest(origin,destination)
	var first: Array[String] = _shortest(origin,via,[destination])
	if first.is_empty(): return []
	var blocked: Array[String] = first.duplicate()
	blocked.erase(via)
	var second: Array[String] = _shortest(via,destination,blocked)
	if second.is_empty(): return []
	first.append_array(second.slice(1))
	return first

static func path_via(origin: String, destination: String, waypoints: Array[String]) -> Array[String]:
	var targets: Array[String]=waypoints.duplicate()
	targets.append(destination)
	var result: Array[String]=[origin]
	for i in range(targets.size()):
		var target: String=targets[i]
		if target==result.back(): continue
		var blocked: Array[String]=result.duplicate()
		blocked.pop_back()
		for future in targets.slice(i+1):
			if future!=target and not blocked.has(future): blocked.append(future)
		var leg: Array[String]=_shortest(result.back(),target,blocked)
		if leg.is_empty(): return []
		result.append_array(leg.slice(1))
	return result if valid_path(result) else []

static func valid_path(nodes: Array[String]) -> bool:
	if nodes.size()<2: return false
	var seen: Dictionary = {}
	for i in range(nodes.size()):
		if not LINKS.has(nodes[i]) or seen.has(nodes[i]): return false
		seen[nodes[i]] = true
		if i>0 and not connected(nodes[i-1],nodes[i]): return false
	return true

static func path_minutes(nodes: Array[String]) -> int:
	if nodes.size()==1 and LINKS.has(nodes[0]): return 0
	if not valid_path(nodes): return -1
	var total: int = 0
	for i in range(nodes.size()-1): total += edge_minutes(nodes[i],nodes[i+1])
	return total

static func path_metres(nodes: Array[String]) -> float:
	if nodes.size()==1: return 0
	if not valid_path(nodes): return -1
	var total: float = 0
	for i in range(nodes.size()-1): total += edge_metres(nodes[i],nodes[i+1])
	return total

static func path_expense(nodes: Array[String]) -> int:
	if not valid_path(nodes): return -1
	var total: int = 0
	for i in range(nodes.size()-1): total += edge_expense(nodes[i],nodes[i+1])
	return total

static func path_exposure(nodes: Array[String]) -> int:
	if not valid_path(nodes): return -1
	var total: int = 0
	for i in range(nodes.size()-1): total += edge_exposure(nodes[i],nodes[i+1])
	return total

static func hops(origin: String, destination: String) -> int:
	return path(origin,destination).size()-1

static func travel_minutes(origin: String, destination: String) -> int:
	return maxi(0,path_minutes(path(origin,destination)))

static func minutes_left(nodes: Array[String], segment: int, elapsed: int) -> int:
	if not valid_path(nodes) or segment<0 or segment>=nodes.size()-1: return -1
	if elapsed<0 or elapsed>=edge_minutes(nodes[segment],nodes[segment+1]): return -1
	var left: int = -elapsed
	for i in range(segment,nodes.size()-1): left += edge_minutes(nodes[i],nodes[i+1])
	return left

static func position_on_path(nodes: Array[String], elapsed: float, duration: float = -1.0) -> Vector3:
	if nodes.is_empty(): return Vector3.ZERO
	if nodes.size()==1: return map_position(nodes[0])
	var total: float = float(path_minutes(nodes))
	var progress: float = elapsed * total/duration if duration>0 else elapsed
	for i in range(nodes.size()-1):
		var edge_time: float = float(edge_minutes(nodes[i],nodes[i+1]))
		if progress<=edge_time: return sample_edge(nodes[i],nodes[i+1],progress/edge_time)
		progress -= edge_time
	return map_position(nodes.back())
