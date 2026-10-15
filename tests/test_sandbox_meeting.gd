extends SceneTree

func _initialize() -> void:
	var a: SandboxWorld = SandboxWorld.new(8)
	var b: SandboxWorld = SandboxWorld.new(8)
	var passenger: String = _two_real_fares(a)
	assert(not passenger.is_empty())
	assert(_two_real_fares(b) == passenger)
	assert(a.snapshot() == b.snapshot())
	assert(a.meetings.size() == 1)
	var invitation: Dictionary = a.meetings[0]
	assert(invitation["npc_id"] == passenger)
	assert(invitation["status"] == "invited")
	assert(invitation["location"] == a.resident(passenger)["location"])
	assert(a.resident(passenger)["driver_identity_facts"].is_empty())
	assert(not a.start_meeting(str(invitation["id"])))
	var sourced: bool = false
	for event in a.events:
		if event["id"] == invitation["source"]:
			assert(event["kind"] == "fare_settled" and event["detail"]["npc_id"] == passenger)
			sourced = true
	assert(sourced)
	var offered_save: String = "user://relationships-invited.json"
	assert(SandboxSave.save_world(a, offered_save))
	var invited: SandboxWorld = SandboxSave.load_world(offered_save)
	assert(invited != null and invited.snapshot() == a.snapshot())
	var meeting_id: String = str(invitation["id"])
	assert(invited.accept_meeting(meeting_id))
	assert(not invited.accept_meeting(meeting_id))
	assert(not invited.decline_meeting(meeting_id))
	assert(invited.meeting_by_id(meeting_id)["status"] == "accepted")
	var confirmed_save: String = "user://relationships-confirmed.json"
	assert(SandboxSave.save_world(invited, confirmed_save))
	var confirmed: SandboxWorld = SandboxSave.load_world(confirmed_save)
	assert(confirmed != null and confirmed.snapshot() == invited.snapshot())
	assert(not confirmed.start_meeting(meeting_id)) # Not physically time yet.
	assert(confirmed.advance(int(invitation["slot"]) - confirmed.minute))
	assert(confirmed.player_district == invitation["location"])
	assert(confirmed.start_meeting(meeting_id))
	assert(not confirmed.start_meeting(meeting_id))
	var in_progress_path: String = "user://relationships-in-progress.json"
	assert(SandboxSave.save_world(confirmed, in_progress_path))
	var mid: SandboxWorld = SandboxSave.load_world(in_progress_path)
	assert(mid != null and mid.snapshot() == confirmed.snapshot())
	var ink: SandboxMeetingDialogue = SandboxMeetingDialogue.new()
	assert(ink.open(mid, meeting_id, self))
	assert(ink.current_frame()["choices"].size() == 3)
	assert(ink.current_frame()["text"].contains("kiosk"))
	var before: int = mid.minute
	var old_trust: int = int(mid.resident(passenger)["trust"])
	assert(ink.choose(0, mid))
	assert(mid.minute == before + SandboxMeetings.MEETING_MINUTES)
	assert(mid.meeting_by_id(meeting_id)["status"] == "completed")
	assert(int(mid.resident(passenger)["trust"]) == old_trust + 2)
	assert(not mid.finish_meeting(meeting_id, "listen"))
	assert(mid.resident(passenger)["driver_identity_facts"].is_empty())
	assert(SandboxSave.save_world(mid, "user://relationships-completed.json"))
	var finished: SandboxWorld = SandboxSave.load_world("user://relationships-completed.json")
	assert(finished != null and finished.snapshot() == mid.snapshot())
	var completions: int = 0
	for event in finished.events:
		if event["kind"] == "meeting_completed" and event["subject"] == meeting_id:
			completions += 1
	assert(completions == 1)

	var late: SandboxWorld = SandboxWorld.new()
	assert(late.restore_snapshot(a.snapshot()))
	assert(late.accept_meeting(meeting_id))
	assert(late.advance(int(invitation["slot"]) + 20 - late.minute))
	assert(late.start_meeting(meeting_id))
	assert(late.meeting_by_id(meeting_id)["late"])
	var late_trust: int = int(late.resident(passenger)["trust"])
	assert(late.finish_meeting(meeting_id, "brief"))
	assert(int(late.resident(passenger)["trust"]) == late_trust) # +1 goodwill -1 lateness.
	var missed: SandboxWorld = SandboxWorld.new()
	assert(missed.restore_snapshot(a.snapshot()))
	assert(missed.accept_meeting(meeting_id))
	var missed_trust: int = int(missed.resident(passenger)["trust"])
	assert(missed.advance(int(invitation["deadline"]) + 10 - missed.minute))
	assert(missed.meeting_by_id(meeting_id)["status"] == "missed")
	assert(int(missed.resident(passenger)["trust"]) == missed_trust - 1)
	assert(not missed.start_meeting(meeting_id))
	var declined: SandboxWorld = SandboxWorld.new()
	assert(declined.restore_snapshot(a.snapshot()))
	assert(declined.decline_meeting(meeting_id))
	assert(declined.meeting_by_id(meeting_id)["status"] == "declined")
	assert(not declined.accept_meeting(meeting_id))
	var ignored: SandboxWorld = SandboxWorld.new()
	assert(ignored.restore_snapshot(a.snapshot()))
	assert(ignored.advance(int(invitation["slot"]) - ignored.minute))
	assert(ignored.meeting_by_id(meeting_id)["status"] == "expired")
	var forged: Dictionary = a.snapshot()
	forged["meetings"][0]["source"] = "event:forged"
	assert(not SandboxWorld.new().restore_snapshot(forged))
	forged = mid.snapshot()
	forged["meetings"][0]["status"] = "missed" # no matching missed outcome
	assert(not SandboxWorld.new().restore_snapshot(forged))
	for s in [3, 9, 21]:
		var one: SandboxWorld = SandboxWorld.new(s)
		var two: SandboxWorld = SandboxWorld.new(s)
		assert(one.advance(2880) and two.advance(2880))
		assert(one.snapshot() == two.snapshot())
	print("SANDBOX_MEETING_DOMAIN_PASS")
	quit(0)


func _two_real_fares(world: SandboxWorld) -> String:
	var first: Dictionary = {}
	for offer in world.open_offers():
		if offer["origin"] == world.player_district and offer["channel"] != "official":
			first = offer
			break
	assert(not first.is_empty())
	var who: String = str(first["npc_id"])
	assert(world.accept(str(first["id"])))
	assert(world.advance(world.remaining_minutes))
	var second: Dictionary = {}
	for step in range(150):
		for offer in world.open_offers():
			if offer["npc_id"] == who and offer["id"] != first["id"]:
				second = offer
				break
		if not second.is_empty():
			break
		assert(world.advance(10))
	assert(not second.is_empty() and second["origin"] == world.player_district)
	assert(world.accept(str(second["id"])))
	assert(world.advance(world.remaining_minutes))
	return who
