extends SceneTree

func _initialize() -> void:
	for seed in [8, 9, 17]:
		var world: SandboxWorld = SandboxWorld.new(seed)
		var replay: SandboxWorld = SandboxWorld.new(seed)
		assert(world.advance(20))
		var meetings: Array[Dictionary] = []
		for event in world.events:
			if event["kind"] == "npc_peer_contact":
				meetings.append(event)
		assert(meetings.size() > 0)
		var first: Dictionary = meetings[0]
		var actor: Dictionary = world.resident(str(first["subject"]))
		var receiver: Dictionary = world.resident(str(first["detail"]["recipient"]))
		assert(not actor.is_empty() and not receiver.is_empty())
		assert(actor["id"] != receiver["id"] and actor["location"] == receiver["location"])
		assert(actor["language"] == receiver["language"] and actor["species"] != receiver["species"])
		assert(int(first["detail"]["affinity"]) >= 2)
		assert(int(first["detail"]["rivalry"]) > 0) # Familiarity and competition coexist.
		var fact: String = str(first["detail"]["fact"])
		assert(receiver["peer_knowledge"].has(fact))
		assert(receiver["peer_knowledge"][fact]["source"] == first["id"])
		assert(receiver["peer_knowledge"][fact]["value"] == actor["home"])
		assert(int(receiver["contacts"][actor["id"]]) == 1)
		assert(int(actor["contacts"][receiver["id"]]) == 1)
		# Nobody else is granted another person's private fact telepathically.
		for npc in world.residents:
			if npc["id"] != receiver["id"]:
				assert(not npc["peer_knowledge"].has(fact))
		assert(world.advance(1420))
		assert(replay.advance(1440))
		assert(world.snapshot() == replay.snapshot())
		var file: String = "user://s3-peers-%d.json" % seed
		var split: SandboxWorld = SandboxWorld.new(seed)
		assert(split.advance(720))
		assert(SandboxSave.save_world(split, file))
		var recovered: SandboxWorld = SandboxSave.load_world(file)
		assert(recovered != null)
		assert(recovered.advance(720))
		assert(recovered.snapshot() == world.snapshot())
		var forged: Dictionary = world.snapshot()
		var recipient_idx: int = -1
		for i in range(forged["residents"].size()):
			if forged["residents"][i]["id"] == receiver["id"]:
				recipient_idx = i
		assert(recipient_idx >= 0)
		forged["residents"][recipient_idx]["peer_knowledge"][fact]["source"] = "event:forged"
		assert(not SandboxWorld.new().restore_snapshot(forged))
		print("S3_PEERS seed=", seed, " contacts=", meetings.size(),
			" first_source=", first["id"])
	print("SANDBOX_PEER_PASS")
	quit(0)
