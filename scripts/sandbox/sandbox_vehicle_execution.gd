class_name SandboxVehicleExecution
extends RefCounted

# Bounded near-field execution belongs to World. Native bodies may report
# legal progress within a bounded two-minute execution horizon; they cannot complete a fare,
# change population or advance the city clock. Aggregate travel resumes from
# the same fractional progress when a body leaves the loaded corridor.
const EPSILON: float=0.00001
const LOOKAHEAD_MINUTES: float=2.0

static func trip(world: SandboxWorld,id: String) -> Dictionary:
	if world.vehicle_departures.has(id): return SandboxVehicleDepartures.trip(world,id)
	if id=="player":
		if not world.is_travelling(): return {}
		var base: float=float(world.route_edge_elapsed)
		for index in range(world.route_segment):
			base+=SandboxRoads.edge_minutes(world.route_nodes[index],world.route_nodes[index+1])
		var source: String="fare:"+world.active_offer_id
		if world.active_offer_id.is_empty():
			source=world.last_reposition_event_id
		return {"nodes":world.route_nodes.duplicate(),"base":base,"source":source,
			"arrival_policy":world.vehicle_execution.get(id,{}).get("arrival_policy",""),
			"incoming_node":world.vehicle_execution.get(id,{}).get("incoming_node",""),
			"geometry_nodes":SandboxVehicleReroute.geometry(world),
			"origin_merge":world.vehicle_parking.get("player",{}).get("arrival_policy","")==SandboxVehicleBays.CLINIC and world.route_nodes.front()=="clinic",
			"held":not world.route_hold_id.is_empty(),"origin":SandboxDirectedLanes._parked_screen(world,world.route_nodes.front())}
	var npc: Dictionary=world.resident(id)
	if npc.get("transit_method","")!="shuttle" or int(npc.get("transit_until",0))<=world.minute: return {}
	return {"nodes":npc["transit_nodes"].duplicate(),
		"base":float(world.minute-int(npc["transit_started"])-int(npc.get("transit_pause_minutes",0))),
		"source":str(npc["transit_from_offer"])+":"+str(npc["transit_started"]),
		"held":not str(npc.get("transit_hold_crossing","")).is_empty(),
		"arrival_policy":world.vehicle_execution.get(id,{}).get("arrival_policy","")}

static func nodes_of(travel: Dictionary) -> Array[String]:
	var nodes: Array[String]=[]
	for node in travel.get("nodes",[]): nodes.append(str(node))
	return nodes

static func geometry_nodes(travel: Dictionary) -> Array[String]:
	var nodes: Array[String]=[]
	for node in travel.get("geometry_nodes",travel.get("nodes",[])): nodes.append(str(node))
	return nodes

static func point(travel: Dictionary, progress: float) -> Vector2:
	var nodes: Array[String]=geometry_nodes(travel)
	var incoming: String=str(travel.get("incoming_node",""))
	var geometry: Array[String]=nodes.duplicate()
	var geometry_progress: float=progress
	if not incoming.is_empty():
		geometry.push_front(incoming)
		geometry_progress+=SandboxRoads.edge_minutes(incoming,nodes[0])
	var result: Vector2=SandboxCityView.project(SandboxDirectedLanes.route_point_at_minutes(geometry,geometry_progress))
	if incoming.is_empty() and travel.has("origin") and nodes.size()>=2:
		var fraction: float=progress/float(SandboxRoads.edge_minutes(nodes[0],nodes[1]))
		if fraction<SandboxDirectedLanes.TURN_FRACTION:
			var start: Vector2=SandboxCityView.project(SandboxDirectedLanes.route_lane_point(nodes,0,0.0))
			result+=(Vector2(travel["origin"])-start)*(1.0-smoothstep(0.0,SandboxDirectedLanes.TURN_FRACTION,fraction))
	return SandboxVehicleBays.apply(travel,progress,result)

static func tangent(travel: Dictionary,at: float) -> Vector2:
	var total: float=float(SandboxRoads.path_minutes(geometry_nodes(travel)))
	return point(travel,minf(total,at+.015))-point(travel,maxf(0.0,at-.015))

static func world_point(travel: Dictionary,progress: float,at: Vector2=Vector2.INF) -> Vector3:
	var physical: Vector3=SandboxDirectedLanes.route_point_at_minutes(geometry_nodes(travel),progress)
	var screen: Vector2=point(travel,progress) if not at.is_finite() else at
	var horizontal: float=screen.x/SandboxIsoPresentation.WORLD_TO_SCREEN
	var vertical: float=2.0*(screen.y+physical.y*SandboxIsoPresentation.HEIGHT_TO_SCREEN)/SandboxIsoPresentation.WORLD_TO_SCREEN
	return Vector3((horizontal+vertical)*.5,physical.y,(vertical-horizontal)*.5)


static func segment(travel: Dictionary,progress: float) -> Dictionary:
	var nodes: Array[String]=nodes_of(travel)
	var prior: float=0.0
	for index in range(nodes.size()-1):
		var duration: float=SandboxRoads.edge_minutes(nodes[index],nodes[index+1])
		if progress<prior+duration or index==nodes.size()-2:
			return {"from":nodes[index],"to":nodes[index+1],"index":index,
				"fraction":clampf((progress-prior)/duration,0.0,1.0),"prior":prior,"duration":duration}
		prior+=duration
	return {}

static func bind(world: SandboxWorld,id: String,fraction: float=0.0) -> bool:
	var travel: Dictionary=trip(world,id)
	if travel.is_empty() or str(travel["source"]).is_empty(): return false
	var existing: Dictionary=world.vehicle_execution.get(id,{})
	if existing.get("source","")==travel["source"] and existing.get("nodes",[])==travel["nodes"]:
		var at: float=progress(world,id,fraction)
		var here: Vector2=screen(world,id,fraction)
		var facing: float=heading(world,id,fraction)
		existing["progress"]=at;existing["x"]=here.x;existing["y"]=here.y
		existing["heading"]=facing;existing["native"]=true
		return true
	travel["arrival_policy"]=""
	if not world.vehicle_departures.has(id) and not SandboxVehicleBays.policy(nodes_of(travel)).is_empty():
		travel["arrival_policy"]=SandboxVehicleBays.CLINIC if id=="player" else SandboxVehicleBays.SHUTTLE
	var progress: float=float(travel["base"])+(0.0 if travel["held"] else _departure_fraction(world,id,travel,fraction))
	var heading: float=float(travel.get("initial_heading",tangent(travel,progress).angle())) if progress<=EPSILON else tangent(travel,progress).angle()
	if travel.has("initial_heading"):
		heading=SandboxVehicleKinematics.turn_heading(float(travel["initial_heading"]),tangent(travel,progress).angle(),progress)
	var parked: Dictionary=world.vehicle_parking.get("player",{}) if id=="player" else {}
	if progress<=EPSILON and parked.get("stop","")==travel["nodes"][0]: heading=float(parked["heading"])
	var initial: Vector2=point(travel,progress)
	world.vehicle_execution[id]={"x":initial.x,"y":initial.y,"source":travel["source"],"nodes":travel["nodes"].duplicate(),
		"arrival_policy":travel.get("arrival_policy",""),
		"progress":progress,"speed":0.0,"heading":heading,"native":true,"reason":""}
	world._record("vehicle_execution_entered",id,{"source":travel["source"],"progress":progress,"arrival_policy":travel.get("arrival_policy","")})
	return true

static func _departure_fraction(world: SandboxWorld,id: String,travel: Dictionary,fraction: float) -> float:
	var result: float=clampf(fraction,0.0,.999999)
	if id!="player" or float(travel["base"])>EPSILON: return result
	for index in range(world.events.size()-1,-1,-1):
		var event: Dictionary=world.events[index]
		if int(event["minute"])<world.minute: break
		var source: String="fare:"+str(event["subject"]) if event["kind"]=="offer_accepted" else str(event["id"]) if event["kind"]=="reposition" else ""
		if source==travel["source"]: return maxf(0.0,result-float(event["detail"].get("clock_fraction",0.0)))
	return result


static func unbind(world: SandboxWorld,id: String,clock_fraction: float=0.0) -> void:
	var state: Dictionary=world.vehicle_execution.get(id,{})
	if state.is_empty() or not bool(state["native"]): return
	state["native"]=false
	state["handoff_minute"]=world.minute
	state["handoff_fraction"]=clampf(clock_fraction,0.0,.999999999999)
	state["handoff_progress"]=state["progress"]
	state["handoff_x"]=state["x"];state["handoff_y"]=state["y"]
	state["handoff_heading"]=state["heading"]
	state["reason"]="motion"
	world._record("vehicle_execution_handoff",id,{"source":state["source"],"progress":state["progress"],"fraction":state["handoff_fraction"],"x":state["handoff_x"],"y":state["handoff_y"],"heading":state["handoff_heading"]})

static func progress(world: SandboxWorld,id: String,fraction: float=0.0,minute_offset: int=0) -> float:
	var travel: Dictionary=trip(world,id)
	if travel.is_empty(): return 0.0
	var base: float=float(travel["base"])
	var state: Dictionary=world.vehicle_execution.get(id,{})
	if state.is_empty(): return base+(0.0 if travel["held"] else clampf(fraction,0.0,1.0))
	var at: float=float(state["progress"])
	if bool(state["native"]) or travel["held"]: return at
	var elapsed: float=maxf(0.0,float(world.minute+minute_offset-int(state.get("handoff_minute",world.minute)))+
			clampf(fraction,0.0,1.0)-float(state.get("handoff_fraction",0.0)))
	return minf(float(SandboxRoads.path_minutes(nodes_of(travel))),float(state.get("handoff_progress",at))+elapsed)

static func screen(world: SandboxWorld,id: String,fraction: float=0.0) -> Vector2:
	var travel: Dictionary=trip(world,id)
	var state: Dictionary=world.vehicle_execution.get(id,{})
	if not state.is_empty() and bool(state["native"]): return Vector2(float(state["x"]),float(state["y"]))
	var at: float=progress(world,id,fraction)
	var result: Vector2=point(travel,at)
	if state.has("handoff_progress"):
		var origin: Vector2=point(travel,float(state["handoff_progress"]))
		var anchor: Vector2=Vector2(float(state["handoff_x"]),float(state["handoff_y"]))
		result+=(anchor-origin)*clampf(1.0-(at-float(state["handoff_progress"]))/0.15,0.0,1.0)
	return result

static func heading(world: SandboxWorld,id: String,fraction: float=0.0) -> float:
	var travel: Dictionary=trip(world,id)
	var state: Dictionary=world.vehicle_execution.get(id,{})
	var desired: float=tangent(travel,progress(world,id,fraction)).angle()
	if state.is_empty(): return desired
	if bool(state["native"]) or bool(travel.get("held",false)): return float(state["heading"])
	var elapsed: float=maxf(0.0,float(world.minute-int(state.get("handoff_minute",world.minute)))+
			clampf(fraction,0.0,1.0)-float(state.get("handoff_fraction",0.0)))
	return SandboxVehicleKinematics.turn_heading(float(state.get("handoff_heading",desired)),desired,elapsed)


static func report(world: SandboxWorld,id: String,at: float,speed: float,heading: float,reason: String,where: Vector2=Vector2.INF) -> bool:
	var travel: Dictionary=trip(world,id)
	var state: Dictionary=world.vehicle_execution.get(id,{})
	if travel.is_empty() or state.is_empty() or not bool(state["native"]) \
			or not is_finite(at) or not is_finite(speed) or not is_finite(heading) \
			or at<float(state["progress"])-EPSILON or at>float(travel["base"])+world.vehicle_fraction+LOOKAHEAD_MINUTES+EPSILON \
			or speed<0.0 or speed>SandboxVehicleKinematics.CRUISE+EPSILON \
			or not ["","motion","vehicle","pedestrian","junction","world_crossing","arrival"].has(reason): return false
	if bool(travel["held"]) and (absf(at-float(state["progress"]))>EPSILON or absf(angle_difference(float(state["heading"]),heading))>EPSILON): return false
	var window: Dictionary=SandboxVehicleJunctions.next_window(travel,float(state["progress"]))
	if not window.is_empty() and at>float(window["entry"]):
		var reservation: Dictionary=world.vehicle_junctions.get(window["junction"],{})
		if reservation.get("vehicle","")!=id or reservation.get("source","")!=state["source"]: return false
	if not where.is_finite(): where=point(travel,at)
	if where.distance_to(point(travel,at))>.5: return false
	state["x"]=where.x;state["y"]=where.y
	state["progress"]=minf(at,float(travel["base"])+world.vehicle_fraction+LOOKAHEAD_MINUTES)
	state["speed"]=speed
	state["heading"]=wrapf(heading,-PI,PI)
	state["reason"]=reason
	SandboxVehicleJunctions.release_cleared(world)
	return true

# Called BEFORE the single World minute commits. A local body still behind
# its next route minute records an explicit one-minute travel delay. The city
# and all unrelated actors continue; no planned distance/fare is rewritten.
static func before_tick(world: SandboxWorld) -> bool:
	var player_ready: bool=true
	for id in world.vehicle_execution.keys():
		var travel: Dictionary=trip(world,str(id))
		var state: Dictionary=world.vehicle_execution[id]
		if travel.is_empty() or state.get("source","")!=travel.get("source","") \
				or state.get("nodes",[])!=travel.get("nodes",[]):
			world.vehicle_execution.erase(id);continue
		if travel["held"]: continue # existing validated zebra wait owns this minute
		if not bool(state["native"]):
			state["progress"]=progress(world,str(id),0.0,1)
			var elapsed: float=maxf(0.0,float(world.minute+1-int(state.get("handoff_minute",world.minute)))-float(state.get("handoff_fraction",0.0)))
			state["heading"]=SandboxVehicleKinematics.turn_heading(float(state.get("handoff_heading",state["heading"])),tangent(travel,float(state["progress"])).angle(),elapsed)
			var here: Vector2=point(travel,float(state["progress"]))
			state["x"]=here.x;state["y"]=here.y
		if float(state["progress"])+EPSILON>=float(travel["base"])+1.0: continue
		world._record("vehicle_execution_wait",str(id),{"source":state["source"],
			"base":travel["base"],"progress":state["progress"],"reason":state["reason"]})
		if id=="player": player_ready=false
		elif world.vehicle_departures.has(id):
			world.vehicle_departures[id]["pause"]=int(world.vehicle_departures[id]["pause"])+1
		else:
			var npc: Dictionary=world.resident(str(id))
			npc["transit_pause_minutes"]=int(npc.get("transit_pause_minutes",0))+1
			npc["transit_until"]=int(npc["transit_until"])+1
	return player_ready

static func prune(world: SandboxWorld) -> void:
	for id in world.vehicle_execution.keys():
		var travel: Dictionary=trip(world,str(id))
		if id=="player" and not travel.is_empty() and travel.get("source","")==world.vehicle_execution[id]["source"] and travel["nodes"]!=world.vehicle_execution[id]["nodes"]:
			SandboxVehicleReroute.rebase(world,world.vehicle_execution[id])
		if travel.is_empty() and id=="player": SandboxVehicleParking.capture_player(world,world.vehicle_execution[id])
		elif travel.is_empty() and not world.vehicle_departures.has(id): SandboxVehicleDepartures.capture(world,str(id),world.vehicle_execution[id])
		if travel.is_empty() or travel.get("source","")!=world.vehicle_execution[id]["source"] \
				or travel["nodes"]!=world.vehicle_execution[id]["nodes"]:
			world.vehicle_execution.erase(id)

static func valid_snapshot(value: Dictionary) -> bool:
	for event in value["events"]:
		if event["kind"] in ["offer_accepted","reposition"]:
			var fraction: Variant=event.get("detail",{}).get("clock_fraction",0.0)
			if not (fraction is int or fraction is float) or not is_finite(float(fraction)) or float(fraction)<0.0 or float(fraction)>=1.0: return false
	var registry: Variant=value.get("vehicle_execution",{})
	if not registry is Dictionary or registry.size()>32: return false
	for id in registry:
		var state: Variant=registry[id]
		if not id is String or not state is Dictionary: return false
		if not state.get("native") is bool or not state.get("source") is String \
				or str(state["source"]).is_empty() or not state.get("nodes") is Array: return false
		for key in ["progress","speed","heading","x","y"]:
			if not (state.get(key) is float or state.get(key) is int) or not is_finite(float(state[key])): return false
		if float(state["speed"])<0.0 or float(state["speed"])>SandboxVehicleKinematics.CRUISE \
				or absf(float(state["heading"]))>PI or not ["","motion","vehicle","pedestrian","junction","world_crossing","arrival"].has(state.get("reason")): return false
		var nodes: Array[String]=[]
		for node in state["nodes"]:
			if not node is String: return false
			nodes.append(node)
		if not SandboxRoads.valid_path(nodes): return false
		var base: float=0.0
		if id=="player":
			if nodes!=value.get("route_nodes",[]) or nodes.size()<2: return false
			var expected_source: String="fare:"+str(value.get("active_offer_id",""))
			if str(value.get("active_offer_id","")).is_empty():
				expected_source=""
				for index in range(value["events"].size()-1,-1,-1):
					if value["events"][index].get("kind","")=="reposition":
						expected_source=str(value["events"][index]["id"]);break
			if state["source"]!=expected_source: return false
			if int(value.get("route_segment",-1))<0 or int(value["route_segment"])>=nodes.size()-1: return false
			base=float(value.get("route_edge_elapsed",-1))
			for index in range(int(value.get("route_segment",0))): base+=SandboxRoads.edge_minutes(nodes[index],nodes[index+1])
		elif value.get("vehicle_departures",{}).has(id):
			var service: Dictionary=value["vehicle_departures"][id]
			if nodes!=service["nodes"] or state["source"]!="departure:"+str(id): return false
			base=float(int(value["minute"])-int(service["started"])-int(service["pause"]))
		else:
			var npc: Dictionary={}
			for person in value["residents"]:
				if person["id"]==id: npc=person;break
			if npc.is_empty() or npc.get("transit_method","")!="shuttle" \
					or nodes!=npc.get("transit_nodes",[]) \
					or state["source"]!=str(npc.get("transit_from_offer",""))+":"+str(npc.get("transit_started",0)): return false
			base=float(int(value["minute"])-int(npc["transit_started"])-int(npc.get("transit_pause_minutes",0)))
		if float(state["progress"])<base-EPSILON or float(state["progress"])>base+float(value.get("vehicle_fraction",0.0))+LOOKAHEAD_MINUTES+EPSILON: return false
		var arrival_policy: Variant=state.get("arrival_policy","")
		if not arrival_policy is String or arrival_policy not in ["",SandboxVehicleBays.CLINIC,SandboxVehicleBays.SHUTTLE]: return false
		if not arrival_policy.is_empty():
			if SandboxVehicleBays.policy(nodes)!=SandboxVehicleBays.CLINIC: return false
			if (id=="player")!=(arrival_policy==SandboxVehicleBays.CLINIC) or value.get("vehicle_departures",{}).has(id): return false
		var entered: bool=false
		for event in value["events"]:
			if event.get("kind","")=="vehicle_execution_entered" and event.get("subject","")==id \
					and event.get("detail",{}).get("source","")==state["source"] \
					and event.get("detail",{}).get("arrival_policy","")==arrival_policy: entered=true
		if not entered: return false
		var travel: Dictionary={"nodes":nodes,"arrival_policy":arrival_policy}
		var actual: Vector2=Vector2(float(state["x"]),float(state["y"]))
		if id=="player":
			travel["origin"]=SandboxVehicleParking.from_snapshot(value,nodes[0])
			if not SandboxVehicleReroute.valid_context(value,state): return false
			travel["incoming_node"]=state.get("incoming_node","")
			var geometry: Array[String]=[]
			if not value.get("pending_route_nodes",[]).is_empty():
				for index in range(int(value["route_segment"])+1): geometry.append(nodes[index])
				for node in value["pending_route_nodes"]: geometry.append(str(node))
				travel["geometry_nodes"]=geometry
		elif value.get("vehicle_departures",{}).has(id):
			var service: Dictionary=value["vehicle_departures"][id]
			travel["origin"]=Vector2(float(service["x"]),float(service["y"]))
		if actual.distance_to(point(travel,float(state["progress"])))>.5: return false
		if not bool(state["native"]):
			for key in ["handoff_minute","handoff_fraction","handoff_progress","handoff_x","handoff_y","handoff_heading"]:
				if not (state.get(key) is int or state.get(key) is float) or not is_finite(float(state[key])): return false
			if int(state["handoff_minute"])<SandboxWorld.START_MINUTE or int(state["handoff_minute"])>int(value["minute"]) or float(state["handoff_fraction"])<0.0 or float(state["handoff_fraction"])>=1.0: return false
			if float(state["handoff_progress"])<0.0 or float(state["handoff_progress"])>float(state["progress"])+EPSILON or absf(float(state["handoff_heading"]))>PI: return false
			if Vector2(float(state["handoff_x"]),float(state["handoff_y"])).distance_to(point(travel,float(state["handoff_progress"])))>.5: return false
			var sourced: bool=false
			for event in value["events"]:
				var detail: Dictionary=event.get("detail",{})
				if event.get("kind","")=="vehicle_execution_handoff" and event.get("subject","")==id and event.get("minute",-1)==state["handoff_minute"] and detail.get("source","")==state["source"] and detail.get("progress",-1)==state["handoff_progress"] and detail.get("fraction",-1)==state["handoff_fraction"] and detail.get("x",INF)==state["handoff_x"] and detail.get("y",INF)==state["handoff_y"] and detail.get("heading",INF)==state["handoff_heading"]: sourced=true
			if not sourced: return false
	return true
