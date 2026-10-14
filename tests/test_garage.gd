extends SceneTree

func _initialize() -> void:
	var session: GameSession = GameSession.new()
	assert(session.nearest_garage_station().is_empty())
	assert(not session.select_starter_device("gps"))
	assert(not session.read_garage_notice())
	assert(not session.pickup())
	var before: Vector2 = session.garage_position
	assert(session.move_in_garage(Vector2.LEFT))
	assert(session.garage_position != before)
	for i in range(30):
		assert(session.move_in_garage(Vector2.LEFT))
		assert(session.move_in_garage(Vector2.UP))
	assert(session.garage_position == GameSession.GARAGE_MIN, "Walking escaped bounded garage floor.")
	_walk_to(session, GameSession.NOTICEBOARD)
	assert(session.near_garage_station("noticeboard"))
	assert(session.read_garage_notice())
	assert(session.read_garage_notice())
	assert(session.known_facts.count("notice:inspection-shift") == 1)
	_walk_to(session, GameSession.WORKBENCH)
	assert(session.select_starter_device("radio"))
	assert(not session.select_starter_device("gps"))
	_walk_to(session, GameSession.TAXI_DOOR)
	assert(session.pickup())
	assert(not session.move_in_garage(Vector2.LEFT), "Walking continued while in taxi.")
	assert(session.known_facts.has("radio:two-local-languages"))
	var copy: GameSession = GameSession.new()
	assert(copy.restore_snapshot(session.snapshot()))
	assert(copy.garage_position == session.garage_position)
	assert(copy.known_facts.has("notice:inspection-shift"))
	assert(copy.starter_device == "radio")
	var invalid: Dictionary = session.snapshot()
	invalid["garage_position"] = [999.0, 999.0]
	assert(not GameSession.new().restore_snapshot(invalid))
	print("P2_GARAGE_NATIVE_PASS")
	quit(0)


func _walk_to(session: GameSession, goal: Vector2) -> void:
	for i in range(40):
		if session.garage_position.distance_to(goal) <= 0.38:
			break
		assert(session.move_in_garage(goal - session.garage_position))
	assert(session.garage_position.distance_to(goal) <= GameSession.INTERACT_RADIUS)
