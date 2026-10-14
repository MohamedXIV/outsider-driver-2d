class_name IsoProjection
extends RefCounted

# One fixed 2D axonometric projection shared by road logic and drawing.
# The exact look is intentionally configurable before production sprite authoring.
const TILE_WIDTH: float = 96.0
const TILE_HEIGHT: float = 56.0
const LEVEL_HEIGHT: float = 84.0


static func project(world: Vector3) -> Vector2:
	return Vector2(
		(world.x - world.z) * TILE_WIDTH * 0.5,
		(world.x + world.z) * TILE_HEIGHT * 0.5 - world.y * LEVEL_HEIGHT
	)


static func ground(x: float, z: float) -> Vector2:
	return project(Vector3(x, 0.0, z))


# One shared road footprint for drawing and geometric validation.
static func road_quad(a: Vector3, b: Vector3, width: float) -> PackedVector2Array:
	var travel: Vector2 = Vector2(b.x - a.x, b.z - a.z)
	if travel.length_squared() < 0.000001:
		return PackedVector2Array()
	var perpendicular: Vector2 = Vector2(-travel.y, travel.x).normalized() * width * 0.5
	return PackedVector2Array([
		project(Vector3(a.x + perpendicular.x, a.y, a.z + perpendicular.y)),
		project(Vector3(b.x + perpendicular.x, b.y, b.z + perpendicular.y)),
		project(Vector3(b.x - perpendicular.x, b.y, b.z - perpendicular.y)),
		project(Vector3(a.x - perpendicular.x, a.y, a.z - perpendicular.y))
	])
