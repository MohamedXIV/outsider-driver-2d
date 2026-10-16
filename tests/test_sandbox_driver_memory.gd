extends SceneTree

func _initialize() -> void:
	var w: SandboxWorld = SandboxWorld.new(8)
	var chosen: Dictionary = {}
	var remote: Dictionary = {}
	for o in w.open_offers():
		if o["origin"] == "docks" and o["channel"] != "official" and chosen.is_empty():
			chosen = o
		elif o["origin"] != "docks" and remote.is_empty():
			remote = o
	assert(not chosen.is_empty() and not remote.is_empty())
	var id: String = str(chosen["npc_id"])
	assert(w.decline(str(remote["id"])))
	assert(w.resident(str(remote["npc_id"]))["driver_memories"].is_empty())
	assert(w.accept(str(chosen["id"])))
	assert(w.resident(id)["driver_memories"].is_empty())
	assert(w.advance(w.remaining_minutes))
	var person: Dictionary = w.resident(id)
	assert(SandboxDriverMemory.recognizes(person))
	assert(SandboxDriverMemory.significance(person) == "persistent")
	assert(person["driver_memories"].size() == 1 and person["driver_identity_facts"].is_empty())
	var mem: Dictionary = person["driver_memories"][0]
	assert(mem["kind"] == SandboxDriverMemory.COMPLETED)
	var source: Dictionary = {}
	for event in w.events:
		if event["id"] == mem["source"]:
			source = event
	assert(source["kind"] == "fare_settled" and source["subject"] == chosen["id"])
	var followup: Dictionary = {}
	for step in range(150):
		for offer in w.open_offers():
			if offer["npc_id"] == id and offer["id"] != chosen["id"]:
				followup = offer
				break
		if not followup.is_empty():
			break
		assert(w.advance(10))
	if followup.is_empty() or followup["origin"] != w.player_district:
		push_error("No locally reachable repeat passenger demand")
		quit(2)
		return
	var talk: SandboxConversation = SandboxConversation.new()
	assert(talk.open(w, str(followup["id"]), self))
	assert(talk.recognizes_driver() and not talk.understood())
	assert(talk.current_frame()["text"] == SandboxLanguagePresentation.source_line(
			str(person["language"]), "intro_repeat"))
	assert(not str(talk.current_frame()["text"]).contains("taxi"))
	var save: String = "user://s3-returning-passenger.json"
	assert(SandboxSave.save_world(w, save, talk.snapshot()))
	var saved: Dictionary = SandboxSave.load_bundle(save)
	assert(not saved.is_empty())
	var loaded: SandboxWorld = saved["world"]
	var recovered: SandboxConversation = SandboxConversation.new()
	assert(recovered.restore(loaded, saved["dialogue"], self))
	assert(recovered.recognizes_driver())
	assert(recovered.current_frame() == talk.current_frame())
	assert(loaded.resident(id)["driver_memories"] == person["driver_memories"])
	assert(loaded.accept(str(followup["id"])))
	assert(loaded.advance(loaded.remaining_minutes))
	assert(SandboxDriverMemory.significance(loaded.resident(id)) == "significant")
	assert(loaded.resident(id)["driver_identity_facts"].is_empty())
	assert(not loaded.accept(str(followup["id"])))
	var forged: Dictionary = loaded.snapshot()
	forged["residents"][1]["driver_memories"][0]["source"] = "event:forged"
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = loaded.snapshot()
	forged["residents"][1]["driver_identity_facts"]["human"] = true
	assert(not SandboxWorld.new().restore_snapshot(forged))
	var other: SandboxWorld = SandboxWorld.new(9)
	var replay: SandboxWorld = SandboxWorld.new(9)
	assert(other.advance(1440) and replay.advance(1440))
	assert(other.snapshot() == replay.snapshot())
	print("SANDBOX_DRIVER_MEMORY_PASS")
	quit(0)
