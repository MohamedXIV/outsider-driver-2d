extends SceneTree

# Domain-owned knowledge must be earned from a real live NPC, not from Ink.
func _initialize() -> void:
	for device in SandboxKnowledge.DEVICES:
		var trial: SandboxWorld = SandboxWorld.new(8)
		assert(trial.select_starter_device(device))
		assert(trial.starter_device == device)
		assert(trial.knowledge.size() == 1)
		assert(trial.knows(str(SandboxKnowledge.FIRST_FACT[device])))
		assert(not trial.select_starter_device(device))
		assert(not trial.select_starter_device("gps"))
		assert(not trial.select_starter_device("pirate"))
		assert(not trial.knows(SandboxKnowledge.ROUTE_MARKER))
		var count: int = 0
		for event in trial.events:
			if event["kind"] == "knowledge_learned":
				count += 1
		assert(count == 1)
	var none: SandboxWorld = SandboxWorld.new(8)
	assert(not none.select_starter_device("bogus"))
	var translator: SandboxWorld = SandboxWorld.new(8)
	assert(translator.select_starter_device("translator"))
	var local_ids: Array[String] = []
	var trade_id: String = ""
	for offer in translator.open_offers():
		if offer["origin"] != "docks":
			continue
		var npc: Dictionary = translator.resident(str(offer["npc_id"]))
		if npc["language"] == "local" and offer["channel"] != "official":
			local_ids.append(str(offer["id"]))
		elif npc["language"] == "trade":
			trade_id = str(offer["id"])
	assert(local_ids.size() >= 1 and not trade_id.is_empty())
	var before: SandboxConversation = SandboxConversation.new()
	assert(before.open(translator, local_ids[0], self))
	assert(not before.understood() and not before.recognizes_route())
	assert(before.choose(0, translator))
	assert(before.current_frame()["text"].contains("Vrek shaa"))
	assert(not before.current_frame()["text"].contains(str(translator.offer_by_id(local_ids[0])["destination"])))
	assert(translator.knows(SandboxKnowledge.ROUTE_MARKER))
	var gain: int = translator.events.size()
	assert(not translator.observe_route_language(local_ids[0]), "Should not learn route marker twice.")
	assert(translator.events.size() == gain)
	var after: SandboxConversation = SandboxConversation.new()
	assert(after.open(translator, local_ids[0], self))
	assert(not after.understood() and after.recognizes_route())
	assert(after.choose(0, translator))
	assert(after.current_frame()["text"].contains(str(translator.offer_by_id(local_ids[0])["destination"])))
	assert(after.current_frame()["text"].contains("other words remain untranslated"))
	# Same learned marker works with a *different* local speaker/offer after travel.
	var persisted: String = "user://s2-translator-fixture.json"
	assert(SandboxSave.save_world(translator, persisted, after.snapshot()))
	var bundle: Dictionary = SandboxSave.load_bundle(persisted)
	assert(not bundle.is_empty())
	var restored: SandboxWorld = bundle["world"] as SandboxWorld
	assert(restored.starter_device == "translator")
	assert(restored.knows(SandboxKnowledge.ROUTE_MARKER))
	assert(restored.knowledge.size() == 2)
	var pending: SandboxConversation = SandboxConversation.new()
	assert(pending.restore(restored, bundle["dialogue"], self))
	assert(pending.current_frame()["text"] == after.current_frame()["text"])
	assert(pending.choose(1, restored))
	assert(pending.outcome() == "declined")
	var no_scan: SandboxWorld = SandboxWorld.new(8)
	assert(no_scan.select_starter_device("radio"))
	var radio: SandboxConversation = SandboxConversation.new()
	assert(radio.open(no_scan, local_ids[0], self))
	assert(radio.choose(0, no_scan))
	assert(not no_scan.knows(SandboxKnowledge.ROUTE_MARKER))
	var gps: SandboxWorld = SandboxWorld.new(8)
	assert(gps.select_starter_device("gps"))
	assert(gps.knows("map:district-graph") and not gps.knows(SandboxKnowledge.ROUTE_MARKER))
	assert(gps.knowledge != translator.knowledge)
	# Observing an official trade speaker never upgrades the local lexicon.
	assert(not gps.observe_route_language(trade_id))
	var future: SandboxWorld = SandboxWorld.new(9)
	assert(future.select_starter_device("translator"))
	var replay: SandboxWorld = SandboxWorld.new(9)
	assert(replay.select_starter_device("translator"))
	assert(JSON.stringify(future.snapshot()) == JSON.stringify(replay.snapshot()))
	var forged: Dictionary = translator.snapshot()
	forged["starter_device"] = "radio"
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = translator.snapshot()
	forged["knowledge"] = ["tool:local-phrase-scanner", "lexicon:local:route-marker", "lexicon:local:route-marker"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	print("SANDBOX_KNOWLEDGE_PASS")
	quit(0)
