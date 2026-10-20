class_name SandboxVehicleDepartures
extends RefCounted

# A completed real clinic shuttle remains a vehicle after its rider exits.
# Its empty return uses authored roads and the SAME World minute; it has no
# passenger fare, synthetic driver, population entry or economy callback.
static func return_nodes(incoming: Array[String]) -> Array[String]:
	if incoming.size()<2 or incoming.back()!="clinic": return []
	var via: String="basin_turn" if incoming[incoming.size()-2]=="docks" else "docks"
	return SandboxRoads.path_via("clinic","depot",[via])

static func elapsed(world: SandboxWorld,service: Dictionary,fraction: float=0.0) -> float:
	return maxf(0.0,float(world.minute-int(service["started"])-int(service["pause"]))+clampf(fraction,0.0,1.0))

static func trip(world: SandboxWorld,id: String) -> Dictionary:
	var service: Dictionary=world.vehicle_departures.get(id,{})
	if service.is_empty(): return {}
	var nodes: Array[String]=SandboxVehicleExecution.nodes_of(service)
	var at: float=elapsed(world,service)
	if at>=float(SandboxRoads.path_minutes(nodes)): return {}
	return {"nodes":nodes,"base":at,"source":"departure:"+id,"held":false,
		"origin":Vector2(float(service["x"]),float(service["y"])),"origin_merge":true,"initial_heading":service["heading"]}

static func capture(world: SandboxWorld,owner: String,state: Dictionary) -> void:
	if state.get("arrival_policy","")!=SandboxVehicleBays.SHUTTLE: return
	var incoming: Array[String]=SandboxVehicleExecution.nodes_of(state)
	if incoming.size()<2 or float(state["progress"])+SandboxVehicleExecution.EPSILON<float(SandboxRoads.path_minutes(incoming)): return
	var parent: Dictionary={}
	for index in range(world.events.size()-1,-1,-1):
		var event: Dictionary=world.events[index]
		if event["kind"]=="npc_alternative_arrived" and event["subject"]==owner:
			parent=event;break
	if parent.is_empty() or parent["minute"]!=world.minute or parent["detail"].get("method","")!="shuttle" \
			or parent["detail"].get("to","")!="clinic" or not str(state["source"]).begins_with(str(parent["detail"]["offer_id"])+":"): return
	var id: String="shuttle:"+str(state["source"])
	if world.vehicle_departures.has(id): return
	var nodes: Array[String]=return_nodes(incoming)
	if not SandboxRoads.valid_path(nodes): return
	var service: Dictionary={"owner":owner,"source":state["source"],"parent_event":parent["id"],
		"incoming":incoming,"nodes":nodes,"x":state["x"],"y":state["y"],"heading":state["heading"],
		"started":world.minute,"pause":0}
	world.vehicle_departures[id]=service
	world._record("vehicle_service_departed",id,service)

static func screen(world: SandboxWorld,id: String,fraction: float=0.0) -> Vector2:
	if world.vehicle_execution.has(id): return SandboxVehicleExecution.screen(world,id,fraction)
	var service: Dictionary=world.vehicle_departures[id]
	return SandboxVehicleExecution.point({"nodes":service["nodes"],"origin":Vector2(float(service["x"]),float(service["y"]))},elapsed(world,service,fraction))

static func heading(world: SandboxWorld,id: String,fraction: float=0.0) -> float:
	if world.vehicle_execution.has(id): return SandboxVehicleExecution.heading(world,id,fraction)
	var service: Dictionary=world.vehicle_departures[id]
	var travel: Dictionary={"nodes":service["nodes"],"origin":Vector2(float(service["x"]),float(service["y"]))}
	var at: float=minf(elapsed(world,service,fraction),float(SandboxRoads.path_minutes(SandboxVehicleExecution.nodes_of(service))))
	return SandboxVehicleKinematics.turn_heading(float(service["heading"]),SandboxVehicleExecution.tangent(travel,at).angle(),at)

static func elevated(world: SandboxWorld,id: String,fraction: float=0.0) -> bool:
	var service: Dictionary=world.vehicle_departures[id]
	var at: float=SandboxVehicleExecution.progress(world,id,fraction) if world.vehicle_execution.has(id) else elapsed(world,service,fraction)
	return SandboxDirectedLanes.route_point_at_minutes(SandboxVehicleExecution.nodes_of(service),at).y>0.0


static func resident_screen(world: SandboxWorld,npc: Dictionary,fraction: float=0.0) -> Vector2:
	if npc.get("location","")!="clinic" or int(npc.get("transit_until",0))>0 or not str(npc.get("taxi_offer","")).is_empty(): return Vector2.INF
	var latest: Dictionary={}
	for service in world.vehicle_departures.values():
		if service["owner"]==npc["id"] and (latest.is_empty() or int(service["started"])>int(latest["started"])): latest=service
	if latest.is_empty() or int(npc.get("passenger_alight",{}).get("started",-1))>=int(latest["started"]): return Vector2.INF
	var incoming: Array[String]=[]
	for node in latest["incoming"]: incoming.append(str(node))
	var start: Vector2=Vector2(float(latest["x"]),float(latest["y"]))+SandboxVehicleBays.normal(incoming[incoming.size()-2])*SandboxVehicleBays.DOOR_CLEARANCE
	var goal: Vector2=SandboxAlightGeometry.goal({"from":incoming[incoming.size()-2]})
	var elapsed: float=maxf(0.0,float(world.minute-int(latest["started"]))+clampf(fraction,0.0,1.0))
	return start.move_toward(goal,elapsed*SandboxAlightGeometry.WALK_SPEED)

static func valid_snapshot(value: Dictionary) -> bool:
	var registry: Variant=value.get("vehicle_departures",{})
	if not registry is Dictionary: return false
	var expected: Dictionary={}
	var seen: Dictionary={}
	var original: Dictionary={}
	var entered: Dictionary={}
	for event in value["events"]:
		var kind: String=str(event.get("kind",""))
		var detail: Dictionary=event.get("detail",{})
		var id: String=str(event.get("subject",""))
		if kind=="npc_alternative_departed" and detail.get("method","")=="shuttle":
			original[str(detail.get("offer_id",""))+":"+str(event["minute"])]=event
		elif kind=="vehicle_execution_entered":
			entered[str(detail.get("source",""))]={"owner":id,"policy":detail.get("arrival_policy","")}
		elif kind=="vehicle_service_departed":
			if expected.has(id) or id!="shuttle:"+str(detail.get("source","")) or not seen.has(detail.get("parent_event","")): return false
			for key in ["x","y","heading","started","pause"]:
				if not (detail.get(key) is int or detail.get(key) is float) or not is_finite(float(detail[key])): return false
			var source: String=str(detail.get("source",""))
			if not original.has(source) or entered.get(source,{})!={"owner":detail.get("owner",""),"policy":SandboxVehicleBays.SHUTTLE}: return false
			var depart: Dictionary=original[source]
			var parent: Dictionary=seen[detail["parent_event"]]
			if parent["kind"]!="npc_alternative_arrived" or parent["subject"]!=detail["owner"] \
					or parent["detail"].get("offer_id","")!=depart["detail"]["offer_id"] or parent["detail"].get("method","")!="shuttle" \
					or parent["detail"].get("to","")!="clinic" or parent["minute"]!=event["minute"] \
					or detail["started"]!=event["minute"] or detail["pause"]!=0 or absf(float(detail["heading"]))>PI: return false
			var incoming: Array[String]=SandboxRoads.path(depart["detail"]["from"],depart["detail"]["to"])
			if detail.get("incoming",[])!=incoming or detail.get("nodes",[])!=return_nodes(incoming): return false
			var from: String=incoming[incoming.size()-2]
			if SandboxVehicleBays.shuttle_point(from).distance_to(Vector2(float(detail["x"]),float(detail["y"])))>.001: return false
			expected[id]=detail.duplicate(true)
		elif kind=="vehicle_execution_wait" and expected.has(id):
			if detail.get("source","")!="departure:"+id or int(event["minute"])<int(expected[id]["started"]): return false
			expected[id]["pause"]=int(expected[id]["pause"])+1
		seen[str(event.get("id",""))]=event
	return registry==expected
