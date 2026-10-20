class_name SandboxVehicleCrossings
extends RefCounted

# Read-only native approach/queue evidence. Existing World pedestrian and yield
# ledgers remain the authority; no occupancy, clock or reservation is duplicated.
static func context(world: SandboxWorld) -> Dictionary:
	return {"vehicle_execution":world.vehicle_execution,"residents":world.residents,"route_hold_id":world.route_hold_id}

static func _state(value: Dictionary,id: String) -> Dictionary:
	var registry: Variant=value.get("vehicle_execution",{})
	if not registry is Dictionary: return {}
	var state: Variant=registry.get(id,{})
	if not state is Dictionary or not state.get("native") is bool or not state.get("nodes") is Array: return {}
	if not state.get("source") is String or str(state["source"]).is_empty(): return {}
	var retained: bool=not bool(state["native"]) and _held(value,id) and state.has("handoff_progress")
	if not bool(state["native"]) and not retained: return {}
	for key in ["progress","speed","x","y","heading"]:
		if not (state.get(key) is float or state.get(key) is int) or not is_finite(float(state[key])): return {}
	if float(state["progress"])<0.0 or float(state["speed"])<0.0: return {}
	if retained:
		for key in ["handoff_progress","handoff_x","handoff_y"]:
			if not (state.get(key) is float or state.get(key) is int) or not is_finite(float(state[key])): return {}
		if absf(float(state["progress"])-float(state["handoff_progress"]))>.000001 or absf(float(state["x"])-float(state["handoff_x"]))>.001 or absf(float(state["y"])-float(state["handoff_y"]))>.001: return {}
	var nodes: Array[String]=[]
	for node in state["nodes"]:
		if not node is String: return {}
		nodes.append(node)
	return state if SandboxRoads.valid_path(nodes) else {}

static func _held(value: Dictionary,id: String) -> bool:
	if id=="player": return value.get("route_hold_id","")==SandboxStreetRouteBinding.CROSSING_ID
	var residents: Variant=value.get("residents",[])
	if not residents is Array: return false
	for npc in residents:
		if npc is Dictionary and npc.get("id","")==id:
			return npc.get("transit_method","")=="shuttle" and npc.get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID
	return false

static func native_approach(value: Dictionary,id: String) -> bool:
	var state: Dictionary=_state(value,id)
	if state.is_empty() or float(state["speed"])>.05: return false
	var segment: Dictionary=SandboxVehicleExecution.segment(state,float(state["progress"]))
	if segment.is_empty(): return false
	var crossing: float=SandboxStreetRouteBinding.crossing_fraction(segment["from"],segment["to"])
	if crossing<0.0 or float(segment["fraction"])>=crossing: return false
	var remaining: float=(crossing-float(segment["fraction"]))*float(segment["duration"])
	var reason: String="world_crossing" if _held(value,id) else str(state.get("reason",""))
	if reason in ["pedestrian","world_crossing"] and remaining<=SandboxVehicleExecution.LOOKAHEAD_MINUTES:
		return true
	if reason not in ["vehicle","world_crossing"]: return false
	# A following real vehicle may stop behind an already held real leader
	# before the integer approach window. Retain its own independent yield.
	for leader_id in value.get("vehicle_execution",{}):
		if leader_id==id or not _held(value,str(leader_id)): continue
		var leader: Dictionary=_state(value,str(leader_id))
		if leader.is_empty(): continue
		var ahead: Dictionary=SandboxVehicleExecution.segment(leader,float(leader["progress"]))
		if ahead.get("from","")!=segment["from"] or ahead.get("to","")!=segment["to"]: continue
		var gap: float=(float(ahead["fraction"])-float(segment["fraction"]))*float(segment["duration"])
		var point: Vector2=Vector2(float(state["x"]),float(state["y"]))
		var front: Vector2=Vector2(float(leader["x"]),float(leader["y"]))
		if gap>0.0 and gap<=SandboxVehicleExecution.LOOKAHEAD_MINUTES and point.distance_to(front)<=SandboxVehicleKinematics.BODY_SIZE.x+2.0*SandboxVehicleKinematics.CLEARANCE+.5:
			return true
	return false

static func clearance(world: SandboxWorld,travel: Dictionary,at: float,position: Vector2) -> float:
	var reserved: bool=false
	for npc in world.residents:
		var trip: Dictionary=npc.get("local_pedestrian_trip",{})
		if trip.get("site","")==SandboxLocalPedestrianTrip.PATCHWORKS_PARTS and trip.get("status","") in ["walking","offscreen"] and trip.get("crossing_state","") in ["reserved","entered"]:
			reserved=true;break
	if not reserved: return INF
	var segment: Dictionary=SandboxVehicleExecution.segment({"nodes":SandboxVehicleExecution.geometry_nodes(travel)},at)
	if segment.is_empty(): return INF
	var crossing: float=SandboxStreetRouteBinding.crossing_fraction(segment["from"],segment["to"])
	if crossing<0.0 or float(segment["fraction"])>=crossing: return INF
	var stop: float=float(segment["prior"])+crossing*float(segment["duration"])
	# The zebra paint is 26 units wide along the road. Reserve the whole
	# vehicle footprint plus the same physical clearance before that paint.
	return maxf(0.0,position.distance_to(SandboxVehicleExecution.point(travel,stop))-SandboxVehicleKinematics.BODY_SIZE.x*.5-13.0-SandboxVehicleKinematics.CLEARANCE)

static func native_occupies(value: Dictionary,id: String) -> bool:
	var state: Dictionary=_state(value,id)
	if state.is_empty() or not SandboxStreetRouteBinding.grounded(): return false
	var segment: Dictionary=SandboxVehicleExecution.segment(state,float(state["progress"]))
	if segment.is_empty() or SandboxStreetRouteBinding.crossing_fraction(segment["from"],segment["to"])<0.0: return false
	var half: Vector2=SandboxVehicleKinematics.BODY_SIZE*.5
	var pose: Transform2D=SandboxStreetRouteBinding.street_transform().affine_inverse()*Transform2D(float(state["heading"]),Vector2(float(state["x"]),float(state["y"])))
	var corners: PackedVector2Array=[]
	for corner in [-half,Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)]: corners.append(pose*corner)
	var footprint: Rect2=Rect2(corners[0],Vector2.ZERO)
	for corner in corners: footprint=footprint.expand(corner)
	var paint: Rect2=Rect2(SandboxStreetModule.CROSS_X-13.0,SandboxStreetModule.ROAD.position.y,26.0,SandboxStreetModule.ROAD.size.y)
	return footprint.intersects(paint,true)

static func hold_evidence(value: Dictionary) -> Dictionary:
	var state: Dictionary=_state(value,"player")
	if state.is_empty() or float(state["speed"])>.05: return {}
	var segment: Dictionary=SandboxVehicleExecution.segment(state,float(state["progress"]))
	if segment.is_empty(): return {}
	var crossing: float=SandboxStreetRouteBinding.crossing_fraction(segment["from"],segment["to"])
	if crossing<0.0 or float(segment["fraction"])>=crossing: return {}
	return {"source":state["source"],"progress":state["progress"],"x":state["x"],"y":state["y"],"heading":state["heading"]}

static func held_player(value: Dictionary) -> bool:
	var state: Dictionary=_state(value,"player")
	if state.is_empty() or float(state["speed"])>.05: return false
	var segment: Dictionary=SandboxVehicleExecution.segment(state,float(state["progress"]))
	if segment.is_empty(): return false
	var crossing: float=SandboxStreetRouteBinding.crossing_fraction(segment["from"],segment["to"])
	if crossing<0.0 or float(segment["fraction"])>=crossing: return false
	var events: Variant=value.get("events",[])
	if not events is Array: return false
	for index in range(events.size()-1,-1,-1):
		var event: Variant=events[index]
		if not event is Dictionary or event.get("kind","")!="taxi_yield_started" or event.get("subject","")!="player": continue
		var detail: Variant=event.get("detail",{})
		if not detail is Dictionary: return false
		var proof: Variant=detail.get("execution",{})
		if not proof is Dictionary or proof.get("source","")!=state["source"]: return false
		for key in ["progress","x","y","heading"]:
			if not (proof.get(key) is float or proof.get(key) is int) or not is_finite(float(proof[key])): return false
			var difference: float=absf(angle_difference(float(proof[key]),float(state[key]))) if key=="heading" else absf(float(proof[key])-float(state[key]))
			if difference>.0001: return false
		return true
	return false

static func has_hold_evidence(value: Dictionary) -> bool:
	var events: Variant=value.get("events",[])
	if not events is Array: return false
	for index in range(events.size()-1,-1,-1):
		var event: Variant=events[index]
		if not event is Dictionary or event.get("kind","")!="taxi_yield_started" or event.get("subject","")!="player": continue
		var detail: Variant=event.get("detail",{})
		return detail is Dictionary and detail.has("execution")
	return false
