class_name SandboxVehicleBays
extends RefCounted

# One authored clinic frontage; no invented city-wide parking network.
const CLINIC: String="clinic-curb-v1"
const SHUTTLE: String="clinic-shuttle-v1"
const BLEND: float=.15
const CAR_OFFSET: float=40.0
const DOOR_CLEARANCE: float=14.0

static func normal(from: String) -> Vector2:
	var trip: Dictionary={"from":from}
	var side: Vector2=SandboxAlightGeometry.tangent(trip).orthogonal()
	var centre: Vector2=SandboxCityView.project(SandboxRoads.map_position("clinic"))
	if side.dot(SandboxAlightGeometry.goal(trip)-centre)<0.0: side=-side
	return side

static func policy(nodes: Array[String]) -> String:
	if nodes.size()<2 or nodes.back()!="clinic": return ""
	var from: String=nodes[nodes.size()-2]
	return CLINIC if SandboxDirectedLanes.has_profile(from,"clinic") and SandboxRoads.map_position(from).y==0.0 else ""

static func point(from: String) -> Vector2:
	return SandboxCityView.project(SandboxRoads.map_position("clinic"))+normal(from)*CAR_OFFSET

static func apply(travel: Dictionary,at: float,screen: Vector2) -> Vector2:
	if travel.get("arrival_policy","") not in [CLINIC,SHUTTLE]: return screen
	var nodes: Array[String]=SandboxVehicleExecution.nodes_of(travel)
	if policy(nodes)!=CLINIC: return screen
	var from: String=nodes[nodes.size()-2]
	var duration: float=SandboxRoads.edge_minutes(from,"clinic")
	var total: float=SandboxRoads.path_minutes(nodes)
	var weight: float=smoothstep(total-duration*BLEND,total,at)
	var lane_end: Vector2=SandboxCityView.project(SandboxDirectedLanes.route_lane_point(nodes,nodes.size()-2,1.0))
	var target: Vector2=shuttle_point(from) if travel["arrival_policy"]==SHUTTLE else point(from)
	return screen+(target-lane_end)*weight

static func alight_start(from: String) -> Vector2:
	return point(from)+normal(from)*DOOR_CLEARANCE

static func shuttle_point(from: String) -> Vector2:
	return point(from)-SandboxAlightGeometry.tangent({"from":from})*36.0
