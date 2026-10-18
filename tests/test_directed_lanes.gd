extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	assert(SandboxDirectedLanes.lane_count("clinic","docks")==1)
	assert(SandboxDirectedLanes.lane_count("docks","clinic")==1)
	assert(SandboxDirectedLanes.lane_count("quay_gate","freight_cross")==2)
	assert(SandboxDirectedLanes.lane_count("freight_cross","quay_gate")==2)
	assert(SandboxDirectedLanes.lane_count("depot","civic")==0)
	assert(not SandboxDirectedLanes.valid_lane("docks","clinic",1))
	assert(not SandboxDirectedLanes.valid_lane("quay_gate","freight_cross",-1))
	assert(SandboxDirectedLanes.lane_point("clinic","docks",.5,8)==Vector3.INF)
	var a: String="clinic"
	var b: String="docks"
	var centre: Vector3=SandboxRoads.sample_edge(a,b,.5)
	var p: Vector3=SandboxDirectedLanes.lane_point(a,b,.5)
	var rev: Vector3=SandboxDirectedLanes.lane_point(b,a,.5)
	var lateral: Vector2=Vector2(p.x-centre.x,p.z-centre.z)
	var reverse_lateral: Vector2=Vector2(rev.x-centre.x,rev.z-centre.z)
	assert(lateral.length()>25 and lateral.dot(reverse_lateral)<-100,
			"Real directed lanes must occupy opposite world-metric road sides")
	assert(is_equal_approx(p.y,centre.y) and is_equal_approx(rev.y,centre.y))
	var inside: Vector3=SandboxDirectedLanes.lane_point("freight_cross","quay_gate",.35,0)
	var outer: Vector3=SandboxDirectedLanes.lane_point("freight_cross","quay_gate",.35,1)
	assert(inside.distance_to(outer)>45,"Two lanes heading same direction must be distinct")
	assert(is_equal_approx(inside.y,outer.y))
	assert(inside.is_finite() and outer.is_finite())
	var world: SandboxWorld=SandboxWorld.new(9)
	var offered: Dictionary={}
	for candidate in world.open_offers():
		if candidate.get("origin","")=="garage" and SandboxPassengerAlight.applicable(candidate):
			offered=candidate
			break
	assert(not offered.is_empty() and world.accept(str(offered["id"])))
	assert(world.advance(world.remaining_minutes))
	assert(not world.is_travelling() and world.player_district=="clinic")
	var before: Dictionary=world.snapshot()
	var parked_screen: Vector2=SandboxDirectedLanes.taxi_screen(world,0)
	var actual_centre: Vector2=SandboxIsoPresentation.project(world.player_position())
	assert(parked_screen.distance_to(actual_centre)>1.0,
			"Parked clinic taxi must inherit the actual inbound directed lane")
	assert(world.snapshot()==before and world.events.filter(func(e: Dictionary)->bool:
		return e.get("kind","")=="fare_settled" and e.get("subject","")==offered["id"]).size()==1,
		"Lane rendering must not change one legitimate fare or world ownership")
	var second: SandboxWorld=SandboxWorld.new(9)
	assert(second.reposition("docks"))
	assert(SandboxDirectedLanes.taxi_screen(second,.1).is_finite())
	assert(SandboxRoads.path_minutes(["clinic","docks"])==SandboxRoads.edge_minutes("clinic","docks"))
	print("DIRECTED_LANES_PASS world-metric opposite lanes, four-lane arterial, real taxi arrival, unchanged fares")
	quit()
