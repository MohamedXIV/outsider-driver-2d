class_name SandboxMeetings
extends RefCounted

# Invitation policy only. SandboxWorld owns transitions, event IDs and time.
# The venue is the NPC's *real* current district, not an invented teleport.
const WINDOW_MINUTES: int = 40
const MEETING_MINUTES: int = 20


static func propose(npc: Dictionary, minute: int, source: String) -> Dictionary:
	if SandboxDriverMemory.significance(npc) != "significant":
		return {}
	# Cautious people need more trust; neither completed rides nor trust
	# imply affection, disclosure of a secret, or universal willingness.
	var threshold: int = 3 if npc["temperament"] == "cautious" else 2
	if int(npc["trust"]) < threshold or str(npc["activity"]) == "travelling":
		return {}
	var venue: String = str(npc["location"])
	for slot in range(minute + 60, minute + 1450, 10):
		var hour: int = (slot % 1440) / 60
		if hour < 6 or hour >= 21:
			continue
		if venue == str(npc["workplace"]) and hour >= 8 and hour < 18:
			continue
		if venue == str(npc["home"]) and (hour >= 22 or hour < 6):
			continue
		return {
			"id": "meeting:%s:%d" % [npc["id"], minute],
			"npc_id": str(npc["id"]), "location": venue,
			"slot": slot, "deadline": slot + WINDOW_MINUTES,
			"created_at": minute, "source": source,
			"status": "invited", "late": false
		}
	return {}


static func valid_history(meetings: Array, residents: Array, offers: Array,
		events: Array, minute: int) -> bool:
	var seen: Dictionary = {}
	for meeting in meetings:
		if not (meeting is Dictionary):
			return false
		var id: String = str(meeting.get("id", ""))
		var npc_id: String = str(meeting.get("npc_id", ""))
		var created: int = int(meeting.get("created_at", -1))
		var slot: int = int(meeting.get("slot", -1))
		var deadline: int = int(meeting.get("deadline", -1))
		var status: String = str(meeting.get("status", ""))
		if id.is_empty() or seen.has(npc_id) or not id.begins_with("meeting:%s:" % npc_id) \
				or created < 480 or created > minute or slot < created + 60 \
				or deadline != slot + WINDOW_MINUTES \
				or not SandboxRoads.DISTRICTS.has(meeting.get("location", "")) \
				or not ["invited", "accepted", "in_progress", "completed", "left", "missed", "declined", "expired", "cancelled"].has(status) \
				or not (meeting.get("late") is bool):
			return false
		seen[npc_id] = true
		var belongs: bool = false
		for npc in residents:
			if npc.get("id") == npc_id:
				belongs = true
		if not belongs:
			return false
		var source: String = str(meeting.get("source", ""))
		var experienced: int = 0
		var grounded: bool = false
		for event in events:
			if event.get("kind") != "fare_settled" or event.get("detail", {}).get("npc_id") != npc_id:
				continue
			if int(event.get("minute", -1)) <= created:
				experienced += 1
			if event.get("id") == source and int(event.get("minute", -1)) == created:
				grounded = true
		if not grounded or experienced < 2:
			return false
		var invite: bool = false
		var terminal: bool = false
		for event in events:
			if event.get("subject") != id:
				continue
			if event.get("kind") == "meeting_invited" \
					and event.get("detail", {}).get("source") == source:
				invite = true
			if event.get("kind") == "meeting_%s" % status:
				terminal = true
		if not invite or (["completed", "left", "missed", "declined", "expired", "cancelled"].has(status) and not terminal):
			return false
	return true


static func maybe_invite(world: SandboxWorld, npc: Dictionary, source: String) -> void:
	for existing in world.meetings:
		if existing["npc_id"] == npc["id"]:
			return # One bounded first off-duty meeting per person in this slice.
	var invitation: Dictionary = propose(npc, world.minute, source)
	if invitation.is_empty():
		return
	world.meetings.append(invitation)
	world._record("meeting_invited", str(invitation["id"]), {
		"npc_id": npc["id"], "source": source, "venue": invitation["location"],
		"slot": invitation["slot"], "deadline": invitation["deadline"]
	})


static func find(world: SandboxWorld, meeting_id: String) -> Dictionary:
	for meeting in world.meetings:
		if meeting["id"] == meeting_id:
			return meeting
	return {}


static func accept(world: SandboxWorld, meeting_id: String) -> bool:
	var meeting: Dictionary = find(world, meeting_id)
	if meeting.is_empty() or meeting["status"] != "invited" \
			or world.minute >= int(meeting["slot"]) or not world.active_offer_id.is_empty():
		return false
	for other in world.meetings:
		if ["accepted", "in_progress"].has(other["status"]):
			return false
	var npc: Dictionary = world.resident(str(meeting["npc_id"]))
	if npc.is_empty() or npc["location"] != meeting["location"] \
			or npc["activity"] == "travelling":
		return false
	for offer in world.offers:
		if offer["npc_id"] == npc["id"] and ["open", "accepted"].has(offer["status"]):
			return false
	meeting["status"] = "accepted"
	# An accepted personal commitment takes precedence over new trip demand.
	npc["cooldown_until"] = maxi(int(npc["cooldown_until"]), int(meeting["deadline"]) + 10)
	world._record("meeting_accepted", meeting_id, {
		"npc_id": npc["id"], "venue": meeting["location"], "slot": meeting["slot"]
	})
	return true


static func decline(world: SandboxWorld, meeting_id: String) -> bool:
	var meeting: Dictionary = find(world, meeting_id)
	if meeting.is_empty() or meeting["status"] != "invited":
		return false
	meeting["status"] = "declined"
	world._record("meeting_declined", meeting_id, {"npc_id": meeting["npc_id"]})
	return true


static func on_tick(world: SandboxWorld) -> void:
	for meeting in world.meetings:
		var status: String = str(meeting["status"])
		if status == "invited" and world.minute >= int(meeting["slot"]):
			meeting["status"] = "expired"
			world._record("meeting_expired", str(meeting["id"]), {
				"reason": "invitation_unanswered"
			})
		elif status == "accepted" and world.minute >= int(meeting["slot"]):
			var npc: Dictionary = world.resident(str(meeting["npc_id"]))
			if npc.is_empty() or npc["location"] != meeting["location"] \
					or npc["activity"] != "available":
				meeting["status"] = "cancelled"
				world._record("meeting_cancelled", str(meeting["id"]), {
					"reason": "npc_unavailable", "npc_id": meeting["npc_id"]
				})
			elif world.minute > int(meeting["deadline"]):
				meeting["status"] = "missed"
				npc["trust"] = int(npc["trust"]) - 1
				world._record("meeting_missed", str(meeting["id"]), {
					"npc_id": npc["id"], "trust_delta": -1,
					"deadline": meeting["deadline"]
				})


static func start(world: SandboxWorld, meeting_id: String) -> bool:
	var meeting: Dictionary = find(world, meeting_id)
	if meeting.is_empty() or meeting["status"] != "accepted" \
			or not world.active_offer_id.is_empty() \
			or world.player_district != meeting["location"] \
			or world.minute < int(meeting["slot"]) or world.minute > int(meeting["deadline"]):
		return false
	var npc: Dictionary = world.resident(str(meeting["npc_id"]))
	if npc.is_empty() or npc["location"] != meeting["location"] \
			or npc["activity"] != "available":
		return false
	meeting["status"] = "in_progress"
	meeting["late"] = world.minute > int(meeting["slot"]) + 10
	world._record("meeting_started", meeting_id, {
		"npc_id": npc["id"], "venue": meeting["location"],
		"late": meeting["late"], "source": meeting["source"]
	})
	return true


static func finish(world: SandboxWorld, meeting_id: String, choice: String) -> bool:
	var meeting: Dictionary = find(world, meeting_id)
	if meeting.is_empty() or meeting["status"] != "in_progress" \
			or not ["listen", "brief", "leave"].has(choice):
		return false
	var npc: Dictionary = world.resident(str(meeting["npc_id"]))
	if npc.is_empty():
		return false
	var duration: int = 10 if choice == "leave" else MEETING_MINUTES
	var trust_delta: int = -1 if choice == "leave" else (2 if choice == "listen" else 1)
	if bool(meeting["late"]) and choice != "leave":
		trust_delta -= 1
	meeting["status"] = "left" if choice == "leave" else "completed"
	# Consume real world time; another passenger's offer can expire meanwhile.
	if not world.advance(duration):
		return false
	npc["trust"] = int(npc["trust"]) + trust_delta
	world._record("meeting_%s" % meeting["status"], meeting_id, {
		"npc_id": npc["id"], "venue": meeting["location"],
		"choice": choice, "duration": duration, "late": meeting["late"],
		"trust_delta": trust_delta
	})
	return true
