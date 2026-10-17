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
	if duration<=0 or duration!=SandboxRoads.path_minutes(nodes):
		return {}
	var elapsed: float=clampf(float(world.minute-start)+clampf(fraction,0.0,1.0),
			0.0,float(duration))
	var current: Vector3=world.npc_position(npc,fraction)
	var ahead: Vector3=SandboxRoads.position_on_path(nodes,minf(float(duration),
			elapsed+0.15),float(duration))
	if ahead.distance_to(current)<0.0001:
		ahead=SandboxRoads.position_on_path(nodes,maxf(0.0,elapsed-0.15),
				float(duration))
	return {
		"resident_id":str(npc["id"]),
		"source_offer":str(npc["transit_from_offer"]),
		"position":current,
		"ahead":ahead,
		"arrival_at":finish
	}
