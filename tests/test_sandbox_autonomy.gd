extends SceneTree

# S3 proof: life happens while the player never accepts or declines a fare.
func _initialize() -> void:
	for seed in [8, 9, 17]:
		var a: SandboxWorld = SandboxWorld.new(seed)
		var b: SandboxWorld = SandboxWorld.new(seed)
		var before_locations: Dictionary = {}
		for npc in a.residents:
			before_locations[npc["id"]] = npc["location"]
		assert(a.advance(1440))
		assert(b.advance(1440))
		assert(JSON.stringify(a.snapshot()) == JSON.stringify(b.snapshot()))
		assert(a.credits == 12 and a.risk == 0 and a.active_offer_id.is_empty())
		var departures: Dictionary = {}
		var arrivals: Dictionary = {}
		var changed_routines: int = 0
		var paid_workers: int = 0
		for event in a.events:
			if event["kind"] == "npc_alternative_departed":
				departures[event["detail"]["offer_id"]] = event
				assert(event["detail"]["arrival_at"] > event["minute"])
				assert(event["detail"]["method"] in ["walking", "shuttle"])
				assert(int(event["detail"]["cost"]) >= 0)
			elif event["kind"] == "npc_alternative_arrived":
				arrivals[event["detail"]["offer_id"]] = event
				assert(departures.has(event["detail"]["offer_id"]))
				assert(int(departures[event["detail"]["offer_id"]]["detail"]["arrival_at"]) == int(event["minute"]))
			elif event["kind"] == "npc_routine_changed":
				changed_routines += 1
			elif event["kind"] == "npc_work_paid":
				paid_workers += 1
		assert(departures.size() > 0 and arrivals.size() > 0)
		assert(changed_routines > 0 and paid_workers > 0)
		var changed_places: int = 0
		for npc in a.residents:
			if npc["location"] != before_locations[npc["id"]]:
				changed_places += 1
		assert(changed_places > 0)
		var split: SandboxWorld = SandboxWorld.new(seed)
		assert(split.advance(720))
		var save_path: String = "user://s3-day-%d.json" % seed
		assert(SandboxSave.save_world(split, save_path))
		var recovered: SandboxWorld = SandboxSave.load_world(save_path)
		assert(recovered != null and recovered.minute == split.minute)
		assert(recovered.advance(720))
		assert(JSON.stringify(recovered.snapshot()) == JSON.stringify(a.snapshot()))
		# Forged incomplete in-flight state must not load.
		var forged: Dictionary = a.snapshot()
		forged["residents"][0]["transit_until"] = a.minute + 20
		forged["residents"][0]["transit_to"] = ""
		assert(not SandboxWorld.new().restore_snapshot(forged))
		print("S3_IDLE_DAY seed=", seed, " departed=", departures.size(),
			" arrived=", arrivals.size(), " routines=", changed_routines,
			" work_payments=", paid_workers)
	print("SANDBOX_AUTONOMY_PASS")
	quit(0)
