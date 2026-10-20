extends SceneTree
func _initialize() -> void:
	var records: Array[Dictionary]=[]
	for key in SandboxDirectedLanes.ROAD_PROFILES:
		var nodes: PackedStringArray=str(key).split("|")
		var minimum: float=INF
		var maximum: float=0.0
		for sample in range(1,100):
			var fraction: float=float(sample)/100.0
			var a: Vector2=SandboxIsoPresentation.project(SandboxDirectedLanes.lane_point(nodes[0],nodes[1],fraction))
			var b: Vector2=SandboxIsoPresentation.project(SandboxDirectedLanes.lane_point(nodes[1],nodes[0],1.0-fraction))
			var tangent: Vector2=SandboxIsoPresentation.project(SandboxRoads.sample_edge(nodes[0],nodes[1],fraction+.001))-SandboxIsoPresentation.project(SandboxRoads.sample_edge(nodes[0],nodes[1],fraction-.001))
			var separation: float=absf((a-b).dot(tangent.normalized().orthogonal()))
			minimum=minf(minimum,separation);maximum=maxf(maximum,separation)
		records.append({"road":key,"minimum_opposing_lane_clearance":minimum,"maximum":maximum,"visible_body_width":13.0,"physical_fit":minimum>=17.0})
	print(JSON.stringify(records,"  "))
	quit()
