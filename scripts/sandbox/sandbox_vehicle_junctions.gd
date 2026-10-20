class_name SandboxVehicleJunctions
extends RefCounted

# Exclusive admission for real adjacent authored lane connectors. The World
# ledger survives unloading, saves and scene replacement; bodies own no locks.
static func next_window(travel: Dictionary,progress: float) -> Dictionary:
	var nodes: Array[String]=SandboxVehicleExecution.geometry_nodes(travel)
	var preceding: String=str(travel.get("incoming_node",""))
	if not preceding.is_empty() and nodes.size()>=2 and SandboxDirectedLanes.can_turn(preceding,nodes[0],nodes[1]):
		var turn_exit: float=SandboxRoads.edge_minutes(nodes[0],nodes[1])*SandboxDirectedLanes.TURN_FRACTION
		if progress<=turn_exit:
			return {"junction":nodes[0],"entry":0.0,"exit":turn_exit,"nodes":[preceding,nodes[0],nodes[1]],"kind":"carried_turn"}
	if bool(travel.get("origin_merge",false)) and nodes.size()>=2 and nodes[0]=="clinic":
		var merge_exit: float=SandboxRoads.edge_minutes(nodes[0],nodes[1])*SandboxDirectedLanes.TURN_FRACTION
		if progress<=merge_exit:
			return {"junction":"clinic","entry":0.0,"exit":merge_exit,"nodes":[nodes[0],nodes[1]],"kind":"curb_merge"}
	var boundary: float=0.0
	for index in range(nodes.size()-2):
		var incoming: float=SandboxRoads.edge_minutes(nodes[index],nodes[index+1])
		var outgoing: float=SandboxRoads.edge_minutes(nodes[index+1],nodes[index+2])
		boundary+=incoming
		if not SandboxDirectedLanes.can_turn(nodes[index],nodes[index+1],nodes[index+2]): continue
		var exit: float=boundary+outgoing*SandboxDirectedLanes.TURN_FRACTION
		if progress>exit: continue
		return {"junction":nodes[index+1],"entry":boundary-incoming*SandboxDirectedLanes.TURN_FRACTION,
			"exit":exit,"nodes":[nodes[index],nodes[index+1],nodes[index+2]]}
	if nodes.size()>=2 and nodes.back()=="clinic" and travel.get("arrival_policy","") in [SandboxVehicleBays.CLINIC,SandboxVehicleBays.SHUTTLE]:
		var total: float=SandboxRoads.path_minutes(nodes)
		var duration: float=SandboxRoads.edge_minutes(nodes[nodes.size()-2],nodes.back())
		if progress<=total:
			return {"junction":"clinic","entry":total-duration*SandboxVehicleBays.BLEND,
				"exit":total,"nodes":[nodes[nodes.size()-2],nodes.back()],"kind":"curb_arrival"}
	return {}

static func claim(world: SandboxWorld,id: String) -> bool:
	var travel: Dictionary=SandboxVehicleExecution.trip(world,id)
	var state: Dictionary=world.vehicle_execution.get(id,{})
	if travel.is_empty() or state.is_empty(): return false
	var window: Dictionary=next_window(travel,float(state["progress"]))
	if window.is_empty() or float(window["entry"])-float(state["progress"])>SandboxVehicleExecution.LOOKAHEAD_MINUTES: return false
	var key: String=str(window["junction"])
	var held: Dictionary=world.vehicle_junctions.get(key,{})
	if not held.is_empty(): return held["vehicle"]==id and held["source"]==state["source"]
	var reservation: Dictionary={"vehicle":id,"source":state["source"],"entry":window["entry"],
		"exit":window["exit"],"nodes":window["nodes"]}
	if window.has("kind"): reservation["kind"]=window["kind"]
	world.vehicle_junctions[key]=reservation
	world._record("vehicle_junction_claimed",id,{"junction":key,"reservation":reservation})
	return true

static func refresh_player_plan(world: SandboxWorld) -> void:
	var state: Dictionary=world.vehicle_execution.get("player",{})
	if state.is_empty(): return
	var window: Dictionary=next_window(SandboxVehicleExecution.trip(world,"player"),float(state["progress"]))
	var changed: bool=false
	for key in world.vehicle_junctions.keys():
		var held: Dictionary=world.vehicle_junctions[key]
		if held["vehicle"]!="player": continue
		if window.get("nodes",[])==held["nodes"] and window.get("entry",-1)==held["entry"] and window.get("exit",-1)==held["exit"]: continue
		world._record("vehicle_junction_released","player",{"junction":key,"source":held["source"]})
		world.vehicle_junctions.erase(key);changed=true
	if changed: claim(world,"player")


static func release_cleared(world: SandboxWorld) -> void:
	for key in world.vehicle_junctions.keys():
		var held: Dictionary=world.vehicle_junctions[key]
		var id: String=str(held["vehicle"])
		var travel: Dictionary=SandboxVehicleExecution.trip(world,id)
		var state: Dictionary=world.vehicle_execution.get(id,{})
		if not travel.is_empty() and not state.is_empty() and state["source"]==held["source"] \
				and float(state["progress"])<=float(held["exit"]): continue
		world._record("vehicle_junction_released",id,{"junction":key,"source":held["source"]})
		world.vehicle_junctions.erase(key)

static func stop_progress(world: SandboxWorld,id: String) -> float:
	var travel: Dictionary=SandboxVehicleExecution.trip(world,id)
	var state: Dictionary=world.vehicle_execution.get(id,{})
	if travel.is_empty() or state.is_empty(): return INF
	release_cleared(world)
	var window: Dictionary=next_window(travel,float(state["progress"]))
	if window.is_empty(): return INF
	if claim(world,id): return INF
	return float(window["entry"])

static func valid_snapshot(value: Dictionary) -> bool:
	var registry: Variant=value.get("vehicle_junctions",{})
	if not registry is Dictionary: return false
	var ledger: Dictionary={}
	for event in value["events"]:
		var kind: String=str(event.get("kind",""))
		if kind!="vehicle_junction_claimed" and kind!="vehicle_junction_released": continue
		var detail: Dictionary=event.get("detail",{})
		var key: String=str(detail.get("junction",""))
		var id: String=str(event.get("subject",""))
		if kind=="vehicle_junction_claimed":
			var held: Variant=detail.get("reservation",{})
			if ledger.has(key) or not held is Dictionary or held.get("vehicle","")!=id \
					or not held.get("source") is String or str(held["source"]).is_empty() \
					or not held.get("nodes") is Array: return false
			var nodes: Array=held["nodes"]
			if held.get("kind","")=="curb_merge":
				if nodes.size()!=2 or nodes[0]!="clinic" or key!="clinic" or not nodes[1] is String or not SandboxDirectedLanes.has_profile(nodes[0],nodes[1]): return false
				if held.get("entry",-1)!=0.0 or held.get("exit",-1)!=SandboxRoads.edge_minutes(nodes[0],nodes[1])*SandboxDirectedLanes.TURN_FRACTION: return false
			elif held.get("kind","")=="curb_arrival":
				if nodes.size()!=2 or nodes[1]!="clinic" or key!="clinic" or not nodes[0] is String or not SandboxDirectedLanes.has_profile(nodes[0],nodes[1]): return false
				if absf(float(held.get("exit",0))-float(held.get("entry",0))-SandboxRoads.edge_minutes(nodes[0],nodes[1])*SandboxVehicleBays.BLEND)>.00001: return false
			elif held.get("kind","")=="carried_turn":
				if nodes.size()!=3 or not nodes[0] is String or not nodes[1] is String or not nodes[2] is String or nodes[1]!=key or not SandboxDirectedLanes.can_turn(nodes[0],nodes[1],nodes[2]): return false
				if held.get("entry",-1)!=0.0 or held.get("exit",-1)!=SandboxRoads.edge_minutes(nodes[1],nodes[2])*SandboxDirectedLanes.TURN_FRACTION: return false
			else:
				if held.has("kind") or nodes.size()!=3: return false
				if not nodes[0] is String or not nodes[1] is String or not nodes[2] is String \
						or nodes[1]!=key or not SandboxDirectedLanes.can_turn(nodes[0],nodes[1],nodes[2]): return false
			for field in ["entry","exit"]:
				if not (held.get(field) is float or held.get(field) is int) or not is_finite(float(held[field])): return false
			if float(held["entry"])<0.0 or float(held["exit"])<=float(held["entry"]): return false
			ledger[key]=held
		else:
			if not ledger.has(key) or ledger[key]["vehicle"]!=id or ledger[key]["source"]!=detail.get("source",""): return false
			ledger.erase(key)
	if ledger!=registry: return false
	for key in registry:
		var held: Dictionary=registry[key]
		var state: Dictionary=value.get("vehicle_execution",{}).get(held["vehicle"],{})
		if state.is_empty() or state["source"]!=held["source"]: return false
		var curb: bool=value.get("vehicle_departures",{}).has(held["vehicle"]) or (held["vehicle"]=="player" and value.get("vehicle_parking",{}).get("player",{}).get("arrival_policy","")==SandboxVehicleBays.CLINIC)
		var travel: Dictionary={"nodes":state["nodes"],"origin_merge":curb,"arrival_policy":state.get("arrival_policy",""),"incoming_node":state.get("incoming_node","")}
		if held["vehicle"]=="player" and not value.get("pending_route_nodes",[]).is_empty():
			var geometry: Array[String]=[]
			for index in range(int(value["route_segment"])+1): geometry.append(str(state["nodes"][index]))
			for node in value["pending_route_nodes"]: geometry.append(str(node))
			travel["geometry_nodes"]=geometry
		var window: Dictionary=next_window(travel,float(state["progress"]))
		if window.is_empty() or window["junction"]!=key or window["entry"]!=held["entry"] \
				or window["exit"]!=held["exit"] or window["nodes"]!=held["nodes"]: return false
	return true
