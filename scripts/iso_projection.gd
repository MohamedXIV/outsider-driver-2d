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
