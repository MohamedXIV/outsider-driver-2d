class_name SandboxVehicleParking
extends RefCounted

# The completed real journey, not a remembered CanvasItem, owns its parked
# pose. Keep this record through the next trip so its departure has an anchor.
static func terminal(world: SandboxWorld,stop: String) -> Dictionary:
	var state: Dictionary=world.vehicle_execution.get("player",{})
	if state.is_empty(): return {}
	var nodes: Array[String]=SandboxVehicleExecution.nodes_of(state)
	if nodes.size()<2 or nodes.back()!=stop or float(state["progress"])+SandboxVehicleExecution.EPSILON<float(SandboxRoads.path_minutes(nodes)): return {}
	return state

static func screen(world: SandboxWorld,stop: String) -> Vector2:
	var ending: Dictionary=terminal(world,stop)
	if not ending.is_empty(): return Vector2(float(ending["x"]),float(ending["y"]))
	var parked: Dictionary=world.vehicle_parking.get("player",{})
	if parked.get("stop","")!=stop: return Vector2.INF
	return Vector2(float(parked["x"]),float(parked["y"]))

static func from_snapshot(value: Dictionary,stop: String) -> Vector2:
	var parked: Dictionary=value.get("vehicle_parking",{}).get("player",{})
	if parked.get("stop","")==stop: return Vector2(float(parked["x"]),float(parked["y"]))
	return SandboxDirectedLanes.parked_screen_from_events(value["events"],stop)

static func capture_player(world: SandboxWorld,state: Dictionary) -> void:
	if world.is_travelling() or terminal(world,world.player_district).is_empty(): return
	var nodes: Array[String]=SandboxVehicleExecution.nodes_of(state)
	var parent: Dictionary={}
	for index in range(world.events.size()-1,-1,-1):
		var event: Dictionary=world.events[index]
		if event["kind"] in ["fare_settled","reposition_arrived"]:
			parent=event;break
	if parent.is_empty() or parent["minute"]!=world.minute or parent["detail"].get("to","")!=world.player_district: return
	var parked: Dictionary={"source":state["source"],"parent_event":parent["id"],"stop":world.player_district,
		"from":nodes[nodes.size()-2],"x":state["x"],"y":state["y"],
		"height":SandboxRoads.map_position(world.player_district).y,"heading":state["heading"],"minute":world.minute}
	if not str(state.get("arrival_policy","")).is_empty(): parked["arrival_policy"]=state["arrival_policy"]
	world.vehicle_parking["player"]=parked
	world._record("vehicle_parked","player",parked)

static func valid_snapshot(value: Dictionary) -> bool:
	var registry: Variant=value.get("vehicle_parking",{})
	if not registry is Dictionary or registry.size()>1 or (not registry.is_empty() and not registry.has("player")): return false
	var expected: Dictionary={}
	var seen: Dictionary={}
	var source: String=""
	var entered: Dictionary={}
	var leg: Dictionary={}
	for event in value["events"]:
		var detail: Variant=event.get("detail",{})
		if event.get("kind","")=="reposition": source=str(event["id"])
		elif event.get("kind","")=="offer_accepted": source="fare:"+str(event["subject"])
		elif event.get("kind","")=="route_segment_completed": leg=event
		elif event.get("kind","")=="vehicle_execution_entered" and event.get("subject","")=="player":
			if not detail is Dictionary: return false
			entered[str(detail.get("source",""))]=str(detail.get("arrival_policy",""))
		elif event.get("kind","")=="vehicle_parked" and event.get("subject","")=="player":
			if not detail is Dictionary: return false
			for key in ["source","parent_event","stop","from"]:
				if not detail.get(key) is String: return false
			for key in ["x","y","height","heading","minute"]:
				if not (detail.get(key) is int or detail.get(key) is float) or not is_finite(float(detail[key])): return false
			if detail["source"]!=source or not entered.has(source) or not seen.has(detail["parent_event"]): return false
			var parent: Dictionary=seen[detail["parent_event"]]
			if not parent.get("detail",{}) is Dictionary or parent["detail"].get("to","")!=detail["stop"] \
					or parent["minute"]!=event["minute"] or detail["minute"]!=event["minute"]: return false
			if source.begins_with("fare:"):
				if parent["kind"]!="fare_settled" or source!="fare:"+str(parent["subject"]): return false
			elif parent["kind"]!="reposition_arrived" or parent["subject"]!="player": return false
			if leg.is_empty() or leg["minute"]!=parent["minute"] or leg["detail"].get("from","")!=detail["from"] or leg["detail"].get("to","")!=detail["stop"]: return false
			if not SandboxRoads.connected(detail["from"],detail["stop"]) or not SandboxRoads.DISTRICTS.has(detail["stop"]) \
					or absf(float(detail["heading"]))>PI or float(detail["height"])!=SandboxRoads.map_position(detail["stop"]).y: return false
			var nodes: Array[String]=[detail["from"],detail["stop"]]
			var policy: String=str(detail.get("arrival_policy",""))
			if policy!=entered[source] or (not policy.is_empty() and SandboxVehicleBays.policy(nodes)!=policy): return false
			var point: Vector2=SandboxVehicleExecution.point({"nodes":nodes,"arrival_policy":policy},float(SandboxRoads.path_minutes(nodes)))
			if point.distance_to(Vector2(float(detail["x"]),float(detail["y"])))>.5: return false
			expected=detail
		seen[str(event.get("id",""))]=event
	return registry.get("player",{})==expected
