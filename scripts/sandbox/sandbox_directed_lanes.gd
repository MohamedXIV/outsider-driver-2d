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

static func taxi_screen(world: SandboxWorld,fraction: float) -> Vector2:
	var centre: Vector3=world.player_position(fraction)
	if world.is_travelling():
		var a: String=world.route_nodes[world.route_segment]
		var b: String=world.route_nodes[world.route_segment+1]
		if has_profile(a,b):
			var progress: float=(float(world.route_edge_elapsed)+clampf(fraction,0,1)) / \
					float(SandboxRoads.edge_minutes(a,b))
			var physical: Vector3=lane_point(a,b,progress)
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
