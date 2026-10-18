class_name SandboxRiderInitiative
extends RefCounted

# A rider, not the driver, chooses whether and when to speak during a genuine
# accepted fare. No RNG state, omniscient identity detection or second clock.
const TOPICS: Array[String] = ["route", "curiosity", "familiar"]
const ANSWERS: Array[String] = ["brief", "deflect", "silent"]

static func _rider_number(npc: Dictionary) -> int:
	return int(str(npc.get("id", "npc:00")).trim_prefix("npc:"))

static func _understands(world: SandboxWorld, npc: Dictionary) -> bool:
	return SandboxKnowledge.understands(str(npc.get("language", "")), world.modules_installed) \
			or bool(world.common_requests.get(world.active_offer_id, false))

static func schedule(world: SandboxWorld) -> bool:
	if not world.is_travelling() or world.active_offer_id.is_empty() \
			or not world.rider_initiative.is_empty() or world.remaining_minutes < 8:
		return false
	var offer: Dictionary = world.offer_by_id(world.active_offer_id)
	var npc: Dictionary = world.resident(str(offer.get("npc_id", "")))
	if offer.get("status", "") != "accepted" or npc.is_empty(): return false
	# 9-in-10 seeded rides are eligible, NOT 90% of every minute. Quiet riders
	# stay quiet for their entire journey; the source offer provides entropy.
	var bucket: int = posmod(world.seed * 19 + _rider_number(npc) * 7 \
			+ int(offer.get("created_at", 0)) * 3, 10)
	if bucket == 0: return false
	var topic: String = "familiar" if SandboxDriverMemory.recognizes(npc) else (
			"route" if world.route_nodes.size() > 2 else "curiosity")
	var delay: int = maxi(2, mini(6, world.remaining_minutes / 4))
	world.rider_initiative = {"status": "scheduled", "offer_id":world.active_offer_id,
			"npc_id":str(npc["id"]), "topic":topic, "due":world.minute + delay}
	world._record("rider_initiative_scheduled",world.active_offer_id,{
			"npc_id":npc["id"], "topic":topic,"due":world.minute+delay})
	return true

static func tick(world: SandboxWorld) -> void:
	var prompt: Dictionary = world.rider_initiative
	if prompt.get("status", "") != "scheduled" or world.minute < int(prompt.get("due", 0)):
		return
	if not world.is_travelling() or world.active_offer_id != prompt.get("offer_id", ""):
		return
	prompt["status"] = "pending"
	world._record("rider_initiative_started",str(prompt["offer_id"]),{
		"npc_id":prompt["npc_id"],"topic":prompt["topic"]
	})

static func answer(world: SandboxWorld, response: String) -> bool:
	var prompt: Dictionary = world.rider_initiative
	if prompt.get("status", "") != "pending" or not ANSWERS.has(response) \
			or world.active_offer_id != prompt.get("offer_id", "") or not world.is_travelling():
		return false
	var npc: Dictionary = world.resident(str(prompt.get("npc_id", "")))
	if npc.is_empty() or (response != "silent" and not _understands(world,npc)):
		return false
	# Social consequences are grounded in a witnessed answer: no passenger
	# can know that the driver is human from merely asking a question.
	var trust_delta: int = 1 if response == "brief" else (-1 if response == "silent" else 0)
	var scrutiny_delta: int = 1 if response == "deflect" and npc.get("temperament") == "cautious" else 0
	npc["trust"] = int(npc["trust"]) + trust_delta
	npc["driver_scrutiny"] = int(npc.get("driver_scrutiny", 0)) + scrutiny_delta
	prompt["status"] = "answered"
	prompt["answer"] = response
	world._record("rider_initiative_answered",str(prompt["offer_id"]),{
			"npc_id":prompt["npc_id"],"answer":response,"trust_delta":trust_delta,
			"scrutiny_delta":scrutiny_delta})
	return true

static func close(world: SandboxWorld) -> void:
	var prompt: Dictionary = world.rider_initiative
	if prompt.is_empty(): return
	world._record("rider_initiative_closed",str(prompt["offer_id"]),{
			"npc_id":prompt["npc_id"], "previous_status":prompt["status"]
	})
	world.rider_initiative = {}

static func understood(world: SandboxWorld) -> bool:
	var npc: Dictionary = world.resident(str(world.rider_initiative.get("npc_id", "")))
	return not npc.is_empty() and _understands(world,npc)

static func question(world: SandboxWorld, locale: String) -> String:
	var prompt: Dictionary = world.rider_initiative
	if prompt.get("status","") != "pending": return ""
	var npc: Dictionary = world.resident(str(prompt.get("npc_id","")))
	if npc.is_empty(): return ""
	if not _understands(world,npc):
		var key: String = "intro_repeat" if prompt["topic"]=="familiar" else (
				"travel_city" if prompt["topic"]=="route" else "travel_person")
		return SandboxLanguagePresentation.source_line(str(npc["language"]),key)
	var offer: Dictionary = world.offer_by_id(str(prompt["offer_id"]))
	match str(prompt["topic"]):
		"familiar":
			return "Have we met on this route before?" if locale!="ar" else "ألم نلتق في هذه السيارة من قبل؟"
		"route":
			if locale=="ar":
				var district: String = str(SandboxLanguagePresentation.AR_DISTRICTS.get(str(offer["destination"]), ""))
				return "هل هذا هو الطريق المعتاد إلى %s؟" % district
			return "Is this the usual road to %s?" % SandboxRoads.location_name(str(offer["destination"]))
		_:
			return "You are quiet. Long shift?" if locale!="ar" else "أنت قليل الكلام. هل تعمل منذ وقت طويل؟"

# Event validation detects invented initiation, answer and signed response.
# Historical answered rides can be closed without keeping phantom pending UI.
static func valid_history(snapshot: Dictionary) -> bool:
	var events_value: Variant = snapshot.get("events",[])
	var offers_value: Variant = snapshot.get("offers",[])
	var residents_value: Variant = snapshot.get("residents",[])
	var state: Variant = snapshot.get("rider_initiative",{})
	if not (events_value is Array) or not (offers_value is Array) \
			or not (residents_value is Array) or not (state is Dictionary):
		return false
	var events: Array = events_value
	var offers: Array = offers_value
	for evt in events:
		if not (evt is Dictionary) or not (evt.get("detail",{}) is Dictionary): return false
	for offer in offers:
		if not (offer is Dictionary): return false
	for npc in residents_value:
		if not (npc is Dictionary): return false
	var attempts: Dictionary = {}
	var settled: Dictionary = {}
	var recorded_scrutiny: Dictionary = {}
	for evt in events:
		var kind: String = str(evt.get("kind", ""))
		var offer_id: String = str(evt.get("subject",""))
		if kind == "offer_accepted": settled[offer_id] = true
		if not kind.begins_with("rider_initiative_"): continue
		var detail: Dictionary=evt.get("detail",{})
		var status: String=str(attempts.get(offer_id,{}).get("status",""))
		var matching: Dictionary={}
		for offer in offers:
			if offer.get("id","")==offer_id: matching=offer;break
		if matching.is_empty() or not settled.has(offer_id) \
				or detail.get("npc_id","")!=matching.get("npc_id",""): return false
		match kind:
			"rider_initiative_scheduled":
				if status!="" or not TOPICS.has(detail.get("topic","")) \
						or int(detail.get("due",-1))<=int(evt.get("minute",-1)): return false
				attempts[offer_id]={"status":"scheduled","offer_id":offer_id,
					"npc_id":detail["npc_id"],"topic":detail["topic"],"due":detail["due"]}
			"rider_initiative_started":
				if status!="scheduled" or detail.get("topic")!=attempts[offer_id]["topic"] \
						or int(evt.get("minute",-1))<int(attempts[offer_id]["due"]): return false
				attempts[offer_id]["status"]="pending"
			"rider_initiative_answered":
				var response: String=str(detail.get("answer",""))
				var trust: int=1 if response=="brief" else (-1 if response=="silent" else 0)
				if status!="pending" or not ANSWERS.has(response) \
						or int(detail.get("trust_delta",999))!=trust \
						or not [0,1].has(detail.get("scrutiny_delta",-1)): return false
				attempts[offer_id]["status"]="answered"
				attempts[offer_id]["answer"]=response
				recorded_scrutiny[str(detail["npc_id"])]=int(recorded_scrutiny.get(str(detail["npc_id"]),0))+int(detail["scrutiny_delta"])
			"rider_initiative_closed":
				if not ["scheduled","pending","answered"].has(status) \
						or detail.get("previous_status")!=status: return false
				attempts[offer_id]["status"]="closed"
			_:
				return false
	var live: Dictionary={}
	for id in attempts:
		var attempt: Dictionary=attempts[id]
		if attempt["status"]=="closed":continue
		if not live.is_empty() or id != snapshot.get("active_offer_id",""): return false
		live=attempt
	if live!=state: return false
	for npc in snapshot.get("residents",[]):
		if int(npc.get("driver_scrutiny",-1)) != int(recorded_scrutiny.get(str(npc.get("id","")),0)):
			return false
	return true
