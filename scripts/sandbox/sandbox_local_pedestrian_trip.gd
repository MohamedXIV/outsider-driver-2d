class_name SandboxLocalPedestrianTrip
extends RefCounted

# A genuine resident's local errand belongs to SandboxWorld. Godot agents own
# visible movement; the world validates and records intent and arrival once.
# This bounded experiment does not change city-wide taxi offer/route semantics.
const PATCHWORKS_PARTS: String = "patchworks:parts_counter"

static func eligible(world: SandboxWorld, npc: Dictionary) -> bool:
	if not npc.get("local_pedestrian_trip",{}).is_empty() or npc.get("location","")!="garage" \
			or npc.get("activity","")!="available" or int(npc.get("need",0))<30 \
			or not ["supplies","work"].has(npc.get("purpose","")) \
			or int(npc.get("cooldown_until",0))>world.minute \
			or not str(npc.get("taxi_offer","")).is_empty(): return false
	for offer in world.offers:
		if offer.get("npc_id","")==npc.get("id","") and offer.get("status","") in ["open","accepted"]:
			return false
	return true

static func candidates(world: SandboxWorld) -> Array[String]:
	var ids: Array[String]=[]
	# Resume existing identities first; never manufacture population for a demo.
	for npc in world.residents:
		if npc.get("local_pedestrian_trip",{}).get("status","") in ["walking","offscreen"]:
			ids.append(str(npc["id"]))
	for npc in world.residents:
		if ids.size()>=2: break
		if eligible(world,npc): ids.append(str(npc["id"]))
	return ids

static func candidate(world: SandboxWorld) -> String:
	var ids: Array[String]=candidates(world)
	return ids[0] if not ids.is_empty() else ""

static func begin(world: SandboxWorld, npc_id: String, site: String) -> bool:
	var npc: Dictionary=world.resident(npc_id)
	if site!=PATCHWORKS_PARTS or not eligible(world,npc): return false
	var used: Array[int]=[]
	for other in world.residents:
		var trip: Dictionary=other.get("local_pedestrian_trip",{})
		if trip.get("status","") in ["walking","offscreen"]: used.append(int(trip.get("slot",0)))
	var slot: int=0 if not used.has(0) else 1
	if used.has(slot): return false
	npc["local_pedestrian_trip"]={"site":site,"status":"walking","started":world.minute,
			"slot":slot,"crossing_state":"approach"}
	world._record("local_pedestrian_departed",npc_id,{"from":"garage","site":site,"slot":slot})
	return true

static func reserve(world: SandboxWorld, npc_id: String) -> bool:
	return _crossing_transition(world,npc_id,"reserved",["approach"])

static func entered(world: SandboxWorld, npc_id: String) -> bool:
	return _crossing_transition(world,npc_id,"entered",["reserved"])

static func clear(world: SandboxWorld, npc_id: String) -> bool:
	return _crossing_transition(world,npc_id,"cleared",["reserved","entered"])

static func _crossing_transition(world: SandboxWorld,npc_id: String,next: String,prior: Array) -> bool:
	var trip: Dictionary=world.resident(npc_id).get("local_pedestrian_trip",{})
	if not trip.get("status","") in ["walking","offscreen"] \
			or not prior.has(trip.get("crossing_state","approach")): return false
	trip["crossing_state"]=next
	world._record("local_pedestrian_crossing_"+next,npc_id,{"site":PATCHWORKS_PARTS})
	return true

static func withdraw(world: SandboxWorld,npc_id: String,where: Vector2) -> bool:
	var trip: Dictionary=world.resident(npc_id).get("local_pedestrian_trip",{})
	var body: Rect2=Rect2(where-Vector2.ONE*7.0,Vector2.ONE*14.0)
	if trip.get("status","")!="walking" or trip.get("crossing_state","")!="reserved" \
			or not where.is_finite() or not SandboxStreetModule.NORTH_SIDEWALK.encloses(body): return false
	trip["crossing_state"]="approach"
	world._record("local_pedestrian_crossing_withdrawn",npc_id,{"site":PATCHWORKS_PARTS,"x":where.x,"y":where.y})
	return true

static func cancel(world: SandboxWorld,npc_id: String,where: Vector2) -> bool:
	var trip: Dictionary=world.resident(npc_id).get("local_pedestrian_trip",{})
	if trip.get("status","")!="walking" or not where.is_finite(): return false
	var body: Rect2=Rect2(where-Vector2.ONE*SandboxStreetModule.PEDESTRIAN_RADIUS,
			Vector2.ONE*SandboxStreetModule.PEDESTRIAN_RADIUS*2.0)
	if not SandboxStreetModule.NORTH_SIDEWALK.encloses(body) \
			and not SandboxStreetModule.SOUTH_SIDEWALK.encloses(body): return false
	trip["status"]="cancelled"
	trip["cancelled"]=world.minute
	world._record("local_pedestrian_cancelled",npc_id,{"site":PATCHWORKS_PARTS,"x":where.x,"y":where.y})
	return true


# When the player leaves a loaded neighborhood, the native actor is removed.
# The world keeps the resident's one real trip and a timestamped progress
# anchor; distant travel requires no per-frame physics or extra NPC instance.
static func handoff(world: SandboxWorld, npc_id: String, progress: float, where: Vector2=Vector2.INF) -> bool:
	var npc: Dictionary=world.resident(npc_id)
	var trip: Dictionary=npc.get("local_pedestrian_trip",{})
	if trip.get("status","")!="walking" or not is_finite(progress) \
			or progress<0.0 or progress>=1.0:
		return false
	if not where.is_finite(): where=SandboxStreetModule.position_at(progress,int(trip.get("slot",0)))
	if where.distance_to(SandboxStreetModule.position_at(progress,int(trip.get("slot",0))))>24.0: return false
	trip["handoff_x"]=where.x
	trip["handoff_y"]=where.y
	trip["status"]="offscreen"
	trip["handoff_minute"]=world.minute
	trip["handoff_progress"]=snappedf(progress,0.000001)
	npc["local_pedestrian_trip"]=trip
	world._record("local_pedestrian_handoff",npc_id,{"site":PATCHWORKS_PARTS,
			"progress":trip["handoff_progress"],"x":where.x,"y":where.y})
	return true

static func offscreen_progress(world: SandboxWorld, npc_id: String) -> float:
	var trip: Dictionary=world.resident(npc_id).get("local_pedestrian_trip",{})
	if trip.get("status","")!="offscreen":
		return -1.0
	var seconds_as_minutes: float=float(world.minute-int(trip["handoff_minute"]))
	return clampf(float(trip["handoff_progress"]) + seconds_as_minutes / \
			SandboxStreetModule.OFFSCREEN_MINUTES,0.0,1.0)

# Shared by native reentry and the far renderer: preserve the actual saved
# collision pose, then merge back to the authored path over the same distance.
static func offscreen_position(world: SandboxWorld, npc_id: String, fraction: float=0.0) -> Vector2:
	var trip: Dictionary=world.resident(npc_id).get("local_pedestrian_trip",{})
	if trip.get("status","")!="offscreen": return Vector2.INF
	var slot: int=int(trip.get("slot",0))
	var old_phase: float=float(trip["handoff_progress"])
	var phase: float=clampf(offscreen_progress(world,npc_id)+
			clampf(fraction,0.0,1.0)/SandboxStreetModule.OFFSCREEN_MINUTES,0.0,1.0)
	var origin: Vector2=SandboxStreetModule.position_at(old_phase,slot)
	var anchor: Vector2=Vector2(float(trip.get("handoff_x",origin.x)),float(trip.get("handoff_y",origin.y)))
	var result: Vector2=SandboxStreetModule.position_at(phase,slot)+(anchor-origin)*clampf(1.0-(phase-old_phase)/.15,0.0,1.0)
	# A fractional visual preview cannot assert physical clearance ahead of
	# World's coarse crossing transition. Reentry starts on the same safe
	# side; subsequent genuine native movement may clear the reservation.
	if not SandboxStreetModule.crossing_finished(offscreen_progress(world,npc_id),slot) \
			and SandboxStreetModule.crossing_clear(result):
		result.y=SandboxStreetModule.crossing_clear_y()-.01
	return result

# Used only when no native pedestrian actor is available. A missing scene
# object is NOT evidence that the zebra is empty: live walkers fail closed,
# and offscreen travelers clear it only after world-owned distance passes
# the same collision-body boundary used by their native counterpart.
static func crossing_cleared_without_actor(world: SandboxWorld, loaded_ids: Array[String]=[]) -> bool:
	for npc in world.residents:
		if loaded_ids.has(str(npc["id"])): continue
		var trip: Dictionary=npc.get("local_pedestrian_trip",{})
		if trip.get("site","")!=PATCHWORKS_PARTS:
			continue
		match str(trip.get("status","")):
			"walking":
				return false
			"offscreen":
				if not SandboxStreetModule.crossing_finished(
						offscreen_progress(world,str(npc["id"])),int(trip.get("slot",0))):
					return false
	return true


static func resume(world: SandboxWorld, npc_id: String) -> float:
	var npc: Dictionary=world.resident(npc_id)
	var trip: Dictionary=npc.get("local_pedestrian_trip",{})
	if trip.get("status","")!="offscreen":
		return -1.0
	var progress: float=offscreen_progress(world,npc_id)
	if progress>=1.0:
		arrive(world,npc_id,PATCHWORKS_PARTS)
		return -1.0
	trip["status"]="walking"
	npc["local_pedestrian_trip"]=trip
	world._record("local_pedestrian_resumed",npc_id,{"site":PATCHWORKS_PARTS,
			"progress":snappedf(progress,0.000001)})
	return progress

static func advance_offscreen(world: SandboxWorld) -> void:
	# Deterministic coarse completion, independent of native frame timings.
	for npc in world.residents:
		var trip: Dictionary=npc.get("local_pedestrian_trip",{})
		if trip.get("status","")!="offscreen": continue
		var progress: float=offscreen_progress(world,str(npc["id"]))
		if SandboxStreetModule.crossing_finished(progress,int(trip.get("slot",0))): clear(world,str(npc["id"]))
		if progress>=1.0: arrive(world,str(npc["id"]),PATCHWORKS_PARTS)

static func arrive(world: SandboxWorld, npc_id: String, site: String) -> bool:
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty():
		return false
	var trip: Dictionary = npc.get("local_pedestrian_trip", {})
	if trip.get("site", "") != site or not ["walking", "offscreen"].has(trip.get("status", "")):
		return false
	if trip.get("status","")=="offscreen" and offscreen_progress(world,npc_id)<1.0: return false
	# This counter is a local site inside the garage's coarse world location.
	# It does not teleport an NPC between dispatch/region graph nodes.
	trip["status"] = "arrived"
	trip["arrived"] = world.minute
	npc["local_pedestrian_trip"] = trip
	world._record("local_pedestrian_arrived", npc_id, {"site": site})
	return true

static func valid_history(npc: Dictionary, events: Array, minute: int) -> bool:
	var trip: Variant=npc.get("local_pedestrian_trip",{})
	if not (trip is Dictionary):
		return false
	var state: String=""
	var began: int=-1
	var handed_off: int=-1
	var last_progress: float=0.0
	var arrival_at: int=-1
	var cancelled_at: int=-1
	var crossing_state: String="approach"
	var slot: int=0
	var anchor: Vector2=Vector2.ZERO
	for evt in events:
		if evt.get("subject","") != npc.get("id",""):
			continue
		var kind: String=str(evt.get("kind",""))
		if not kind.begins_with("local_pedestrian_"):
			continue
		if evt.get("detail",{}).get("site","")!=PATCHWORKS_PARTS:
			return false
		var when: int=int(evt.get("minute",-1))
		if when>minute:
			return false
		match kind:
			"local_pedestrian_departed":
				if state!="" or evt.get("detail",{}).get("from","")!="garage":
					return false
				state="walking"
				began=when
				slot=int(evt.get("detail",{}).get("slot",0))
				if slot<0 or slot>1: return false
			"local_pedestrian_handoff":
				var phase: Variant=evt.get("detail",{}).get("progress",null)
				if state!="walking" or not (phase is float or phase is int) \
						or not is_finite(float(phase)) or float(phase)<0.0 or float(phase)>=1.0:
					return false
				state="offscreen"
				handed_off=when
				last_progress=float(phase)
				anchor=Vector2(float(evt["detail"].get("x",SandboxStreetModule.position_at(last_progress,slot).x)),
						float(evt["detail"].get("y",SandboxStreetModule.position_at(last_progress,slot).y)))
				if not anchor.is_finite() or anchor.distance_to(SandboxStreetModule.position_at(last_progress,slot))>24.0: return false
			"local_pedestrian_resumed":
				var resumed: Variant=evt.get("detail",{}).get("progress",null)
				var expected: float=snappedf(clampf(last_progress+float(when-handed_off)/SandboxStreetModule.OFFSCREEN_MINUTES,0.0,1.0),.000001)
				if state!="offscreen" or not (resumed is float or resumed is int) \
						or not is_finite(float(resumed)) or not is_equal_approx(float(resumed),expected) or float(resumed)>=1.0:
					return false
				state="walking"
			"local_pedestrian_crossing_reserved", "local_pedestrian_crossing_entered", "local_pedestrian_crossing_cleared":
				if not state in ["walking","offscreen"]: return false
				var next: String=kind.trim_prefix("local_pedestrian_crossing_")
				if next=="reserved" and crossing_state!="approach": return false
				if next=="entered" and crossing_state!="reserved": return false
				if next=="cleared" and not crossing_state in ["reserved","entered"]: return false
				crossing_state=next
			"local_pedestrian_crossing_withdrawn":
				var where: Vector2=Vector2(float(evt["detail"].get("x",INF)),float(evt["detail"].get("y",INF)))
				if state!="walking" or crossing_state!="reserved" or not where.is_finite() \
						or not SandboxStreetModule.NORTH_SIDEWALK.encloses(Rect2(where-Vector2.ONE*7.0,Vector2.ONE*14.0)): return false
				crossing_state="approach"
			"local_pedestrian_cancelled":
				if state!="walking": return false
				var where: Vector2=Vector2(float(evt["detail"].get("x",INF)),float(evt["detail"].get("y",INF)))
				var body: Rect2=Rect2(where-Vector2.ONE*7.0,Vector2.ONE*14.0)
				if not where.is_finite() or (not SandboxStreetModule.NORTH_SIDEWALK.encloses(body) and not SandboxStreetModule.SOUTH_SIDEWALK.encloses(body)): return false
				state="cancelled"
				cancelled_at=when
			"local_pedestrian_arrived":
				if not ["walking","offscreen"].has(state) or arrival_at>=0:
					return false
				if state=="offscreen" and last_progress+float(when-handed_off)/SandboxStreetModule.OFFSCREEN_MINUTES<1.0: return false
				state="arrived"
				arrival_at=when
			_:
				return false
	if trip.is_empty():
		return state==""
	if state!=trip.get("status","") or trip.get("site","")!=PATCHWORKS_PARTS \
			or began!=int(trip.get("started",-1)) or began<SandboxWorld.START_MINUTE or int(trip.get("slot",0))!=slot or trip.get("crossing_state","approach")!=crossing_state:
		return false
	# The last recorded spatial anchor is immutable even after resuming or
	# arriving. Otherwise a saved world could silently rewrite an offscreen trip.
	if handed_off>=0:
		if handed_off!=int(trip.get("handoff_minute",-1)) or handed_off<began:
			return false
		if not Vector2(float(trip.get("handoff_x",anchor.x)),float(trip.get("handoff_y",anchor.y))).is_equal_approx(anchor): return false
		var progress: Variant=trip.get("handoff_progress",null)
		if not (progress is float or progress is int) or not is_finite(float(progress)) \
				or not is_equal_approx(float(progress),last_progress):
			return false
	if state=="walking" and (npc.get("location","")!="garage" \
			or not str(npc.get("taxi_offer","")).is_empty()):
		return false
	if state=="cancelled": return cancelled_at==int(trip.get("cancelled",-1)) and arrival_at<0
	return (state!="arrived" and arrival_at<0) or (state=="arrived" \
			and arrival_at==int(trip.get("arrived",-1)) and arrival_at>=began)

static func valid_presentation(world: SandboxWorld,state: Variant) -> bool:
	if state is Dictionary and not SandboxJunctionTraffic.valid_snapshot(state.get("junction",{})): return false
	if state is Dictionary:
		for key in ["car_speed","follower_speed"]:
			if not state.has(key): continue
			var value: Variant=state[key]
			if not (value is float or value is int) or not is_finite(float(value)) or float(value)<0.0 \
					or float(value)>SandboxVehicleKinematics.CRUISE+0.001: return false
	if not state is Dictionary: return false
	var actors: Variant=state.get("actors",{})
	if not state.has("actors") and not str(state.get("npc_id","")).is_empty():
		actors={str(state["npc_id"]):state}
	if not actors is Dictionary or actors.size()>2: return false
	for npc in world.residents:
		if npc.get("local_pedestrian_trip",{}).get("status","")=="walking" and not actors.has(str(npc["id"])): return false
	for id in actors:
		var saved: Variant=actors[id]
		var trip: Dictionary=world.resident(str(id)).get("local_pedestrian_trip",{})
		if not saved is Dictionary or saved.get("npc_id","")!=id or not trip.get("status","") in ["walking","offscreen","arrived"]: return false
		for key in ["pedestrian_x","pedestrian_y"]:
			var value: Variant=saved.get(key,null)
			if not (value is float or value is int) or not is_finite(float(value)): return false
		for key in ["crossing_reserved","crossing_completed","did_arrive"]:
			if not saved.get(key,null) is bool: return false
		if bool(saved["crossing_reserved"]) and trip.get("crossing_state","approach")=="approach": return false
		var point: Vector2=Vector2(float(saved["pedestrian_x"]),float(saved["pedestrian_y"]))
		var slot: int=int(trip.get("slot",0))
		var phase: float=SandboxStreetModule.progress_of(point,slot)
		if point.distance_to(SandboxStreetModule.position_at(phase,slot))>24.0: return false
		if bool(saved["did_arrive"])!=(trip.get("status","")=="arrived"): return false
		if trip.get("status","")=="arrived" and point.distance_to(SandboxStreetModule.destination(slot))>9.0: return false
		if trip.get("status","")=="arrived" and (world.resident(str(id)).get("location","")!="garage" \
				or int(world.resident(str(id)).get("transit_until",0))>0 \
				or not str(world.resident(str(id)).get("taxi_offer","")).is_empty()): return false
	return true
