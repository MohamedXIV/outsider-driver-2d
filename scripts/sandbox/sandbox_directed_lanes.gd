class_name SandboxDirectedLanes
extends RefCounted

# This is a world-metric *geometry* layer, subordinate to SandboxRoads.
# It does not decide NPC trips, lane admission, junction priority or duration.
# Lane physics/occupancy of the full city is a separate future contract.
const ROAD_PROFILES: Dictionary={
	"basin_turn|clinic":{"per_direction":1,"lane_width":240.0},
	"clinic|docks":{"per_direction":1,"lane_width":240.0},
	"freight_cross|quay_gate":{"per_direction":2,"lane_width":240.0},
	"garage|margin_gate":{"per_direction":1,"lane_width":240.0}
}

# The 25×13 projected vehicle footprint needs at least 17 screen units
# between neighbouring flows, including four units of clearance. Widths
# remain metric; the painted envelope follows their projected extrema.
static var _screen_widths: Dictionary={}

static func screen_road_width(a: String,b: String) -> float:
	if not has_profile(a,b): return 23.0
	var key: String=SandboxRoads.edge_key(a,b)
	if _screen_widths.has(key): return float(_screen_widths[key])
	var extent: float=0.0
	for sample in range(1,100):
		var t: float=float(sample)/100.0
		var centre: Vector2=SandboxIsoPresentation.project(SandboxRoads.sample_edge(a,b,t))
		var tangent: Vector2=SandboxIsoPresentation.project(SandboxRoads.sample_edge(a,b,t+.001))-SandboxIsoPresentation.project(SandboxRoads.sample_edge(a,b,t-.001))
		for side in [false,true]:
			var lane: Vector3=lane_point(b,a,1.0-t,lane_count(a,b)-1) if side else lane_point(a,b,t,lane_count(a,b)-1)
			extent=maxf(extent,absf((SandboxIsoPresentation.project(lane)-centre).dot(tangent.normalized().orthogonal())))
	var width: float=ceilf(2.0*(extent+10.5))
	_screen_widths[key]=width
	return width

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
	var lane: Vector3=lane_point(from,to,t,index)
	# Where an authored lane section meets the existing centerline presenter,
	# taper only its lateral offset. Both samplers then meet at the same
	# graph node, including ramps; never invent a grade-level turn connector.
	var weight: float=1.0
	if segment>0 and not valid_lane(nodes[segment-1],from,index):
		weight=minf(weight,smoothstep(0.0,TURN_FRACTION,t))
	if segment+2<nodes.size() and not valid_lane(to,nodes[segment+2],index):
		weight=minf(weight,smoothstep(0.0,TURN_FRACTION,1.0-t))
	return SandboxRoads.sample_edge(from,to,t).lerp(lane,weight)

# Pure display sampling for real World-owned journeys. The units/edge times
# are exactly SandboxRoads' canonical minutes; no independent vehicle clock.
# Unprofiled roads preserve their existing centerline presentation.
static func route_point_at_minutes(nodes: Array[String], elapsed: float,
		duration: float = -1.0, index: int = 0) -> Vector3:
	if not SandboxRoads.valid_path(nodes) or not is_finite(elapsed) or not is_finite(duration):
		return Vector3.INF
	if duration == 0.0 or (duration < 0.0 and duration != -1.0):
		return Vector3.INF
	var total: float = float(SandboxRoads.path_minutes(nodes))
	var progress: float = clampf(elapsed * total / duration if duration > 0.0 else elapsed,
			0.0, total)
	for segment in range(nodes.size()-1):
		var minutes: float = float(SandboxRoads.edge_minutes(nodes[segment], nodes[segment+1]))
		if progress <= minutes:
			return route_lane_point(nodes, segment, progress / minutes, index)
		progress -= minutes
	return route_lane_point(nodes, nodes.size()-2, 1.0, index)

# A single projected tangent straddles REAL authored edge boundaries.
# Both player taxi and world-owned shuttle use this same pure source;
# a junction never falls back to an isolated edge's terminal derivative.
static func route_screen_tangent_at_minutes(nodes: Array[String], elapsed: float,
		duration: float = -1.0, index: int = 0) -> Vector2:
	if not SandboxRoads.valid_path(nodes) or not is_finite(elapsed) \
			or not is_finite(duration) or (duration <= 0.0 and duration != -1.0):
		return Vector2.ZERO
	var finish: float = duration if duration>0.0 else float(SandboxRoads.path_minutes(nodes))
	if finish<=0.0: return Vector2.ZERO
	var at: float = clampf(elapsed,0.0,finish)
	var before: Vector3 = route_point_at_minutes(nodes,maxf(0.0,at-0.15),duration,index)
	var after: Vector3 = route_point_at_minutes(nodes,minf(finish,at+0.15),duration,index)
	if not before.is_finite() or not after.is_finite(): return Vector2.ZERO
	return SandboxIsoPresentation.project(after)-SandboxIsoPresentation.project(before)

# The player World stores one elapsed count per segment. Map it onto the
# original complete route, without introducing any parallel simulation clock.
static func taxi_elapsed_minutes(world: SandboxWorld, fraction: float = 0.0) -> float:
	if not world.is_travelling() or not is_finite(fraction): return -1.0
	if world.vehicle_execution.has("player"): return SandboxVehicleExecution.progress(world,"player",fraction)
	if not world.route_hold_id.is_empty(): fraction=0.0
	var elapsed: float = float(world.route_edge_elapsed)+clampf(fraction,0.0,1.0)
	for segment in range(world.route_segment):
		elapsed += float(SandboxRoads.edge_minutes(
				world.route_nodes[segment],world.route_nodes[segment+1]))
	return elapsed

static func route_screen_heading(nodes: Array[String], segment: int,
		fraction: float) -> float:
	if segment<0 or segment>=nodes.size()-1: return 0.0
	var t: float=clampf(fraction,0.0,1.0)
	var p: Vector3=route_lane_point(nodes,segment,maxf(0.0,t-.001))
	var q: Vector3=route_lane_point(nodes,segment,minf(1.0,t+.001))
	if not p.is_finite() or not q.is_finite(): return 0.0
	var projected: Vector2=SandboxIsoPresentation.project(q)-SandboxIsoPresentation.project(p)
	return projected.angle() if projected.length_squared()>.000001 else 0.0

# A parked pose is reconstructed from the most recent real arrival at this
# stop, never a renderer-owned remembered position or an older lane visit.
static func _parked_screen(world: SandboxWorld, stop: String) -> Vector2:
	var actual: Vector2=SandboxVehicleParking.screen(world,stop)
	if actual.is_finite(): return actual
	return parked_screen_from_events(world.events,stop)

static func parked_screen_from_events(events: Array, stop: String) -> Vector2:
	for i in range(events.size()-1,-1,-1):
		var evt: Dictionary=events[i]
		if evt.get("kind","")!="route_segment_completed": continue
		var detail: Dictionary=evt.get("detail",{})
		var a: String=str(detail.get("from",""))
		var b: String=str(detail.get("to",""))
		if b!=stop: continue
		if has_profile(a,b): return SandboxIsoPresentation.project(lane_point(a,b,1.0))
		break
	return SandboxIsoPresentation.project(SandboxRoads.map_position(stop))

static func taxi_screen(world: SandboxWorld,fraction: float) -> Vector2:
	if not world.is_travelling(): return _parked_screen(world,world.player_district)
	if world.vehicle_execution.has("player"):
		return SandboxVehicleExecution.screen(world,"player",fraction)
	if not world.route_hold_id.is_empty(): fraction=0.0
	var a: String=world.route_nodes[world.route_segment]
	var b: String=world.route_nodes[world.route_segment+1]
	var progress: float=(float(world.route_edge_elapsed)+clampf(fraction,0,1)) / \
			float(SandboxRoads.edge_minutes(a,b))
	var physical: Vector3=route_lane_point(world.route_nodes,world.route_segment,progress)
	if not physical.is_finite(): return SandboxIsoPresentation.project(world.player_position(fraction))
	var screen: Vector2=SandboxIsoPresentation.project(physical)
	if world.route_segment==0 and progress<TURN_FRACTION:
		# Depart from the actual last parked pose, merging smoothly onto the
		# chosen directed lane over its existing authored approach interval.
		var start: Vector2=SandboxIsoPresentation.project(route_lane_point(world.route_nodes,0,0.0))
		screen+=(_parked_screen(world,a)-start)*(1.0-smoothstep(0.0,TURN_FRACTION,progress))
	return screen
