extends SceneTree

func _initialize() -> void: call_deferred("_run")

static func seeded_ride() -> Dictionary:
	for seed in range(1,90):
		var world: SandboxWorld=SandboxWorld.new(seed)
		for offer in world.open_offers():
			if offer.get("origin")!="garage" or offer.get("channel")=="official": continue
			if SandboxRoads.travel_minutes("garage",str(offer["destination"]))<9: continue
			if not world.accept(str(offer["id"])): continue
			if world.rider_initiative.get("status","")=="scheduled":
				return {"world":world,"offer_id":str(offer["id"])}
	return {}

func _run() -> void:
	var found: Dictionary=seeded_ride()
	assert(not found.is_empty(),"Must use a real dispatch fare, not a synthetic rider")
	var world: SandboxWorld=found["world"]
	var offer_id: String=str(found["offer_id"])
	var prompt: Dictionary=world.rider_initiative.duplicate(true)
	assert(prompt["offer_id"]==offer_id)
	assert(prompt["npc_id"]==world.offer_by_id(offer_id)["npc_id"])
	assert(prompt["due"]>world.minute and prompt["due"]<world.minute+world.remaining_minutes)
	assert(world.events.filter(func(e: Dictionary)->bool:
		return e.get("kind","")=="rider_initiative_scheduled" and e.get("subject","")==offer_id).size()==1)
	var baseline: Dictionary=world.snapshot()
	assert(SandboxWorld.new().restore_snapshot(baseline))
	assert(world.advance(int(prompt["due"])-world.minute))
	assert(world.rider_initiative["status"]=="pending")
	var current: Dictionary=world.snapshot()
	assert(SandboxWorld.new().restore_snapshot(current),"Pending question must persist")
	assert(not world.answer_rider_initiative("invented"))
	var npc: Dictionary=world.resident(str(prompt["npc_id"]))
	var understood: bool=SandboxRiderInitiative.understood(world)
	var response: String="deflect" if understood else "silent"
	var old_trust: int=int(npc["trust"])
	var old_scrutiny: int=int(npc["driver_scrutiny"])
	assert(not SandboxRiderInitiative.question(world,"ar").is_empty())
	assert(world.answer_rider_initiative(response))
	assert(not world.answer_rider_initiative(response),"A rider must not nag repeatedly")
	assert(int(npc["trust"])-old_trust==(0 if response=="deflect" else -1))
	assert(int(npc["driver_scrutiny"])-old_scrutiny==(
			1 if response=="deflect" and npc["temperament"]=="cautious" else 0))
	var answered: Dictionary=world.snapshot()
	assert(SandboxWorld.new().restore_snapshot(answered))
	var tampered: Dictionary=answered.duplicate(true)
	tampered["rider_initiative"]["topic"]="familiar" if prompt["topic"]!="familiar" else "route"
	assert(not SandboxWorld.new().restore_snapshot(tampered),"Forged question must not restore")
	tampered=answered.duplicate(true)
	for person in tampered["residents"]:
		if person.get("id")==prompt["npc_id"]: person["driver_scrutiny"]=999
	assert(not SandboxWorld.new().restore_snapshot(tampered),"Forged rider observation must not restore")
	assert(world.advance(world.remaining_minutes))
	assert(world.rider_initiative.is_empty())
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()),"Completed fare with closed question must restore")
	assert(world.events.filter(func(e: Dictionary)->bool:
		return e.get("kind","")=="rider_initiative_closed" and e.get("subject","")==offer_id).size()==1)
	assert(world.events.filter(func(e: Dictionary)->bool:
		return e.get("kind","")=="fare_settled" and e.get("subject","")==offer_id).size()==1)
	print("RIDER_INITIATIVE_PASS real ride, deterministic pending, language guard, answer, provenance and no duplicates")
	quit()
