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
	# Adjacent, genuinely connected profiled road lanes must not jump
	# across the junction when the canonical World changes route segment.
	var corridor: Array[String]=["docks","clinic","basin_turn"]
	assert(SandboxRoads.valid_path(corridor))
	assert(SandboxDirectedLanes.can_turn("docks","clinic","basin_turn"))
	var incoming: Vector3=SandboxDirectedLanes.route_lane_point(corridor,0,1.0)
	var outgoing: Vector3=SandboxDirectedLanes.route_lane_point(corridor,1,0.0)
	assert(incoming.is_finite() and incoming.distance_to(outgoing)<.001,
			"Actual lane joins must remain position-continuous across segment switch")
	var start_join: Vector3=SandboxDirectedLanes.route_lane_point(corridor,0,1.0-SandboxDirectedLanes.TURN_FRACTION)
	var end_join: Vector3=SandboxDirectedLanes.route_lane_point(corridor,1,SandboxDirectedLanes.TURN_FRACTION)
	assert(start_join.distance_to(SandboxDirectedLanes.lane_point("docks","clinic",
			1.0-SandboxDirectedLanes.TURN_FRACTION))<.001)
	assert(end_join.distance_to(SandboxDirectedLanes.lane_point("clinic","basin_turn",
			SandboxDirectedLanes.TURN_FRACTION))<.001)
	var in_heading: float=SandboxDirectedLanes.route_screen_heading(corridor,0,.9999)
	var out_heading: float=SandboxDirectedLanes.route_screen_heading(corridor,1,.0001)
	assert(absf(angle_difference(in_heading,out_heading))<.06,
			"Visual taxi steering must not snap when crossing a profiled junction")
	# A genuine shuttle's elapsed World minutes must sample these same
	# directed lanes, including the seamless junction transition.
	var join_minute: float=float(SandboxRoads.edge_minutes("docks","clinic"))
	var before_join: Vector3=SandboxDirectedLanes.route_point_at_minutes(
			corridor,join_minute-0.001)
	var at_join: Vector3=SandboxDirectedLanes.route_point_at_minutes(corridor,join_minute)
	var after_join: Vector3=SandboxDirectedLanes.route_point_at_minutes(
			corridor,join_minute+0.001)
	assert(before_join.distance_to(at_join)<1.0 and after_join.distance_to(at_join)<1.0,
			"World-minute shuttle presentation must not jump at a directed junction")
	assert(at_join.distance_to(incoming)<0.001)
	var full_duration: float=float(SandboxRoads.path_minutes(corridor))
	assert(SandboxDirectedLanes.route_point_at_minutes(corridor,join_minute,
			full_duration).distance_to(at_join)<0.001)
	assert(SandboxDirectedLanes.route_point_at_minutes(
			corridor,full_duration,full_duration).distance_to(
			SandboxDirectedLanes.route_lane_point(corridor,1,1.0))<0.001)
	var bad_nodes: Array[String]=["docks","docks"]
	assert(SandboxDirectedLanes.route_point_at_minutes(bad_nodes,1.0)==Vector3.INF)
	assert(SandboxDirectedLanes.route_point_at_minutes(corridor,1.0,0.0)==Vector3.INF)
	var single: Array[String]=["clinic","docks"]
	assert(SandboxDirectedLanes.route_lane_point(single,0,.5).distance_to(
			SandboxDirectedLanes.lane_point("clinic","docks",.5))<.001)
	assert(not SandboxDirectedLanes.can_turn("docks","clinic","docks"),
			"No invented U-turn on the opposite directed lane")
	assert(not SandboxDirectedLanes.can_turn("bridge_east","margin_gate","old_square"),
			"An unprofiled/elevated route must never receive a fake level-grade connector")
	assert(SandboxDirectedLanes.turn_connector_point("bridge_east","margin_gate","old_square",
			.5)==Vector3.INF)
	# The transition is a rendering-only projection, not a new trip or
	# event. Every checked World member, fare, and minute remains unchanged.
	assert(world.snapshot()==before)
	print("DIRECTED_LANES_PASS world-metric opposite lanes, four-lane arterial, real taxi arrival, unchanged fares")
	quit()
