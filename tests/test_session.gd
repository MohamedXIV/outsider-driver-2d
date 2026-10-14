extends SceneTree

func _initialize() -> void:
	var state: GameSession = GameSession.new()
	var start: Vector3 = state.ride.world_position()
	state.advance(3.0)
	assert(state.world_minutes > GameSession.START_MINUTE)
	assert(state.ride.world_position() == start, "Taxi drove before pickup.")
	assert(not state.pickup(), "A shift needs a prepared starter device.")
	assert(not state.select_starter_device("gps"), "Can't reach the bench from spawn.")
	_walk_to(state, GameSession.WORKBENCH)
	assert(not state.select_starter_device("unknown"))
	assert(state.select_starter_device("gps"))
	assert(not state.select_starter_device("translator"), "Starter choice must be single-use.")
	assert(state.known_facts.has("map:inspection-arch"))
	assert(not state.pickup(), "Taxi is too far from workbench.")
	_walk_to(state, GameSession.TAXI_DOOR)
	assert(state.pickup())
	assert(not state.pickup(), "Pickup must happen only once.")
	state.advance(100.0)
	assert(state.phase == GameSession.RidePhase.ARRIVED)
	assert(state.ride.is_finished())
	var world_clock: float = state.world_minutes
	state.advance(5.0)
	assert(state.world_minutes > world_clock, "World stopped during arrival.")
	state.apply_story_tags("choice:docks", ["fact:docks-route", "suspicion:1"])
	state.apply_story_tags("choice:docks", ["fact:docks-route", "suspicion:1"])
	assert(state.known_facts == ["map:inspection-arch", "docks-route"])
	assert(state.suspicion == 1, "Duplicate choice re-applied suspicion.")
	assert(state.credits == 0)
	assert(state.drop_off())
	assert(not state.drop_off(), "Double dropoff allowed.")
	assert(state.credits == GameSession.FARE_CREDITS)

	var save_path: String = "user://p1-session-fixture.json"
	assert(RideSave.save(state, {}, save_path))
	var envelope: Dictionary = RideSave.load(save_path)
	assert(envelope.get("schema_version") == 4)
	var restored: GameSession = GameSession.new()
	assert(restored.restore_snapshot(envelope["game"]))
	assert(restored.phase == GameSession.RidePhase.COMPLETED)
	assert(restored.credits == GameSession.FARE_CREDITS)
	assert(restored.suspicion == 1)
	assert(restored.starter_device == "gps")
	assert(restored.known_facts.has("docks-route"))
	assert(restored.known_facts.has("map:inspection-arch"))
	assert(restored.ride.world_position() == state.ride.world_position())
	assert(not restored.drop_off(), "Restore allowed double payment.")
	var after_dropoff: float = restored.world_minutes
	restored.advance(2.0)
	assert(restored.world_minutes > after_dropoff, "Completed ride froze the world.")
	var traveling: GameSession = GameSession.new()
	_walk_to(traveling, GameSession.WORKBENCH)
	assert(traveling.select_starter_device("radio"))
	_walk_to(traveling, GameSession.TAXI_DOOR)
	assert(traveling.pickup())
	traveling.advance(2.0)
	var unfinished_path: String = "user://p1-unfinished-fixture.json"
	assert(RideSave.save(traveling, {"runtime_state": "ink-state", "frame": {"choices": ["A", "B"]}}, unfinished_path))
	var unfinished: GameSession = GameSession.new()
	assert(unfinished.restore_snapshot(RideSave.load(unfinished_path)["game"]))
	assert(unfinished.phase == GameSession.RidePhase.TRAVELING)
	assert(unfinished.credits == 0 and unfinished.ride.world_position() == traveling.ride.world_position())

	# The three choices must remain differentiated and survive persistence.
	var translation: GameSession = GameSession.new()
	_walk_to(translation, GameSession.WORKBENCH)
	assert(translation.select_starter_device("translator"))
	assert(translation.known_facts.has("translation:clinic-token"))
	assert(not translation.known_facts.has("radio:two-local-languages"))
	assert(translation.restore_snapshot(translation.snapshot()))
	assert(translation.starter_device == "translator")
	var invalid: Dictionary = translation.snapshot()
	invalid["starter_device"] = "unlisted-gear"
	assert(not GameSession.new().restore_snapshot(invalid), "Invalid equipment must reject save.")
	invalid = translation.snapshot()
	invalid["known_facts"] = []
	assert(not GameSession.new().restore_snapshot(invalid), "Cannot lose the chosen gear's fact.")

	print("P1_SESSION_NATIVE_PASS")
	quit(0)


func _walk_to(state: GameSession, goal: Vector2) -> void:
	for step in range(40):
		if state.garage_position.distance_to(goal) <= 0.38:
			break
		assert(state.move_in_garage(goal - state.garage_position))
	assert(state.garage_position.distance_to(goal) <= GameSession.INTERACT_RADIUS, "Could not reach garage station.")
