extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Real eligible 3-node path: two genuinely authored profiled edges meet
	# at the medical clinic, without inventing road connectivity.
	var nodes: Array[String]=["docks","clinic","basin_turn"]
	assert(SandboxRoads.valid_path(nodes))
	assert(SandboxDirectedLanes.valid_lane("docks","clinic",0))
	assert(SandboxDirectedLanes.valid_lane("clinic","basin_turn",0))
	var controls: PackedVector3Array=SandboxDirectedLanes.junction_controls(nodes[0],nodes[1],nodes[2])
	assert(controls.size()==4)
	var last: Vector3=SandboxDirectedLanes.route_point(nodes,0,1.0)
	var first: Vector3=SandboxDirectedLanes.route_point(nodes,1,0.0)
	assert(last.is_finite() and first.is_finite() and last.distance_to(first)<.0001,
			"World minute segment switch cannot teleport taxi across lane offsets")
	var last_heading: float=SandboxDirectedLanes.route_heading(nodes,0,1.0)
	var first_heading: float=SandboxDirectedLanes.route_heading(nodes,1,0.0)
	assert(absf(angle_difference(last_heading,first_heading))<.05,
			"World segment switch must not snap taxi yaw")
	var start: Vector3=SandboxDirectedLanes.route_point(nodes,0,1.0-SandboxDirectedLanes.TURN_FRACTION)
	var finish: Vector3=SandboxDirectedLanes.route_point(nodes,1,SandboxDirectedLanes.TURN_FRACTION)
	assert(start.distance_to(controls[0])<.001)
	assert(finish.distance_to(controls[3])<.001)
	var previous: Vector3=start
	for i in range(1,301):
		var fraction: float=float(i)/300.0
		var point: Vector3=SandboxDirectedLanes.junction_point(nodes[0],nodes[1],nodes[2],fraction)
		assert(point.is_finite())
		assert(point.distance_to(previous)<30.0, "A turn cannot jump from one sampling frame to the next")
		previous=point
	assert(SandboxDirectedLanes.route_point(nodes,0,0.0).is_finite())
	assert(SandboxDirectedLanes.junction_point("docks","clinic","docks",.5)==Vector3.INF,
			"Unsupported U-turn must not fabricate a junction connector")
	assert(SandboxDirectedLanes.junction_point("garage","clinic","basin_turn",.5)==Vector3.INF,
			"Disconnected geometry must not create a shortcut")
	assert(SandboxDirectedLanes.route_point(nodes,-1,.5)==Vector3.INF)
	assert(SandboxDirectedLanes.route_point(nodes,1,NAN)==Vector3.INF)
	# Actual World route/score still owns timing, money and progress.
	var world: SandboxWorld=SandboxWorld.new(9)
	var before: Dictionary=world.snapshot()
	var calculated: Vector3=SandboxDirectedLanes.route_point(nodes,0,.95)
	assert(calculated.is_finite() and world.snapshot()==before)
	var old_minutes: int=SandboxRoads.path_minutes(nodes)
	assert(old_minutes==SandboxRoads.edge_minutes("docks","clinic")+SandboxRoads.edge_minutes("clinic","basin_turn"))
	print("LANE_TURN_CONNECTOR_PASS seamless directed-lane junction, finite cubic arc, yaw continuity, world invariance")
	quit()
