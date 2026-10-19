extends SceneTree
func _initialize() -> void:
	for key in SandboxDirectedLanes.ROAD_PROFILES:
		var nodes: PackedStringArray=str(key).split("|")
		var width: float=SandboxDirectedLanes.screen_road_width(nodes[0],nodes[1])
		for sample in range(1,100):
			var fraction: float=float(sample)/100.0
			var centre: Vector2=SandboxIsoPresentation.project(SandboxRoads.sample_edge(nodes[0],nodes[1],fraction))
			var tangent: Vector2=SandboxIsoPresentation.project(SandboxRoads.sample_edge(nodes[0],nodes[1],fraction+.001))-SandboxIsoPresentation.project(SandboxRoads.sample_edge(nodes[0],nodes[1],fraction-.001))
			var normal: Vector2=tangent.normalized().orthogonal()
			var previous: Vector2=SandboxIsoPresentation.project(SandboxDirectedLanes.lane_point(nodes[1],nodes[0],1.0-fraction))
			for lane in range(SandboxDirectedLanes.lane_count(nodes[0],nodes[1])):
				var current: Vector2=SandboxIsoPresentation.project(SandboxDirectedLanes.lane_point(nodes[0],nodes[1],fraction,lane))
				assert(absf((current-previous).dot(normal))>=17.0,"Visible vehicle width plus clearance must fit")
				assert(absf((current-centre).dot(normal))+6.5+4.0<=width*.5+.001,"The full vehicle must remain on painted asphalt")
				previous=current
	print("VEHICLE_LANE_CLEARANCE_PASS all authored profiles, opposing and same-direction flows, visible footprint and painted envelope")
	quit()
