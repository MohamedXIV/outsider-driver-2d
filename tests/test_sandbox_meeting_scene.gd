extends SceneTree

const SHOTS: String = "/tmp/od2d-ink-evidence/sandbox"

func _initialize() -> void:
	call_deferred("_walk")

func _walk() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var scene: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame
	var world: SandboxWorld = scene.get("_world")
	var first: Dictionary = world.offer_by_id(str(scene.get("_selected_id")))
	var npc_id: String = str(first["npc_id"])
	var accept_trip: Button = scene.get_node("HUD/DockPanel/Content/Actions/Accept")
	assert(not accept_trip.disabled)
	accept_trip.pressed.emit()
	assert(world.advance(world.remaining_minutes))
	var followup: String = ""
	for tick in range(150):
		for offer in world.open_offers():
			if offer["npc_id"] == npc_id and offer["id"] != first["id"]:
				followup = str(offer["id"])
				break
		if not followup.is_empty():
			break
		assert(world.advance(10))
	assert(not followup.is_empty())
	assert(world.accept(followup))
	assert(world.advance(world.remaining_minutes))
	scene.call("_render")
	await process_frame
	assert(world.meetings.size() == 1)
	var invitation: Dictionary = world.meetings[0]
	var selector: OptionButton = scene.get_node("HUD/WorldPanel/Content/MeetingSelect")
	assert(selector.item_count == 1)
	var accept_meeting: Button = scene.get_node("HUD/WorldPanel/Content/MeetingActions/AcceptMeeting")
	assert(not accept_meeting.disabled)
	await RenderingServer.frame_post_draw
	_capture("meeting-invitation-native.png")
	accept_meeting.pressed.emit()
	assert(world.meetings[0]["status"] == "accepted")
	assert(world.advance(int(invitation["slot"]) - world.minute))
	scene.call("_render")
	var attend: Button = scene.get_node("HUD/WorldPanel/Content/MeetingActions/AttendMeeting")
	assert(not attend.disabled)
	await RenderingServer.frame_post_draw
	_capture("meeting-location-native.png")
	attend.pressed.emit()
	await process_frame
	var panel: PanelContainer = scene.get_node("HUD/MeetingPanel")
	assert(panel.visible)
	var stage: SandboxMeetingStage = scene.get_node("HUD/MeetingPanel/Content/Stage")
	assert(stage.venue == invitation["location"] and stage.companion == npc_id)
	var choices: VBoxContainer = scene.get_node("HUD/MeetingPanel/Content/Choices")
	assert(choices.get_child_count() == 3)
	assert((scene.get_node("HUD/MeetingPanel/Content/Line") as Label).text.contains("kiosk"))
	await RenderingServer.frame_post_draw
	_capture("meeting-in-person-native.png")
	scene.call("_on_save")
	scene.call("_on_new_seed")
	scene.call("_on_load")
	await process_frame
	assert(scene.get("_world").meetings[0]["status"] == "in_progress")
	assert(panel.visible and choices.get_child_count() == 3)
	await RenderingServer.frame_post_draw
	_capture("meeting-restored-native.png")
	(choices.get_child(0) as Button).pressed.emit()
	await process_frame
	var recovered: SandboxWorld = scene.get("_world")
	assert(recovered.meetings[0]["status"] == "completed")
	assert(not panel.visible)
	await RenderingServer.frame_post_draw
	_capture("meeting-completed-native.png")
	print("SANDBOX_MEETING_SCENE_PASS")
	quit(0)


func _capture(name: String) -> void:
	assert(get_root().get_texture().get_image().save_png(SHOTS.path_join(name)) == OK)
