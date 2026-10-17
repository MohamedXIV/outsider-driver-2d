class_name SandboxBridgePresentation
extends RefCounted

# Presentation geometry sampled from the legal graph, never new road links.
# Ground carriageways remain clear of pier footings at apparent crossings.
static func footing_clear(at: Vector2) -> bool:
	for key in SandboxCityData.EDGES:
		var pair: PackedStringArray=str(key).split("|")
		if SandboxRoads.map_position(pair[0]).y>0 or SandboxRoads.map_position(pair[1]).y>0: continue
		var previous: Vector2=SandboxCityView.project(SandboxRoads.sample_edge(pair[0],pair[1],0.0))
		for i in range(1,65):
			var next: Vector2=SandboxCityView.project(SandboxRoads.sample_edge(pair[0],pair[1],float(i)/64.0))
			if Geometry2D.get_closest_point_to_segment(at,previous,next).distance_to(at)<31.0: return false
			previous=next
	return true

static func thickness(height: float) -> float:
	return clampf(height*.24,0.0,6.0)

static func supports(a: String,b: String) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for i in range(5,45,7):
		var phase: float=float(i)/48.0
		var p: Vector3=SandboxRoads.sample_edge(a,b,phase)
		if p.y<80.0: continue
		var next: Vector3=SandboxRoads.sample_edge(a,b,phase+.01)
		var ground: Vector3=Vector3(p.x,0,p.z)
		next.y=0.0
		var normal: Vector2=(SandboxCityView.project(next)-SandboxCityView.project(ground)).normalized().orthogonal()
		var feet: Array[Vector2]=[]
		var caps: Array[Vector2]=[]
		for side in [-1,1]:
			feet.append(SandboxCityView.project(ground)+normal*float(side)*18.0)
			caps.append(SandboxCityView.project(p)+normal*float(side)*18.0+Vector2(0,5))
		if not footing_clear(feet[0]) or not footing_clear(feet[1]): continue
		result.append({"feet":feet,"caps":caps,"height":p.y})
	return result

static func paint_structure(canvas: Node2D,a: String,b: String) -> void:
	var shadows: PackedVector2Array=[]
	for i in range(49):
		var p: Vector3=SandboxRoads.sample_edge(a,b,float(i)/48.0)
		p.y=0.0;shadows.append(SandboxCityView.project(p)+Vector2(5,7))
	canvas.draw_polyline(shadows,Color(.025,.035,.04,.45),36,true)
	# Retaining faces rise continuously from the actual ramp toe. Their height
	# comes from the same smooth elevation profile as the moving taxi.
	for i in range(48):
		var p: Vector3=SandboxRoads.sample_edge(a,b,float(i)/48.0)
		var q: Vector3=SandboxRoads.sample_edge(a,b,float(i+1)/48.0)
		if maxf(p.y,q.y)>80.0 or is_equal_approx(p.y,q.y): continue
		var ground_p: Vector3=Vector3(p.x,0,p.z)
		var ground_q: Vector3=Vector3(q.x,0,q.z)
		var normal: Vector2=(SandboxCityView.project(ground_q)-SandboxCityView.project(ground_p)).normalized().orthogonal()
		for side in [-1,1]:
			var offset: Vector2=normal*float(side)*14.0
			canvas.draw_colored_polygon(PackedVector2Array([
				SandboxCityView.project(ground_p)+offset,SandboxCityView.project(ground_q)+offset,
				SandboxCityView.project(q)+offset,SandboxCityView.project(p)+offset]),Color("526761"))
	for station in supports(a,b):
		for i in range(2):
			var foot: Vector2=station["feet"][i]
			var cap: Vector2=station["caps"][i]
			canvas.draw_rect(Rect2(foot-Vector2(7,3),Vector2(14,6)),Color("334b49"))
			canvas.draw_line(foot,cap,Color("8b9688"),7.0,true)
			canvas.draw_line(foot+Vector2(3,0),cap+Vector2(3,0),Color("4e625c"),2.0,true)
		canvas.draw_line(station["caps"][0],station["caps"][1],Color("687b70"),6.0,true)
