extends SceneTree

# Run: godot --headless --path . --script res://tests/test_core.gd
func _initialize() -> void:
	var ground: Vector2 = IsoProjection.project(Vector3(2, 0, 0))
	var elevated: Vector2 = IsoProjection.project(Vector3(2, 1, 0))
	assert(is_equal_approx(ground.x, elevated.x), "Elevation cannot change map x.")
	assert(is_equal_approx(ground.y - elevated.y, IsoProjection.LEVEL_HEIGHT), "Elevation projection incorrect.")

	var points: Array[Vector3] = [Vector3.ZERO, Vector3(1, 0, 0), Vector3(1, 1, 0)]
	var ride: TaxiRide = TaxiRide.new(points)
	ride.advance(-3.0)
	assert(ride.world_position() == Vector3.ZERO, "Negative delta moved the taxi.")
	ride.advance(10.0)
	assert(ride.is_finished(), "Route did not finish.")
	assert(ride.world_position() == Vector3(1, 1, 0), "Final waypoint mismatch.")
	ride.advance(1.0)
	assert(ride.world_position() == Vector3(1, 1, 0), "Completed ride moved.")
	print("P0 core checks passed")
	quit(0)
