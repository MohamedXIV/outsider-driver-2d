class_name SandboxLocalPedestrianTrip
extends RefCounted

# A genuine resident's local errand belongs to SandboxWorld. Godot agents own
# visible movement; the world validates and records intent and arrival once.
# This bounded experiment does not change city-wide taxi offer/route semantics.
const PATCHWORKS_PARTS: String = "patchworks:parts_counter"

static func candidate(world: SandboxWorld) -> String:
	# Continue an existing errand before picking another resident. No scripted
	# first passenger, duplicate actor, or synthetic extra simulation person.
	for npc in world.residents:
		var active: Dictionary = npc.get("local_pedestrian_trip", {})
		if active.get("site", "") == PATCHWORKS_PARTS and active.get("status", "") in ["walking", "offscreen"]:
			return str(npc["id"])
	for npc in world.residents:
		# Completed residents do not start the same unique local errand twice.
		if not npc.get("local_pedestrian_trip", {}).is_empty():
			continue
		if str(npc.get("location", "")) != "garage" or str(npc.get("activity", "")) != "available":
			continue
		if not ["supplies", "work"].has(str(npc.get("purpose", ""))) or int(npc.get("need", 0)) < 30:
			continue
		if int(npc.get("cooldown_until", 0)) > world.minute or not str(npc.get("taxi_offer", "")).is_empty():
			continue
		var pending: bool = false
		for offer in world.offers:
			if offer.get("npc_id", "") == npc.get("id", "") and offer.get("status", "") in ["open", "accepted"]:
				pending = true
				break
		if not pending:
			return str(npc["id"])
	return ""

static func begin(world: SandboxWorld, npc_id: String, site: String) -> bool:
	if site != PATCHWORKS_PARTS:
		return false
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty() or str(npc.get("location", "")) != "garage" \
			or npc.get("activity", "") != "available":
		return false
	if not npc.get("local_pedestrian_trip", {}).is_empty():
		return false
	if not ["supplies", "work"].has(str(npc.get("purpose", ""))):
		return false
	for offer in world.offers:
		if offer.get("npc_id", "") == npc_id and offer.get("status", "") in ["open", "accepted"]:
			return false
	# A nearby service errand does not erase the resident's independent long
	# distance need or authorize the player to accept a licensed taxi fare.
	npc["local_pedestrian_trip"] = {"site": site, "status": "walking", "started": world.minute}
	world._record("local_pedestrian_departed", npc_id, {"from": "garage", "site": site})
	return true


# When the player leaves a loaded neighborhood, the native actor is removed.
# The world keeps the resident's one real trip and a timestamped progress
# anchor; distant travel requires no per-frame physics or extra NPC instance.
static func handoff(world: SandboxWorld, npc_id: String, progress: float) -> bool:
	var npc: Dictionary=world.resident(npc_id)
	var trip: Dictionary=npc.get("local_pedestrian_trip",{})
	if trip.get("status","")!="walking" or not is_finite(progress) \
			or progress<0.0 or progress>=1.0:
		return false
	trip["status"]="offscreen"
	trip["handoff_minute"]=world.minute
	trip["handoff_progress"]=snappedf(progress,0.000001)
	npc["local_pedestrian_trip"]=trip
	world._record("local_pedestrian_handoff",npc_id,{"site":PATCHWORKS_PARTS,
			"progress":trip["handoff_progress"]})
	return true

static func offscreen_progress(world: SandboxWorld, npc_id: String) -> float:
	var trip: Dictionary=world.resident(npc_id).get("local_pedestrian_trip",{})
	if trip.get("status","")!="offscreen":
		return -1.0
	var seconds_as_minutes: float=float(world.minute-int(trip["handoff_minute"]))
	return clampf(float(trip["handoff_progress"]) + seconds_as_minutes / \
			SandboxStreetModule.OFFSCREEN_MINUTES,0.0,1.0)

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
		if npc.get("local_pedestrian_trip",{}).get("status","")=="offscreen" \
				and offscreen_progress(world,str(npc["id"]))>=1.0:
			arrive(world,str(npc["id"]),PATCHWORKS_PARTS)

static func arrive(world: SandboxWorld, npc_id: String, site: String) -> bool:
	var npc: Dictionary = world.resident(npc_id)
	if npc.is_empty():
		return false
	var trip: Dictionary = npc.get("local_pedestrian_trip", {})
	if trip.get("site", "") != site or not ["walking", "offscreen"].has(trip.get("status", "")):
		return false
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
			"local_pedestrian_handoff":
				var phase: Variant=evt.get("detail",{}).get("progress",null)
				if state!="walking" or not (phase is float or phase is int) \
						or not is_finite(float(phase)) or float(phase)<0.0 or float(phase)>=1.0:
					return false
				state="offscreen"
				handed_off=when
				last_progress=float(phase)
			"local_pedestrian_resumed":
				var resumed: Variant=evt.get("detail",{}).get("progress",null)
				if state!="offscreen" or not (resumed is float or resumed is int) \
						or not is_finite(float(resumed)) or float(resumed)<last_progress or float(resumed)>=1.0:
					return false
				state="walking"
			"local_pedestrian_arrived":
				if not ["walking","offscreen"].has(state) or arrival_at>=0:
					return false
				state="arrived"
				arrival_at=when
			_:
				return false
	if trip.is_empty():
		return state==""
	if state!=trip.get("status","") or trip.get("site","")!=PATCHWORKS_PARTS \
			or began!=int(trip.get("started",-1)) or began<SandboxWorld.START_MINUTE:
		return false
	# The last recorded spatial anchor is immutable even after resuming or
	# arriving. Otherwise a saved world could silently rewrite an offscreen trip.
	if handed_off>=0:
		if handed_off!=int(trip.get("handoff_minute",-1)) or handed_off<began:
			return false
		var progress: Variant=trip.get("handoff_progress",null)
		if not (progress is float or progress is int) or not is_finite(float(progress)) \
				or not is_equal_approx(float(progress),last_progress):
			return false
	if state=="walking" and (npc.get("location","")!="garage" \
			or not str(npc.get("taxi_offer","")).is_empty()):
		return false
	return (state!="arrived" and arrival_at<0) or (state=="arrived" \
			and arrival_at==int(trip.get("arrived",-1)) and arrival_at>=began)
