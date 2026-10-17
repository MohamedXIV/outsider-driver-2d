class_name SandboxAlightGeometry
extends RefCounted

# A single authored Night Clinic curb-to-intake footprint. This is *not* a
# claim of universal sidewalks: the rest of the city awaits authored geometry.
const WALK_SPEED: float = 32.0
const BODY_RADIUS: float = 6.0
static func tangent(trip: Dictionary) -> Vector2:
	var from: String = str(trip.get("from", ""))
	if not SandboxRoads.connected(from, "clinic"): return Vector2.RIGHT
	var p: Vector3 = SandboxRoads.sample_edge(from, "clinic", 0.998)
	var q: Vector3 = SandboxRoads.sample_edge(from, "clinic", 1.0)
	var d: Vector2 = SandboxCityView.project(q) - SandboxCityView.project(p)
	return d.normalized() if d.length_squared() > 0.000001 else Vector2.RIGHT

static func start(trip: Dictionary) -> Vector2:
	var centre: Vector2 = SandboxCityView.project(SandboxRoads.map_position("clinic"))
	return centre + tangent(trip).orthogonal() * 30.0

static func goal(trip: Dictionary) -> Vector2:
	return start(trip) + tangent(trip).orthogonal() * 40.0 + tangent(trip) * 24.0

static func at(trip: Dictionary, fraction: float) -> Vector2:
	return start(trip).lerp(goal(trip), clampf(fraction, 0.0, 1.0))

static func progress(trip: Dictionary, at_position: Vector2) -> float:
	var a: Vector2 = start(trip)
	var d: Vector2 = goal(trip) - a
	return clampf((at_position - a).dot(d) / d.length_squared(), 0.0, 1.0)

static func valid_position(trip: Dictionary, point: Vector2) -> bool:
	var a: Vector2 = start(trip)
	var b: Vector2 = goal(trip)
	var t: float = progress(trip, point)
	return point.is_finite() and point.distance_to(a.lerp(b,t)) <= 9.0
