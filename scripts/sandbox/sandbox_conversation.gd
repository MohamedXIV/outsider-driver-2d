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
var _partial_route: bool = false


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
	var understood: bool = SandboxKnowledge.understands(str(npc["language"]), world.knowledge)
	var partial_route: bool = SandboxKnowledge.recognizes_route_marker(str(npc["language"]), world.knowledge)
	var globals: Dictionary = {
		"knows_local_route": partial_route,
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
	_partial_route = partial_route
	_outcome = ""
	_frame = _ink.advance()
	return true


func still_valid(world: SandboxWorld) -> bool:
	if offer_id.is_empty():
		return false
	var offer: Dictionary = world.offer_by_id(offer_id)
	return not offer.is_empty() and offer.get("status") == "open" \
			and offer.get("origin") == world.player_district and world.active_offer_id.is_empty()


func choose(index: int, world: SandboxWorld) -> bool:
	if _ink == null or not still_valid(world):
		return false
	var choices: Array = _frame.get("choices", [])
	if index < 0 or index >= choices.size():
		return false
	var result: Dictionary = _ink.choose(index)
	_frame = result
	var tags: Array = result.get("tags", [])
	# This can only learn a bounded phrase after a real language observation.
	if tags.has("intent:ask_destination"):
		world.observe_route_language(offer_id)
	# Ink tags describe a proposed speech act. World validates & owns the effect.
	if tags.has(ACTION_ACCEPT):
		_outcome = "accepted" if world.accept(offer_id) else "blocked"
	elif tags.has(ACTION_DECLINE):
		_outcome = "declined" if world.decline(offer_id) else "blocked"
	return true


func current_frame() -> Dictionary:
	return _frame.duplicate(true)


func outcome() -> String:
	return _outcome


func understood() -> bool:
	return _understood


func recognizes_route() -> bool:
	return _partial_route


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
	if not (_frame.get("choices") is Array) or not (_frame.get("tags") is Array):
		return false
	return true
