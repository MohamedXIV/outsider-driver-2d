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

# The same authored directed lanes may meet at a real road junction with
# different lateral offsets. Interpolating them independently causes a
# teleport at the minute the World moves between road segments. Bridge the
# last / first 12% using one shared cubic, split at its exact midpoint.
# This is a PRESENTATION curve: no extra route time or new driving authority.
const TURN_FRACTION: float = 0.12

static func junction_controls(previous: String, junction: String, next: String,
		lane_in: int=0, lane_out: int=0) -> PackedVector3Array:
	if previous == next or not valid_lane(previous,junction,lane_in) \
			or not valid_lane(junction,next,lane_out):
		return PackedVector3Array()
	var start: Vector3=lane_point(previous,junction,1.0-TURN_FRACTION,lane_in)
	var end: Vector3=lane_point(junction,next,TURN_FRACTION,lane_out)
	var before: Vector3=lane_point(previous,junction,1.0-TURN_FRACTION-.003,lane_in)
	var after: Vector3=lane_point(junction,next,TURN_FRACTION+.003,lane_out)
	if not start.is_finite() or not end.is_finite() or not before.is_finite() or not after.is_finite():
		return PackedVector3Array()
	# Don't connect different height grades as if a new ramp existed.
	if absf(start.y-end.y)>1.0 or absf(SandboxRoads.map_position(junction).y-start.y)>1.0:
		return PackedVector3Array()
	var incoming: Vector2=Vector2(start.x-before.x,start.z-before.z).normalized()
	var outgoing: Vector2=Vector2(after.x-end.x,after.z-end.z).normalized()
	if incoming.length_squared()<.5 or outgoing.length_squared()<.5: return PackedVector3Array()
	var radius: float=clampf(Vector2(start.x-end.x,start.z-end.z).length()*.42,5.0,1000.0)
	return PackedVector3Array([
		start,
		start+Vector3(incoming.x*radius,0.0,incoming.y*radius),
		end-Vector3(outgoing.x*radius,0.0,outgoing.y*radius),
		end])

static func junction_point(previous: String, junction: String, next: String,
		phase: float, lane_in: int=0, lane_out: int=0) -> Vector3:
	var controls: PackedVector3Array=junction_controls(previous,junction,next,lane_in,lane_out)
	if controls.is_empty() or not is_finite(phase): return Vector3.INF
	var t: float=clampf(phase,0.0,1.0)
	var omt: float=1.0-t
	return controls[0]*omt*omt*omt+controls[1]*3.0*omt*omt*t \
			+controls[2]*3.0*omt*t*t+controls[3]*t*t*t

static func route_point(nodes: Array[String], segment: int, fraction: float) -> Vector3:
	if segment<0 or segment+1>=nodes.size() or not is_finite(fraction):
		return Vector3.INF
	var a: String=nodes[segment]
	var b: String=nodes[segment+1]
	if not SandboxRoads.connected(a,b): return Vector3.INF
	var t: float=clampf(fraction,0.0,1.0)
	if segment>0 and t<=TURN_FRACTION:
		var before: String=nodes[segment-1]
		var entering: Vector3=junction_point(before,a,b,.5+.5*t/TURN_FRACTION)
		if entering.is_finite(): return entering
	if segment+2<nodes.size() and t>=1.0-TURN_FRACTION:
		var after: String=nodes[segment+2]
		var leaving: Vector3=junction_point(a,b,after,.5*(t-(1.0-TURN_FRACTION))/TURN_FRACTION)
		if leaving.is_finite(): return leaving
	return lane_point(a,b,t) if has_profile(a,b) else SandboxRoads.sample_edge(a,b,t)

static func route_heading(nodes: Array[String], segment: int, fraction: float) -> float:
	var a: Vector3=route_point(nodes,segment,clampf(fraction-.001,0.0,1.0))
	var b: Vector3=route_point(nodes,segment,clampf(fraction+.001,0.0,1.0))
	if not a.is_finite() or not b.is_finite(): return 0.0
	var screen: Vector2=SandboxIsoPresentation.project(b)-SandboxIsoPresentation.project(a)
	return screen.angle() if screen.length_squared()>.000001 else 0.0

static func taxi_screen(world: SandboxWorld,fraction: float) -> Vector2:
	var centre: Vector3=world.player_position(fraction)
	if world.is_travelling():
		var a: String=world.route_nodes[world.route_segment]
		var b: String=world.route_nodes[world.route_segment+1]
		var progress: float=(float(world.route_edge_elapsed)+clampf(fraction,0,1)) / \
				float(SandboxRoads.edge_minutes(a,b))
		var physical: Vector3=route_point(world.route_nodes,world.route_segment,progress)
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
