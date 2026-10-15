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
