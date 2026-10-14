class_name InkBridge
extends RefCounted

# Small game-facing boundary around the vendored pure-GDScript Ink runtime.
# Callers receive authored text/choices/tags; they own all gameplay consequences.
var _runtime: Node
var _story: InkStory


func open_compiled(json_text: String, scene_tree: SceneTree) -> bool:
	if json_text.strip_edges().is_empty():
		return false
	var existing: Node = scene_tree.root.get_node_or_null("__InkRuntime")
	if existing == null:
		existing = load("res://addons/inkgd/ink_runtime.gd").new()
		scene_tree.root.add_child(existing)
	_runtime = existing
	_story = InkStory.new(json_text, _runtime)
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
	return {
		"text": "\n".join(lines),
		"tags": tags,
		"choices": options,
		"ended": options.is_empty() and not _story.can_continue
	}


func choose(index: int) -> Dictionary:
	assert(_story != null, "No Ink story is open.")
	assert(index >= 0 and index < _story.current_choices.size(), "Invalid Ink choice.")
	_story.choose_choice_index(index)
	return advance()
