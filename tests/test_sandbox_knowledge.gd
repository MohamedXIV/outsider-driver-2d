extends SceneTree

# #32 replaces S2's partial learned marker, not adds another translator.
func _initialize() -> void:
	for bonus in SandboxKnowledge.DEVICES:
		var trial: SandboxWorld = SandboxWorld.new(8)
		assert(trial.modules_owned == ["trade"] and trial.modules_installed == ["trade"])
		assert(trial.select_starter_device(bonus))
		assert(trial.starter_device == bonus)
		assert(not trial.select_starter_device(bonus))
		assert(not trial.select_starter_device("translator"))
		assert(not trial.select_starter_device("gps"))
		if bonus == "module:local":
			assert(trial.modules_owned == ["trade", "local"])
			assert(trial.modules_installed == ["trade", "local"])
			assert(trial.knowledge.is_empty())
		else:
			assert(trial.knowledge.size() == 1)
			assert(trial.knows(str(SandboxKnowledge.FIRST_FACT[bonus])))
			assert(trial.modules_installed == ["trade"])
	assert(not SandboxWorld.new(8).select_starter_device("bogus"))
	var both_species: SandboxWorld = SandboxWorld.new(8)
	assert(both_species.resident("npc:01")["language"] == "local")
	assert(both_species.resident("npc:04")["language"] == "local")
	assert(both_species.resident("npc:01")["species"] != both_species.resident("npc:04")["species"])
	assert(both_species.resident("npc:02")["language"] == "cant")
	assert(both_species.resident("npc:07")["language"] == "cant")
	assert(both_species.resident("npc:02")["species"] != both_species.resident("npc:07")["species"])
	assert(SandboxKnowledge.understands("trade", both_species.modules_installed))
	assert(not SandboxKnowledge.understands("local", both_species.modules_installed))
	assert(not SandboxKnowledge.understands("cant", both_species.modules_installed))

	# Dockside native speaker cannot speak Common; no free universal fallback.
	var dock_request: String = ""
	for offer in both_species.open_offers():
		if offer["origin"] == "docks" and offer["npc_id"] == "npc:01":
			dock_request = str(offer["id"])
	assert(not dock_request.is_empty())
	var refused: SandboxConversation = SandboxConversation.new()
	assert(refused.open(both_species, dock_request, self))
	assert(not refused.understood())
	assert(refused.request_common(both_species, self))
	assert(not refused.understood())
	assert(both_species.common_requests[dock_request] == false)
	assert(not refused.request_common(both_species, self))
	assert(refused.choose(0, both_species))
	assert(not str(refused.current_frame()["text"]).contains("route marker for"))
	assert(not str(refused.current_frame()["text"]).contains(str(both_species.offer_by_id(dock_request)["destination"])))

	# The driver travels to the actual open physical market before purchasing.
	var world: SandboxWorld = SandboxWorld.new(8)
	assert(not world.buy_language_module("local"))
	assert(world.reposition("market"))
	assert(world.credits == 11)
	var market_offer: String = ""
	for offer in world.open_offers():
		if offer["origin"] == "market" and offer["npc_id"] == "npc:04":
			market_offer = str(offer["id"])
	assert(not market_offer.is_empty())
	var before: SandboxConversation = SandboxConversation.new()
	assert(before.open(world, market_offer, self))
	assert(not before.understood())
	assert(world.buy_language_module("local"))
	assert(world.credits == 3)
	assert(world.market_stock["local"] == 0)
	assert(world.modules_owned.has("local") and not world.modules_installed.has("local"))
	assert(not world.buy_language_module("local"), "Cannot pay twice for one owned module.")
	assert(not SandboxKnowledge.understands("local", world.modules_installed))
	assert(world.install_language_module("local"))
	assert(not world.install_language_module("local"), "Installation is idempotent.")
	assert(SandboxKnowledge.understands("local", world.modules_installed))
	assert(not SandboxKnowledge.understands("cant", world.modules_installed))
	assert(not before.understood(), "An open Ink frame cannot retroactively decode.")
	var after: SandboxConversation = SandboxConversation.new()
	assert(after.open(world, market_offer, self))
	assert(after.understood())
	assert(after.choose(0, world))
	assert(str(after.current_frame()["text"]).contains(str(world.offer_by_id(market_offer)["destination"])))
	assert(not str(after.current_frame()["text"]).contains("other words remain untranslated"))
	var saved: String = "user://language-modules-v10.json"
	assert(SandboxSave.save_world(world, saved, after.snapshot()))
	var bundle: Dictionary = SandboxSave.load_bundle(saved)
	assert(not bundle.is_empty())
	var restored: SandboxWorld = bundle["world"] as SandboxWorld
	assert(restored.credits == 3 and restored.market_stock["local"] == 0)
	assert(restored.modules_owned == world.modules_owned)
	assert(restored.modules_installed == world.modules_installed)
	var resumed: SandboxConversation = SandboxConversation.new()
	assert(resumed.restore(restored, bundle["dialogue"], self))
	assert(resumed.understood())
	assert(resumed.current_frame()["text"] == after.current_frame()["text"])
	assert(resumed.choose(1, restored))
	assert(resumed.outcome() == "declined")

	# Bilingual willingness belongs to that individual, not the species.
	var speaker: SandboxWorld = SandboxWorld.new(8)
	assert(speaker.reposition("market"))
	var fallback: SandboxConversation = SandboxConversation.new()
	assert(fallback.open(speaker, market_offer, self))
	assert(not fallback.understood())
	assert(fallback.request_common(speaker, self))
	assert(fallback.understood())
	assert(speaker.common_requests[market_offer] == true)
	assert(not fallback.request_common(speaker, self))
	var middle_save: String = "user://language-common-v10.json"
	assert(SandboxSave.save_world(speaker, middle_save, fallback.snapshot()))
	var common_bundle: Dictionary = SandboxSave.load_bundle(middle_save)
	var common_restored: SandboxWorld = common_bundle["world"] as SandboxWorld
	assert(common_restored.common_requests[market_offer])
	var common_resume: SandboxConversation = SandboxConversation.new()
	assert(common_resume.restore(common_restored, common_bundle["dialogue"], self))
	assert(common_resume.understood())

	# Cant has its own stable language surface before installation; the
	# compiled Ink semantics and choices remain exactly shared.
	var cant_speech_world: SandboxWorld = SandboxWorld.new(8)
	assert(cant_speech_world.reposition("clinic"))
	var cant_offer: String = ""
	for candidate in cant_speech_world.open_offers():
		if candidate["origin"] == "clinic" and candidate["npc_id"] == "npc:07":
			cant_offer = str(candidate["id"])
	assert(not cant_offer.is_empty())
	var cant_speech: SandboxConversation = SandboxConversation.new()
	assert(cant_speech.open(cant_speech_world, cant_offer, self))
	assert(not cant_speech.understood())
	assert(str(cant_speech.current_frame()["text"]).contains("Neh-vari tel'nuk"))
	assert(cant_speech.choose(0, cant_speech_world))
	assert(str(cant_speech.current_frame()["text"]).contains("Irith aan"))
	var cant_file: String = "user://language-cant-ink-v10.json"
	assert(SandboxSave.save_world(cant_speech_world, cant_file, cant_speech.snapshot()))
	var cant_bundle: Dictionary = SandboxSave.load_bundle(cant_file)
	var cant_resumed: SandboxConversation = SandboxConversation.new()
	assert(cant_resumed.restore(cant_bundle["world"], cant_bundle["dialogue"], self))
	assert(cant_resumed.current_frame()["text"] == cant_speech.current_frame()["text"])

	# Cant is a distinct full-language cartridge (not another word progress bar).
	var cant: SandboxWorld = SandboxWorld.new(8)
	assert(cant.reposition("market"))
	assert(cant.buy_language_module("cant"))
	assert(cant.modules_owned.has("cant") and not cant.modules_installed.has("cant"))
	assert(cant.install_language_module("cant"))
	assert(SandboxKnowledge.understands("cant", cant.modules_installed))
	assert(not SandboxKnowledge.understands("local", cant.modules_installed))
	var cant_clone: SandboxWorld = SandboxWorld.new()
	assert(cant_clone.restore_snapshot(cant.snapshot()))
	assert(cant_clone.market_stock["cant"] == 0)
	var forged: Dictionary = world.snapshot()
	forged["modules_installed"] = ["trade", "cant"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = world.snapshot()
	forged["market_stock"]["local"] = 1
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = world.snapshot()
	forged["modules_owned"] = ["trade", "local", "local"]
	assert(not SandboxWorld.new().restore_snapshot(forged))
	var replay: SandboxWorld = SandboxWorld.new(8)
	assert(replay.reposition("market"))
	assert(replay.buy_language_module("local"))
	assert(replay.install_language_module("local"))
	assert(JSON.stringify(replay.snapshot()) == JSON.stringify(world.snapshot()))
	print("SANDBOX_KNOWLEDGE_PASS")
	quit(0)
