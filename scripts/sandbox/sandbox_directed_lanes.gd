class_name SandboxDirectedLanes
extends RefCounted

# This is a world-metric *geometry* layer, subordinate to SandboxRoads.
# It does not decide NPC trips, lane admission, junction priority or duration.
# Lane physics/occupancy of the full city is a separate future contract.
const ROAD_PROFILES: Dictionary={
	"basin_turn|clinic":{"per_direction":1,"lane_width":62.0},
	"clinic|docks":{"per_direction":1,"lane_width":62.0},
	"freight_cross|quay_gate":{"per_direction":2,"lane_width":55.0},
	"garage|margin_gate":{"per_direction":1,"lane_width":46.0}
}

static func profile(from_node: String, to_node: String) -> Dictionary:
	if not SandboxRoads.connected(from_node,to_node): return {}
	return ROAD_PROFILES.get(SandboxRoads.edge_key(from_node,to_node),{})

static func has_profile(from_node: String,to_node: String) -> bool:
	return not profile(from_node,to_node).is_empty()

static func lane_count(from_node: String,to_node: String) -> int:
	return int(profile(from_node,to_node).get("per_direction",0))

static func valid_lane(from_node: String,to_node: String,index: int) -> bool:
	return index>=0 and index<lane_count(from_node,to_node)

static func lane_point(from_node: String,to_node: String,fraction: float,index: int=0) -> Vector3:
	if not valid_lane(from_node,to_node,index) or not is_finite(fraction):
		return Vector3.INF
	var t: float=clampf(fraction,0.0,1.0)
	var ahead: Vector3=SandboxRoads.sample_edge(from_node,to_node,minf(1.0,t+.001))
	var behind: Vector3=SandboxRoads.sample_edge(from_node,to_node,maxf(0.0,t-.001))
	var tangent: Vector2=Vector2(ahead.x-behind.x,ahead.z-behind.z).normalized()
	if tangent.length_squared()<.5: return Vector3.INF
	var width: float=float(profile(from_node,to_node)["lane_width"])
	var normal: Vector2=tangent.orthogonal()*(float(index)+.5)*width
	var centre: Vector3=SandboxRoads.sample_edge(from_node,to_node,t)
	return Vector3(centre.x+normal.x,centre.y,centre.z+normal.y)

# Bounded *visual* join between adjacent authored directed road lanes.
# The authoritative route always remains two original SandboxRoads edges:
# no extra road, fare minutes, event, or navigation/collision ownership.
const TURN_FRACTION: float = 0.075

static func _xz(point: Vector3) -> Vector2:
	return Vector2(point.x,point.z)

static func can_turn(previous: String, junction: String, following: String,
		index: int = 0) -> bool:
	if previous == following or previous == junction or junction == following:
		return false
	if not valid_lane(previous,junction,index) or not valid_lane(junction,following,index):
		return false
	# This first pilot only joins roads which meet on the same ground level.
	# Never draw a shortcut through a ramp/deck or across grade-separated roads.
	var p: Vector3=SandboxRoads.map_position(previous)
	var j: Vector3=SandboxRoads.map_position(junction)
	var n: Vector3=SandboxRoads.map_position(following)
	return is_equal_approx(p.y,j.y) and is_equal_approx(j.y,n.y)

static func turn_connector_point(previous: String, junction: String, following: String,
		fraction: float, index: int = 0) -> Vector3:
	if not can_turn(previous,junction,following,index) or not is_finite(fraction):
		return Vector3.INF
	var start: Vector3=lane_point(previous,junction,1.0-TURN_FRACTION,index)
	var finish: Vector3=lane_point(junction,following,TURN_FRACTION,index)
	if not start.is_finite() or not finish.is_finite(): return Vector3.INF
	var approach: Vector3=lane_point(previous,junction,1.0-TURN_FRACTION-.002,index)
	var depart: Vector3=lane_point(junction,following,TURN_FRACTION+.002,index)
	var forward: Vector2=(_xz(start)-_xz(approach)).normalized()
	var outward: Vector2=(_xz(depart)-_xz(finish)).normalized()
	if forward.length_squared()<.5 or outward.length_squared()<.5:
		return Vector3.INF
	var span: float=_xz(start).distance_to(_xz(finish))
	if span<1.0: return Vector3.INF
	var reach: float=minf(span*.32,180.0)
	var p0: Vector2=_xz(start)
	var p1: Vector2=p0+forward*reach
	var p3: Vector2=_xz(finish)
	var p2: Vector2=p3-outward*reach
	var t: float=clampf(fraction,0.0,1.0)
	var s: float=1.0-t
	var xy: Vector2=p0*s*s*s+3.0*p1*s*s*t+3.0*p2*s*t*t+p3*t*t*t
	return Vector3(xy.x,lerpf(start.y,finish.y,t),xy.y)

static func route_lane_point(nodes: Array[String], segment: int,
		fraction: float, index: int = 0) -> Vector3:
	if segment<0 or segment>=nodes.size()-1 or not is_finite(fraction):
		return Vector3.INF
	var from: String=nodes[segment]
	var to: String=nodes[segment+1]
	if not SandboxRoads.connected(from,to): return Vector3.INF
	var t: float=clampf(fraction,0.0,1.0)
	if not valid_lane(from,to,index):
		return SandboxRoads.sample_edge(from,to,t)
	if t>=1.0-TURN_FRACTION and segment+2<nodes.size():
		var joined: Vector3=turn_connector_point(from,to,nodes[segment+2],
				.5*(t-(1.0-TURN_FRACTION))/TURN_FRACTION,index)
		if joined.is_finite(): return joined
	if t<=TURN_FRACTION and segment>0:
		var joined: Vector3=turn_connector_point(nodes[segment-1],from,to,
				.5+.5*t/TURN_FRACTION,index)
		if joined.is_finite(): return joined
	return lane_point(from,to,t,index)

# A visual translation of authoritative NPC transit minutes into directed
# world-metric lanes. No simulation state, residents or extra route minutes.
static func path_lane_point(nodes: Array[String], elapsed: float,
		duration: float = -1.0, index: int = 0) -> Vector3:
	if not SandboxRoads.valid_path(nodes) or not is_finite(elapsed): return Vector3.INF
	if duration != -1.0 and (not is_finite(duration) or duration<=0.0): return Vector3.INF
	var total: float=float(SandboxRoads.path_minutes(nodes))
	if total<=0.0: return Vector3.INF
	var progress: float=clampf(elapsed*total/duration if duration>0.0 else elapsed,0.0,total)
	for segment in range(nodes.size()-1):
		var edge: float=float(SandboxRoads.edge_minutes(nodes[segment],nodes[segment+1]))
		if progress<=edge or segment==nodes.size()-2:
			return route_lane_point(nodes,segment,clampf(progress/edge,0.0,1.0),index)
		progress-=edge
	return Vector3.INF

static func path_screen_heading(nodes: Array[String], elapsed: float,
		duration: float = -1.0, index: int = 0) -> float:
	if not SandboxRoads.valid_path(nodes): return 0.0
	var finish: float=duration if duration>0.0 else float(SandboxRoads.path_minutes(nodes))
	if finish<=0.0 or not is_finite(elapsed): return 0.0
	var at: float=clampf(elapsed,0.0,finish)
	var behind: Vector3=path_lane_point(nodes,maxf(0.0,at-.15),duration,index)
	var ahead: Vector3=path_lane_point(nodes,minf(finish,at+.15),duration,index)
	if not behind.is_finite() or not ahead.is_finite(): return 0.0
	var tangent: Vector2=SandboxIsoPresentation.project(ahead)-SandboxIsoPresentation.project(behind)
	return tangent.angle() if tangent.length_squared()>.000001 else 0.0


static func route_screen_heading(nodes: Array[String], segment: int,
		fraction: float) -> float:
	if segment<0 or segment>=nodes.size()-1: return 0.0
	var t: float=clampf(fraction,0.0,1.0)
	var p: Vector3=route_lane_point(nodes,segment,maxf(0.0,t-.001))
	var q: Vector3=route_lane_point(nodes,segment,minf(1.0,t+.001))
	if not p.is_finite() or not q.is_finite(): return 0.0
	var projected: Vector2=SandboxIsoPresentation.project(q)-SandboxIsoPresentation.project(p)
	return projected.angle() if projected.length_squared()>.000001 else 0.0

static func taxi_screen(world: SandboxWorld,fraction: float) -> Vector2:
	var centre: Vector3=world.player_position(fraction)
	if world.is_travelling():
		var a: String=world.route_nodes[world.route_segment]
		var b: String=world.route_nodes[world.route_segment+1]
		if has_profile(a,b):
			var progress: float=(float(world.route_edge_elapsed)+clampf(fraction,0,1)) / \
					float(SandboxRoads.edge_minutes(a,b))
			var physical: Vector3=route_lane_point(world.route_nodes,world.route_segment,progress)
			if physical.is_finite(): return SandboxIsoPresentation.project(physical)
	elif world.player_district == "clinic":
		# The active route may already be cleared, but settled arrivals
		# preserve their actual inbound edge in immutable World events.
		for i in range(world.events.size()-1,-1,-1):
			var evt: Dictionary=world.events[i]
			if evt.get("kind","")!="route_segment_completed": continue
			var detail: Dictionary=evt.get("detail",{})
			var a: String=str(detail.get("from",""))
			var b: String=str(detail.get("to",""))
			if b == "clinic" and has_profile(a,b):
				return SandboxIsoPresentation.project(lane_point(a,b,1.0))
	return SandboxIsoPresentation.project(centre)
