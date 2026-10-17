class_name SandboxStreetRouteBinding
extends RefCounted

# The authored Patchworks crossing lies ON the actual ground-level taxi
# road, not at an unrelated point painted over the city. The main taxi still
# uses SandboxRoads' authoritative route until a future full lane-physics pass.
const FROM: String = "garage"
const TO: String = "margin_gate"
const CROSS_FRACTION: float = 0.35
const CROSSING_ID: String = "patchworks:garage-feeder-zebra"

# The zebra is a single physical location, but route progress has opposite
# fractions depending on which endpoint the taxi is approaching from.
static func crossing_fraction(from_node: String, to_node: String) -> float:
	if from_node==FROM and to_node==TO:
		return CROSS_FRACTION
	if from_node==TO and to_node==FROM:
		return 1.0-CROSS_FRACTION
	return -1.0

static func on_edge(world: SandboxWorld) -> bool:
	return world.is_travelling() and world.route_segment < world.route_nodes.size()-1 \
			and crossing_fraction(world.route_nodes[world.route_segment],
				world.route_nodes[world.route_segment+1])>=0.0

static func grounded() -> bool:
	return SandboxRoads.connected(FROM,TO) and \
			absf(SandboxRoads.sample_edge(FROM,TO,CROSS_FRACTION).y)<0.01

static func crossing_position() -> Vector2:
	return SandboxCityView.project(SandboxRoads.sample_edge(FROM,TO,CROSS_FRACTION))

static func street_transform() -> Transform2D:
	var before: Vector2=SandboxCityView.project(SandboxRoads.sample_edge(FROM,TO,CROSS_FRACTION-0.005))
	var after: Vector2=SandboxCityView.project(SandboxRoads.sample_edge(FROM,TO,CROSS_FRACTION+0.005))
	var heading: float=(after-before).angle()
	var origin: Vector2=crossing_position()-Vector2(SandboxStreetModule.CROSS_X,
			SandboxStreetModule.LANE_Y).rotated(heading)
	return Transform2D(heading,origin)

static func approaching(world: SandboxWorld) -> bool:
	if not on_edge(world) or not grounded():
		return false
	var from_node: String=world.route_nodes[world.route_segment]
	var to_node: String=world.route_nodes[world.route_segment+1]
	var minutes: int=SandboxRoads.edge_minutes(from_node,to_node)
	if minutes<=1:
		return false
	var threshold: float=crossing_fraction(from_node,to_node)
	var before: float=float(world.route_edge_elapsed)/float(minutes)
	var after: float=float(world.route_edge_elapsed+1)/float(minutes)
	return before<threshold and after>=threshold

static func in_neighborhood(world: SandboxWorld) -> bool:
	if world.player_district==FROM and not world.is_travelling():
		return true
	if not on_edge(world) or not grounded():
		return false
	var from_node: String=world.route_nodes[world.route_segment]
	var to_node: String=world.route_nodes[world.route_segment+1]
	return float(world.route_edge_elapsed)/float(SandboxRoads.edge_minutes(from_node,to_node)) \
			<=crossing_fraction(from_node,to_node)+0.10

static func taxi_occupies_crosswalk(world: SandboxWorld) -> bool:
	if not on_edge(world) or not grounded() or not world.route_hold_id.is_empty():
		return false
	var from_node: String=world.route_nodes[world.route_segment]
	var to_node: String=world.route_nodes[world.route_segment+1]
	var at: float=float(world.route_edge_elapsed)/float(SandboxRoads.edge_minutes(from_node,to_node))
	return absf(at-crossing_fraction(from_node,to_node))<=0.065
