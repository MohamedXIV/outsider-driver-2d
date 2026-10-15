extends SceneTree

# Reusable authored Ink intents are parameterized by actual NPC world context.
# Neither a passenger ID nor a job ID is hardcoded into the Ink file.
func _initialize() -> void:
	var world: SandboxWorld = SandboxWorld.new(8)
	var unknown_id: String = ""
	var trade_id: String = ""
	for offer in world.open_offers():
		if offer["origin"] != "docks":
			continue
		var npc: Dictionary = world.resident(str(offer["npc_id"]))
		if npc["language"] == "trade":
			trade_id = str(offer["id"])
		elif offer["channel"] != "official":
			unknown_id = str(offer["id"])
	assert(not unknown_id.is_empty() and not trade_id.is_empty(), "Seed 8 has two authentic dockside language contexts.")
	var unknown: SandboxConversation = SandboxConversation.new()
	var trade: SandboxConversation = SandboxConversation.new()
	assert(unknown.open(world, unknown_id, self))
	assert(trade.open(world, trade_id, self))
	assert(not unknown.understood() and trade.understood())
	print("S1_FRAME_UNKNOWN ", JSON.stringify(unknown.current_frame()))
	print("S1_FRAME_TRADE ", JSON.stringify(trade.current_frame()))
	if not unknown.current_frame()["tags"].has("intent:request_trip"):
		push_error("Missing request_trip tag from actual inkgd runtime frame.")
		quit(2)
		return
	assert(unknown.current_frame()["tags"].has("intent:request_trip"))
	assert(trade.current_frame()["tags"].has("intent:request_trip"))
	assert(unknown.current_frame()["text"] != trade.current_frame()["text"])
	var offer: Dictionary = world.offer_by_id(unknown_id)
	assert(not str(unknown.current_frame()["text"]).contains(str(offer["destination"])), "Alien speech was magically translated.")
	assert(trade.current_frame()["choices"].size() == 3)
	assert(unknown.choose(0, world), "Should ask destination before accepting.")
	assert(unknown.current_frame()["tags"].has("intent:ask_destination"))
	assert(unknown.current_frame()["choices"].size() == 2)
	assert(not str(unknown.current_frame()["text"]).contains(str(offer["destination"])), "Untranslated destination leaked in dialogue.")
	var path: String = "user://s1-npc-ink-saved-dialogue.json"
	assert(SandboxSave.save_world(world, path, unknown.snapshot()))
	var bundle: Dictionary = SandboxSave.load_bundle(path)
	assert(not bundle.is_empty())
	var restored_world: SandboxWorld = bundle["world"]
	var restored: SandboxConversation = SandboxConversation.new()
	assert(restored.restore(restored_world, bundle["dialogue"], self))
	assert(restored.offer_id == unknown_id and not restored.understood())
	assert(restored.current_frame()["tags"].has("intent:ask_destination"))
	assert(restored.current_frame()["text"] == unknown.current_frame()["text"])
	assert(restored.choose(0, restored_world))
	assert(restored.outcome() == "accepted")
	assert(restored_world.active_offer_id == unknown_id)
	assert(not restored_world.accept(unknown_id), "Ink could accept twice.")
	var fare: int = int(restored_world.offer_by_id(unknown_id)["fare"])
	assert(restored_world.advance(restored_world.remaining_minutes))
	assert(restored_world.credits == 12 + fare)
	assert(restored_world.offer_by_id(unknown_id)["status"] == "completed")
	var paid: int = 0
	for evt in restored_world.events:
		if evt["kind"] == "fare_settled" and evt["subject"] == unknown_id:
			paid += 1
	assert(paid == 1)
	# Choosing the same speech act for a *different live NPC* cannot mint fare.
	assert(trade.choose(1, world), "Trade speaker must offer the accept act.")
	assert(trade.outcome() == "blocked", "Licensed dispatch must reject the unlicensed player.")
	assert(world.active_offer_id.is_empty())
	# Another world instance has different actual people and requests but reuses Ink.
	var second: SandboxWorld = SandboxWorld.new(9)
	var source_offer: Dictionary = {}
	for candidate in second.open_offers():
		if second.resident(str(candidate["npc_id"]))["language"] == "trade" and candidate["channel"] != "official":
			source_offer = candidate
			break
	assert(not source_offer.is_empty())
	assert(second.reposition(str(source_offer["origin"])))
	var second_dialogue: SandboxConversation = SandboxConversation.new()
	assert(second_dialogue.open(second, str(source_offer["id"]), self))
	assert(second_dialogue.understood())
	assert(second_dialogue.current_frame()["tags"].has("intent:request_trip"))
	assert(second_dialogue.current_frame()["text"] != unknown.current_frame()["text"])
	assert(second_dialogue.choose(2, second))
	assert(second_dialogue.outcome() == "declined")
	assert(second.offer_by_id(str(source_offer["id"]))["status"] == "declined")
	assert(not second.decline(str(source_offer["id"])), "Duplicate decline changed the world.")
	var expires: SandboxConversation = SandboxConversation.new()
	assert(expires.open(world, unknown_id, self))
	assert(world.advance(100))
	assert(not expires.still_valid(world) and not expires.choose(1, world))
	print("SANDBOX_SEMANTIC_INK_PASS")
	quit(0)
