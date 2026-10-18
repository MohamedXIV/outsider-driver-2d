class_name SandboxWorldTraffic
extends RefCounted

# World-owned transport projection, not a second traffic simulator. Only a
# resident already taking an authorized independent municipal shuttle trip
# may be shown as a vehicle. Existing NPC arrival/provenance/economy stay
# exclusively in SandboxWorld and SandboxAutonomy.
static func shuttle_pose(world: SandboxWorld, npc: Dictionary,
		fraction: float = 0.0) -> Dictionary:
	if str(npc.get("transit_method",""))!="shuttle" \
			or int(npc.get("transit_started",-1))>world.minute \
			or int(npc.get("transit_until",0))<=world.minute \
			or str(npc.get("transit_from_offer","")).is_empty() \
			or not (npc.get("transit_nodes") is Array):
		return {}
	var nodes: Array[String]=[]
	for item in npc["transit_nodes"]:
		if not (item is String): return {}
		nodes.append(item)
	if not SandboxRoads.valid_path(nodes):
		return {}
	var start: int=int(npc["transit_started"])
	var finish: int=int(npc["transit_until"])
	var duration: int=finish-start
	if duration<=0 or duration-int(npc.get("transit_pause_minutes",0))!=SandboxRoads.path_minutes(nodes):
		return {}
	var pause: int=int(npc.get("transit_pause_minutes",0))
	var route_duration: float=float(duration-pause)
	var elapsed: float=clampf(float(world.minute-start-pause)+ \
			(0.0 if not str(npc.get("transit_hold_crossing","")).is_empty()
			else clampf(fraction,0.0,1.0)),
			0.0,route_duration)
	var current: Vector3=world.npc_position(npc,fraction)
	# Keep canonical centreline position for world ownership, persistence and
	# crossing. The independent visual shuttle now uses taxi-compatible lanes.
	var visual: Vector3=SandboxDirectedLanes.path_lane_point(nodes,elapsed,route_duration)
	if not visual.is_finite(): return {}
	var visual_heading: float=SandboxDirectedLanes.path_screen_heading(
			nodes,elapsed,route_duration)
	var ahead: Vector3=SandboxRoads.position_on_path(nodes,minf(route_duration,
			elapsed+0.15),route_duration)
	if ahead.distance_to(current)<0.0001:
		ahead=SandboxRoads.position_on_path(nodes,maxf(0.0,elapsed-0.15),
				route_duration)
	return {
		"resident_id":str(npc["id"]),
		"source_offer":str(npc["transit_from_offer"]),
		"position":current,
		"ahead":ahead,
		"visual_position":visual,
		"visual_heading":visual_heading,
		"arrival_at":finish
	}



# World-road approach in both directions. The elapsed route distance is
# unaffected by any accumulated full-minute waiting at this zebra.
static func approaching_zebra(world: SandboxWorld,npc: Dictionary) -> bool:
	if not SandboxStreetRouteBinding.grounded() \
			or str(npc.get("transit_method",""))!="shuttle" \
			or int(npc.get("transit_until",0))<=world.minute \
			or not str(npc.get("transit_hold_crossing","")).is_empty():
		return false
	var elapsed: int=world.minute-int(npc.get("transit_started",0)) \
			-int(npc.get("transit_pause_minutes",0))
	return _at_zebra_window(npc,elapsed,true)


static func occupies_zebra(world: SandboxWorld) -> bool:
	if not SandboxStreetRouteBinding.grounded(): return false
	for npc in world.residents:
		if str(npc.get("transit_method",""))!="shuttle" \
				or int(npc.get("transit_until",0))<=world.minute \
				or not str(npc.get("transit_hold_crossing","")).is_empty():
			continue
		var elapsed: int=world.minute-int(npc.get("transit_started",0)) \
				-int(npc.get("transit_pause_minutes",0))
		if _at_zebra_window(npc,elapsed,false): return true
	return false


static func _at_zebra_window(npc: Dictionary, elapsed: int, approaching: bool) -> bool:
	if not (npc.get("transit_nodes") is Array): return false
	var nodes: Array=npc["transit_nodes"]
	var prior: int=0
	for i in range(nodes.size()-1):
		var from_node: String=str(nodes[i])
		var to_node: String=str(nodes[i+1])
		if not SandboxRoads.connected(from_node,to_node): return false
		var minutes: int=SandboxRoads.edge_minutes(from_node,to_node)
		var fraction: float=SandboxStreetRouteBinding.crossing_fraction(from_node,to_node)
		if fraction>=0.0 and minutes>1:
			var progress: float=float(elapsed-prior)/float(minutes)
			if approaching and progress>=0.0 and progress<fraction \
					and progress+1.0/float(minutes)>=fraction:
				return true
			if not approaching and absf(progress-fraction)<=0.065:
				return true
		prior+=minutes
	return false


# Prevent invented, missing or temporally inconsistent shuttle waits on
# restored saves. Check each real resident's signed start/end event pairs.
static func valid_yield_history(npc: Dictionary,events: Array,minute: int) -> bool:
	var active: bool=int(npc.get("transit_until",0))>0
	var source: String=str(npc.get("transit_from_offer",""))
	var started: int=int(npc.get("transit_started",0))
	var held: String=str(npc.get("transit_hold_crossing",""))
	var paused: int=int(npc.get("transit_pause_minutes",0))
	if paused<0 or not ["",SandboxStreetRouteBinding.CROSSING_ID].has(held):
		return false
	if not active and (paused!=0 or not held.is_empty()): return false
	if active and npc.get("transit_method","")!="shuttle" \
			and (paused!=0 or not held.is_empty()): return false
	var pending: int=-1
	var pending_source: String=""
	var counted: int=0
	for evt in events:
		if evt.get("subject","")!=npc.get("id",""): continue
		var kind: String=str(evt.get("kind",""))
		if kind!="npc_shuttle_yield_started" and kind!="npc_shuttle_yield_ended":
			continue
		var detail: Dictionary=evt.get("detail",{})
		var at: int=int(evt.get("minute",-1))
		if at<0 or at>minute or detail.get("crossing","")!=SandboxStreetRouteBinding.CROSSING_ID:
			return false
		if kind=="npc_shuttle_yield_started":
			if pending>=0 or detail.get("edge","")!=SandboxRoads.edge_key(
					SandboxStreetRouteBinding.FROM,SandboxStreetRouteBinding.TO) \
					or str(detail.get("source_offer","")).is_empty():
				return false
			pending=at
			pending_source=str(detail["source_offer"])
		else:
			if pending<0 or detail.get("source_offer","")!=pending_source \
					or int(detail.get("wait_minutes",-1))!=at-pending:
				return false
			if active and pending_source==source and pending>=started:
				counted+=at-pending
			pending=-1
			pending_source=""
	if active and pending>=0 and pending_source==source and pending>=started:
		counted+=minute-pending
	if not active and pending>=0:return false
	return paused==counted and held==(SandboxStreetRouteBinding.CROSSING_ID
			if pending>=0 else "")
