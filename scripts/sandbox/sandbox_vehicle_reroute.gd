class_name SandboxVehicleReroute
extends RefCounted

# Route commands cannot undo a turn the real vehicle has already taken.
static func geometry(world: SandboxWorld) -> Array[String]:
	if world.pending_route_nodes.is_empty(): return world.route_nodes.duplicate()
	var nodes: Array[String]=[]
	for index in range(world.route_segment+1): nodes.append(world.route_nodes[index])
	nodes.append_array(world.pending_route_nodes)
	return nodes

static func plan(world: SandboxWorld,destination: String,via: String) -> Dictionary:
	if not world.vehicle_execution.has("player"):
		var junction: String=world.route_nodes[world.route_segment+1]
		return {"nodes":SandboxRoads.path(junction,destination,via),"decision_junction":junction}
	var nodes: Array[String]=geometry(world)
	var index: int=world.route_segment
	if world.vehicle_execution.has("player"):
		var at: float=SandboxVehicleExecution.progress(world,"player",world.vehicle_fraction)
		var prior: float=0.0
		for road in range(nodes.size()-1):
			var duration: float=SandboxRoads.edge_minutes(nodes[road],nodes[road+1])
			if at<prior+duration or road==nodes.size()-2:
				index=maxi(index,road)
				if road<nodes.size()-2 and SandboxDirectedLanes.can_turn(nodes[road],nodes[road+1],nodes[road+2]) \
						and at>=prior+duration*(1.0-SandboxDirectedLanes.TURN_FRACTION): index+=1
				break
			prior+=duration
	for road in range(index,nodes.size()-1):
		var junction: String=nodes[road+1]
		if junction==destination: return {}
		var suffix: Array[String]=SandboxRoads.path(junction,destination,via)
		if not SandboxRoads.valid_path(suffix) or suffix[1]==nodes[road]: continue
		var proposed: Array[String]=[]
		for kept in range(world.route_segment+1,road+1): proposed.append(nodes[kept])
		proposed.append_array(suffix)
		return {"nodes":proposed,"decision_junction":junction}
	return {}

# The World just committed the next road and applied a queued suffix. Rebase
# only route coordinates: retain actual XY, speed, yaw, identity and turn context.
static func rebase(world: SandboxWorld,state: Dictionary) -> bool:
	if world.active_offer_id.is_empty(): return false
	var parent: Dictionary={}
	for index in range(world.events.size()-1,-1,-1):
		var event: Dictionary=world.events[index]
		if event["kind"]=="route_rerouted" and event["subject"]==world.active_offer_id:
			parent=event;break
	if parent.is_empty() or parent["minute"]!=world.minute or parent["detail"]["new_remaining"]!=world.route_nodes: return false
	var old_nodes: Array[String]=SandboxVehicleExecution.nodes_of(state)
	var cut: int=old_nodes.size()-parent["detail"]["old_remaining"].size()
	if cut<=0 or cut>=old_nodes.size() or old_nodes[cut]!=world.route_nodes[0]: return false
	var offset: float=0.0
	for index in range(cut): offset+=SandboxRoads.edge_minutes(old_nodes[index],old_nodes[index+1])
	var at: float=float(state["progress"])-offset
	if at<0.0: return false
	var incoming: String=old_nodes[cut-1]
	var travel: Dictionary={"nodes":world.route_nodes,"incoming_node":incoming,"arrival_policy":state.get("arrival_policy","")}
	var position: Vector2=Vector2(float(state["x"]),float(state["y"]))
	if position.distance_to(SandboxVehicleExecution.point(travel,at))>.5: return false
	var held: bool=false
	for key in world.vehicle_junctions.keys():
		if world.vehicle_junctions[key]["vehicle"]=="player":
			world._record("vehicle_junction_released","player",{"junction":key,"source":state["source"]})
			world.vehicle_junctions.erase(key);held=true
	state["nodes"]=world.route_nodes.duplicate()
	state["progress"]=at
	state["incoming_node"]=incoming
	world._record("vehicle_execution_rebased","player",{"source":state["source"],"parent_event":parent["id"],
		"incoming_node":incoming,"nodes":world.route_nodes.duplicate(),"progress":at,"offset":offset})
	state["rebase_event"]=world.events.back()["id"]
	if not bool(state["native"]):
		# Refresh the far anchor at the same point in the same World clock.
		state["handoff_minute"]=world.minute
		state["handoff_fraction"]=world.vehicle_fraction
		state["handoff_progress"]=at
		state["handoff_x"]=position.x;state["handoff_y"]=position.y
		state["handoff_heading"]=state["heading"]
		world._record("vehicle_execution_handoff","player",{"source":state["source"],"progress":at,
			"fraction":world.vehicle_fraction,"x":position.x,"y":position.y,"heading":state["heading"]})
	if held: SandboxVehicleJunctions.claim(world,"player")
	return true

static func valid_context(value: Dictionary,state: Dictionary) -> bool:
	var latest: Dictionary={}
	var seen: Dictionary={}
	var last_leg: Dictionary={}
	for event in value["events"]:
		if event["kind"]=="route_segment_completed" and "fare:"+str(event["subject"])==state["source"]: last_leg=event
		if event["kind"]=="vehicle_execution_rebased" and event["subject"]=="player" and event["detail"].get("source","")==state["source"]:
			var detail: Dictionary=event["detail"]
			if not detail.get("nodes") is Array or detail["nodes"].size()<2: return false
			var parent: Dictionary=seen.get(detail.get("parent_event",""),{})
			if parent.get("kind","")!="route_rerouted" or "fare:"+str(parent.get("subject",""))!=state["source"] \
					or parent.get("minute",-1)!=event["minute"] or parent["detail"].get("new_remaining",[])!=detail.get("nodes",[]): return false
			if last_leg.is_empty() or last_leg["minute"]!=event["minute"] or last_leg["detail"].get("from","")!=detail.get("incoming_node","") \
					or last_leg["detail"].get("to","")!=detail["nodes"][0]: return false
			if detail.get("nodes",[])==state["nodes"]: latest=event
		seen[str(event["id"])]=event
	if latest.is_empty(): return not state.has("incoming_node") and not state.has("rebase_event")
	return state.get("incoming_node","")==latest["detail"]["incoming_node"] and state.get("rebase_event","")==latest["id"]
