extends SceneTree

# Run: godot --headless --path . --script res://tests/test_core.gd
func _initialize() -> void:
	var ground: Vector2 = IsoProjection.project(Vector3(2, 0, 0))
	var elevated: Vector2 = IsoProjection.project(Vector3(2, 1, 0))
	assert(is_equal_approx(ground.x, elevated.x), "Elevation cannot change map x.")
	assert(is_equal_approx(ground.y - elevated.y, IsoProjection.LEVEL_HEIGHT), "Elevation projection incorrect.")

	# An actual screen-space overlap must exist at the underpass.
	# Drawing the deck later is not enough if it projects away from the taxi.
	var deck: PackedVector2Array = IsoProjection.road_quad(
		Vector3(2, 1, -7), Vector3(2, 1, 7), 4.1
	)
	assert(Geometry2D.is_point_in_polygon(
		IsoProjection.project(Vector3(2, 0, 0)) + Vector2(0, -8), deck
	), "Projected bridge deck misses the taxi underpass.")
	assert(not Geometry2D.is_point_in_polygon(
		IsoProjection.project(Vector3(-10, 0, 0)), deck
	), "Bridge covers the route start unexpectedly.")

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
