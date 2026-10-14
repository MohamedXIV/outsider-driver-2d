class_name InkBridge
extends RefCounted

# Small game-facing boundary around the vendored pure-GDScript Ink runtime.
# Callers receive authored text/choices/tags; they own all gameplay consequences.
var _runtime: Node
var _story: InkStory
var _last_frame: Dictionary = {}


func open_compiled(json_text: String, scene_tree: SceneTree) -> bool:
	if json_text.strip_edges().is_empty():
		return false
	var existing: Node = scene_tree.root.get_node_or_null("__InkRuntime")
	if existing == null:
		existing = load("res://addons/inkgd/ink_runtime.gd").new()
		scene_tree.root.add_child(existing)
	_runtime = existing
	_story = InkStory.new(json_text, _runtime)
	_last_frame = {}
	return _story != null


func advance() -> Dictionary:
	assert(_story != null, "Call open_compiled() before advancing Ink.")
	var lines: Array[String] = []
	var tags: Array[String] = []
	var steps: int = 0
	while _story.can_continue and steps < 128:
		steps += 1
		var line: String = _story.continue_story().strip_edges()
		if not line.is_empty():
			lines.append(line)
		for tag in _story.current_tags:
			tags.append(str(tag))
	assert(steps < 128, "Story continued for too long without a choice or ending.")
	var options: Array[String] = []
	for choice in _story.current_choices:
		options.append(str(choice.text))
	_last_frame = {
		"text": "\n".join(lines),
		"tags": tags,
		"choices": options,
		"ended": options.is_empty() and not _story.can_continue
	}
	return _last_frame.duplicate(true)


func choose(index: int) -> Dictionary:
	assert(_story != null, "No Ink story is open.")
	assert(index >= 0 and index < _story.current_choices.size(), "Invalid Ink choice.")
	_story.choose_choice_index(index)
	return advance()


func snapshot() -> Dictionary:
	if _story == null:
		return {}
	return {
		"runtime_state": _story.state.to_json(),
		"frame": _last_frame.duplicate(true)
	}


func restore_snapshot(saved: Dictionary) -> bool:
	if _story == null or not (saved.get("frame") is Dictionary):
		return false
	var json_text: String = str(saved.get("runtime_state", ""))
	if json_text.is_empty():
		return false
	_story.state.load_json(json_text)
	_last_frame = saved["frame"].duplicate(true)
	return true


func current_frame() -> Dictionary:
	return _last_frame.duplicate(true)
