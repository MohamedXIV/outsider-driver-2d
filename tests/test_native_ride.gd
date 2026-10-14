extends SceneTree

# Executes the actual main scene and HUD button signals in a displayed Linux
# Godot session. The Web test separately drives real Chromium pointer input.
const EVIDENCE_DIR: String = "/tmp/od2d-ink-evidence/native"


func _initialize() -> void:
	call_deferred("_walkthrough")


func _walkthrough() -> void:
	DirAccess.make_dir_recursive_absolute(EVIDENCE_DIR)
	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed != null, "Real main scene must exist.")
	var scene: Node2D = packed.instantiate() as Node2D
	get_root().add_child(scene)
	await process_frame
	await process_frame

	var actions: HBoxContainer = scene.get_node("HUD/RideBar/RideContent/Actions") as HBoxContainer
	var pickup: Button = actions.get_node("Pickup") as Button
	var arrival: Button = actions.get_node("Arrived") as Button
	var save_button: Button = actions.get_node("Save") as Button
	var load_button: Button = actions.get_node("Load") as Button
	var choice_list: VBoxContainer = scene.get_node("HUD/ChoicePanel/ChoiceList") as VBoxContainer
	var passenger: PanelContainer = scene.get_node("HUD/PassengerPanel") as PanelContainer
	var session: GameSession = scene.get("_session") as GameSession
	assert(session.phase == GameSession.RidePhase.WAITING)
	await RenderingServer.frame_post_draw
	_capture("waiting.png")

	pickup.pressed.emit()
	await process_frame
	assert(session.phase == GameSession.RidePhase.TRAVELING)
	assert(passenger.visible)
	assert(choice_list.get_child_count() == 2, "Native UI must show authored Ink choices.")
	await RenderingServer.frame_post_draw
	_capture("traveling.png")

	save_button.pressed.emit()
	assert(FileAccess.file_exists(RideSave.SAVE_PATH), "Native Save button did not persist a ride.")
	var before_choice: float = session.world_minutes
	session.advance(2.0)
	assert(session.world_minutes > before_choice, "Dialogue paused the native clock.")
	var first: Button = choice_list.get_child(0) as Button
	first.pressed.emit()
	await process_frame
	assert(session.known_facts.has("docks-route"), "The visible choice did not apply its fact.")

	session.advance(100.0)
	await process_frame
	assert(session.phase == GameSession.RidePhase.ARRIVED)
	var clock_at_arrival: float = session.world_minutes
	session.advance(1.0)
	assert(session.world_minutes > clock_at_arrival, "Native world time froze at arrival.")
	assert(arrival.visible)
	await RenderingServer.frame_post_draw
	_capture("arrived.png")

	arrival.pressed.emit()
	await process_frame
	assert(choice_list.get_child_count() == 2, "The authored arrival options are missing.")
	await RenderingServer.frame_post_draw
	_capture("arrival-choices.png")
	var exit_choice: Button = choice_list.get_child(0) as Button
	exit_choice.pressed.emit()
	await process_frame
	assert(session.phase == GameSession.RidePhase.COMPLETED)
	assert(session.credits == GameSession.FARE_CREDITS)
	assert(not passenger.visible, "Disembarked passenger remains in native HUD.")
	await RenderingServer.frame_post_draw
	_capture("completed.png")

	load_button.pressed.emit()
	await process_frame
	var restored: GameSession = scene.get("_session") as GameSession
	assert(restored.phase == GameSession.RidePhase.COMPLETED)
	assert(restored.credits == GameSession.FARE_CREDITS)
	assert(restored.known_facts.has("docks-route"))
	assert(not restored.drop_off(), "Native Load allowed duplicate fare.")
	print("P1_DESKTOP_NATIVE_PASS")
	quit(0)


func _capture(filename: String) -> void:
	var shot: Image = get_root().get_texture().get_image()
	assert(shot != null and shot.get_width() >= 640 and shot.get_height() >= 360,
		"Native rendering did not produce a valid desktop frame.")
	assert(shot.save_png(EVIDENCE_DIR.path_join(filename)) == OK,
		"Could not save desktop screenshot.")
