extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	var world: SandboxWorld=scene._world
	var who: String="npc:07"
	for trip in range(2):
		var found: String=""
		for tick in range(150):
			for offer in world.open_offers():
				if offer["npc_id"]==who and offer["origin"]==world.player_district: found=offer["id"];break
			if not found.is_empty(): break
			world.advance(10)
		assert(not found.is_empty());assert(world.accept(found));world.advance(world.remaining_minutes)
	assert(world.meetings.size()==1)
	var id: String=world.meetings[0]["id"]
	assert(world.accept_meeting(id))
	scene._selected_meeting_id=id;scene._player_ui._tab("contacts");scene._render()
	var mode: SandboxPlayerUI=scene._player_ui
	assert(mode._body.has_node("ContactsListSection"))
	assert(mode._body.has_node("ContactDetailsSection"))
	assert(mode._body.has_node("ContactActionsSection"))
	assert(mode._body.get_node("ContactDetailsSection/Items").get_child_count()>=3)
	assert(mode._actions["meeting_attend"].disabled)
	world.advance(int(world.meetings[0]["slot"])-world.minute);scene._render()
	assert(not scene._player_ui._actions["meeting_attend"].disabled,"Contact action must refresh when the actual appointment starts")
	scene._selected_meeting_id=id;scene._on_meeting_attend();assert(scene._meeting_dialogue!=null)
	scene._player_ui._tab("contacts")
	# Re-render within the same frame: queued old debug children must not affect Player indexes.
	scene._render();scene._render()
	var count: int=scene._meeting_dialogue.current_frame()["choices"].size()
	assert(mode._body.has_node("ContactSceneSection"))
	assert(mode._body.has_node("ContactRepliesSection"))
	assert(not mode._body.has_node("ContactActionsSection"),
		"In-person Ink responses must not mix with scheduling actions")
	var story_note: Label=mode._body.get_node("ContactSceneSection/Items").get_child(1) as Label
	assert(story_note.text==scene._meeting_text.text,
		"Contact presentation must show exactly the sourced Ink frame")
	var actual: int=0
	for key in scene._player_ui._actions:
		if str(key).begins_with("meeting_choice_"):actual+=1
	assert(actual==count)
	for i in range(count): assert(scene._player_ui._actions.has("meeting_choice_"+str(i)))
	scene._player_ui._actions["meeting_choice_0"].pressed.emit()
	assert(world.meeting_by_id(id)["status"]=="completed")
	print("PLAYER_CONTACTS_PASS live frame choices, stable indexes, real meeting settlement")
	quit()
