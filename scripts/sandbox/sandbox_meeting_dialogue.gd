class_name SandboxMeetingDialogue
extends RefCounted

const STORY_PATH: String = "res://stories/sandbox_meeting.ink.json"

var meeting_id: String = ""
var _ink: InkBridge
var _frame: Dictionary = {}


func open(world: SandboxWorld, id: String, tree: SceneTree) -> bool:
	var meeting: Dictionary = world.meeting_by_id(id)
	if meeting.is_empty() or meeting["status"] != "in_progress":
		return false
	var npc: Dictionary = world.resident(str(meeting["npc_id"]))
	var compiled: String = FileAccess.get_file_as_string(STORY_PATH)
	if npc.is_empty() or compiled.is_empty():
		return false
	var bridge: InkBridge = InkBridge.new()
	if not bridge.open_compiled(compiled, tree, {
		"is_late": bool(meeting["late"]),
		"is_cautious": str(npc["temperament"]) == "cautious",
		"understands_speaker": SandboxKnowledge.understands(str(npc["language"]), world.modules_installed)
	}):
		return false
	meeting_id = id
	_ink = bridge
	_frame = _ink.advance()
	return not _frame.get("choices", []).is_empty()


func current_frame() -> Dictionary:
	return _frame.duplicate(true)


func choose(index: int, world: SandboxWorld) -> bool:
	if _ink == null or world.meeting_by_id(meeting_id).get("status") != "in_progress":
		return false
	if index < 0 or index >= _frame.get("choices", []).size():
		return false
	var next: Dictionary = _ink.choose(index)
	for tag in next.get("tags", []):
		var act: String = str(tag)
		if act.begins_with("meeting:"):
			return world.finish_meeting(meeting_id, act.trim_prefix("meeting:"))
	return false
