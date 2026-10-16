class_name SandboxStreetRouteBinding
extends RefCounted

# The authored Patchworks crossing lies ON the actual ground-level taxi
# road, not at an unrelated point painted over the city. The main taxi still
# uses SandboxRoads' authoritative route until a future full lane-physics pass.
const FROM: String = "garage"
const TO: String = "margin_gate"
const CROSS_FRACTION: float = 0.35
const CROSSING_ID: String = "patchworks:garage-feeder-zebra"

static func on_edge(world: SandboxWorld) -> bool:
	return world.is_travelling() and world.route_segment < world.route_nodes.size()-1 \
			and world.route_nodes[world.route_segment]==FROM \
			and world.route_nodes[world.route_segment+1]==TO

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
	var minutes: int=SandboxRoads.edge_minutes(FROM,TO)
	if minutes<=1:
		return false
	var before: float=float(world.route_edge_elapsed)/float(minutes)
	var after: float=float(world.route_edge_elapsed+1)/float(minutes)
	return before<CROSS_FRACTION and after>=CROSS_FRACTION

static func in_neighborhood(world: SandboxWorld) -> bool:
	if world.player_district==FROM and not world.is_travelling():
		return true
	if not on_edge(world) or not grounded():
		return false
	return float(world.route_edge_elapsed)/float(SandboxRoads.edge_minutes(FROM,TO))<=CROSS_FRACTION+0.10

static func taxi_occupies_crosswalk(world: SandboxWorld) -> bool:
	if not on_edge(world) or not grounded() or not world.route_hold_id.is_empty():
		return false
	var at: float=float(world.route_edge_elapsed)/float(SandboxRoads.edge_minutes(FROM,TO))
	return absf(at-CROSS_FRACTION)<=0.065
