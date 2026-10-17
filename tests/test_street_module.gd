extends SceneTree

func _initialize() -> void:
	var points: PackedVector2Array=SandboxStreetModule.waypoints()
	assert(points.size()==4)
	assert(points[0]==SandboxStreetModule.START)
	assert(points[points.size()-1]==SandboxStreetModule.SITE)
	assert(SandboxStreetModule.crossing_finished(0.9))
	var clear_y: float=SandboxStreetModule.crossing_clear_y()
	assert(clear_y>SandboxStreetModule.ROAD.end.y+SandboxStreetModule.PEDESTRIAN_RADIUS,
			"Clearance must include the entire walker collider")
	assert(clear_y<SandboxStreetModule.SOUTH_Y,
			"Walker should be clear before reaching the south sidewalk center")
	assert(not SandboxStreetModule.crossing_clear(
			Vector2(SandboxStreetModule.CROSS_X,clear_y-0.1)))
	assert(SandboxStreetModule.crossing_clear(
			Vector2(SandboxStreetModule.CROSS_X,clear_y)))
	assert(not SandboxStreetModule.crossing_finished(
			SandboxStreetModule.progress_of(Vector2(SandboxStreetModule.CROSS_X,clear_y-0.1))))
	assert(SandboxStreetModule.crossing_finished(
			SandboxStreetModule.progress_of(Vector2(SandboxStreetModule.CROSS_X,clear_y+0.1))))
	var crossing: Vector2=SandboxStreetModule.position_at(
		SandboxStreetModule.progress_of(Vector2(SandboxStreetModule.CROSS_X,355.0)))
	assert(is_equal_approx(crossing.x,SandboxStreetModule.CROSS_X))
	assert(crossing.y>SandboxStreetModule.NORTH_Y and crossing.y<SandboxStreetModule.SOUTH_Y)
	for phase in [0.0,0.16,0.35,0.47,0.62,0.83,1.0]:
		var position: Vector2=SandboxStreetModule.position_at(phase)
		assert(absf(SandboxStreetModule.progress_of(position)-phase)<0.001,
				"Local module geometry/progress invertibility")
	assert(SandboxStreetModule.NORTH_SIDEWALK.end.y<SandboxStreetModule.SOUTH_SIDEWALK.position.y)
	assert(SandboxStreetModule.ROAD.has_point(Vector2(SandboxStreetModule.CROSS_X,355)))
	assert(SandboxStreetModule.FRONTAGES.size()>=3)
	assert(SandboxStreetModule.EAST_BLOCK.position.x==SandboxStreetModule.NORTH_SIDEWALK.end.x)
	assert(SandboxStreetModule.EAST_CROSS_X>SandboxStreetModule.T_BRANCH.end.x)
	assert(SandboxStreetModule.T_BRANCH.end.y==SandboxStreetModule.EAST_BLOCK.position.y)
	print("STREET_MODULE_PASS shared sidewalk, lane, crossing, block rectangles and offscreen spatial anchors")
	quit()
