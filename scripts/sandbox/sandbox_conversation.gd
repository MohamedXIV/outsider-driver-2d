class_name SandboxConversation
extends RefCounted

# A live NPC's *current* request is the only entrance into shared Ink policy.
# No passenger-specific knot, job schedule, scenario ID or fabricated world fact.
const STORY_PATH: String = "res://stories/sandbox_dialogue.ink.json"
const ACTION_ACCEPT: String = "action:accept_offer"
const ACTION_DECLINE: String = "action:decline_offer"

var offer_id: String = ""
var _ink: InkBridge
var _frame: Dictionary = {}
var _outcome: String = ""
var _understood: bool = false
var _recognizes_driver: bool = false


func open(world: SandboxWorld, requested_offer: String, tree: SceneTree) -> bool:
	var offer: Dictionary = world.offer_by_id(requested_offer)
	if offer.is_empty() or offer.get("status") != "open" or offer.get("origin") != world.player_district:
		return false
	var npc: Dictionary = world.resident(str(offer.get("npc_id", "")))
	if npc.is_empty() or str(npc.get("location")) != str(offer["origin"]):
		return false
	var compiled: String = FileAccess.get_file_as_string(STORY_PATH)
	if compiled.is_empty():
		return false
	var understood: bool = SandboxKnowledge.understands(str(npc["language"]), world.modules_installed) \
			or bool(world.common_requests.get(requested_offer, false))
	var globals: Dictionary = {
		"knows_local_route": false, # Obsolete S2 Ink branch is unreachable; compiled story remains deterministic.
		"recognizes_driver": SandboxDriverMemory.recognizes(npc),
		"understands_speaker": understood,
		"urgent": int(npc["need"]) >= 70,
		"temperament": str(npc["temperament"]),
		"destination": str(offer["destination"]),
		"purpose": str(offer["purpose"])
	}
	var bridge: InkBridge = InkBridge.new()
	if not bridge.open_compiled(compiled, tree, globals):
		return false
	_ink = bridge
	offer_id = requested_offer
	_understood = understood
	_recognizes_driver = SandboxDriverMemory.recognizes(npc)
	_outcome = ""
	_frame = _ink.advance()
	_present_untranslated_frame(world)
	return true


func still_valid(world: SandboxWorld) -> bool:
	if offer_id.is_empty():
		return false
	var offer: Dictionary = world.offer_by_id(offer_id)
	return not offer.is_empty() and offer.get("status") == "open" \
			and offer.get("origin") == world.player_district and world.active_offer_id.is_empty()


func choose(index: int, world: SandboxWorld, waypoint: String = "") -> bool:
	if _ink == null or not still_valid(world):
		return false
	var choices: Array = _frame.get("choices", [])
	if index < 0 or index >= choices.size():
		return false
	var result: Dictionary = _ink.choose(index)
	_frame = result
	_present_untranslated_frame(world)
	var tags: Array = result.get("tags", [])
	# Ink tags describe a proposed speech act. World validates & owns the effect.
	if tags.has(ACTION_ACCEPT):
		_outcome = "accepted" if world.accept(offer_id, waypoint) else "blocked"
	elif tags.has(ACTION_DECLINE):
		_outcome = "declined" if world.decline(offer_id) else "blocked"
	return true


func _present_untranslated_frame(world: SandboxWorld) -> void:
	if _understood or _frame.is_empty():
		return
	var offer: Dictionary = world.offer_by_id(offer_id)
	var npc: Dictionary = world.resident(str(offer.get("npc_id", "")))
	_frame["text"] = SandboxLanguagePresentation.source_line(str(npc.get("language", "")),
			SandboxLanguagePresentation.speech_key(_frame, npc))


func spoken_language(world: SandboxWorld) -> String:
	if _understood and bool(world.common_requests.get(offer_id, false)):
		return "trade" # This speaker explicitly switched to Common.
	var offer: Dictionary = world.offer_by_id(offer_id)
	return str(world.resident(str(offer.get("npc_id", ""))).get("language", "trade"))


func current_frame() -> Dictionary:
	return _frame.duplicate(true)


func outcome() -> String:
	return _outcome


func understood() -> bool:
	return _understood


func request_common(world: SandboxWorld, tree: SceneTree) -> bool:
	if _ink == null or not still_valid(world) or _frame.get("tags", []).has("intent:ask_destination") \
			or world.common_requests.has(offer_id) or _understood:
		return false
	var target: String = offer_id
	if not world.request_common(target):
		return false
	return open(world, target, tree)


func recognizes_driver() -> bool:
	return _recognizes_driver


func is_finished() -> bool:
	return not _outcome.is_empty()


func snapshot() -> Dictionary:
	if _ink == null or is_finished():
		return {}
	return {"offer_id": offer_id, "ink": _ink.snapshot()}


func restore(world: SandboxWorld, value: Dictionary, tree: SceneTree) -> bool:
	var id: String = str(value.get("offer_id", ""))
	var ink_state: Variant = value.get("ink")
	if id.is_empty() or not (ink_state is Dictionary) or ink_state.is_empty():
		return false
	if not open(world, id, tree):
		return false
	if not _ink.restore_snapshot(ink_state):
		_ink = null
		offer_id = ""
		_frame = {}
		return false
	_frame = _ink.current_frame()
	_present_untranslated_frame(world)
	if not (_frame.get("choices") is Array) or not (_frame.get("tags") is Array):
		return false
	return true
