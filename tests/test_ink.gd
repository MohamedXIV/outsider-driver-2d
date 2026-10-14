extends SceneTree

# This test runs the *actual* GDScript Ink interpreter with authored Ink bytecode.
# Run after compiling stories/p1_probe.ink to stories/p1_probe.ink.json.
func _initialize() -> void:
	var file: String = "res://stories/p1_probe.ink.json"
	assert(FileAccess.file_exists(file), "Compile authored Ink before testing.")
	var json_text: String = FileAccess.get_file_as_string(file)
	assert(not json_text.is_empty(), "Compiled Ink missing.")

	var bridge: InkBridge = InkBridge.new()
	assert(bridge.open_compiled(json_text, self))
	var opening: Dictionary = bridge.advance()
	assert(str(opening.text).contains("harbor lights"), "Story did not run.")
	assert(opening.choices.size() == 2, "Expected two authored Ink choices.")
	var resume_snapshot: Dictionary = bridge.snapshot()
	var resume: InkBridge = InkBridge.new()
	assert(resume.open_compiled(json_text, self))
	assert(resume.restore_snapshot(resume_snapshot), "Failed restoring Ink interpreter state.")
	assert(resume.current_frame().choices.size() == 2)
	var first: Dictionary = bridge.choose(0)
	assert(str(first.text).contains("clinic checkpoint"), "First Ink branch was not selected.")
	assert(first.tags.has("fact:docks-route"), "Ink tag consequence missing.")
	assert(first.ended, "First Ink choice must end this probe.")

	assert(bridge.open_compiled(json_text, self))
	var again: Dictionary = bridge.advance()
	assert(again.choices.size() == 2)
	var second: Dictionary = bridge.choose(1)
	assert(str(second.text).contains("Quiet driver"), "Second Ink branch was not selected.")
	assert(second.tags.has("suspicion:1"), "Second Ink consequence missing.")
	assert(second.ended)
	print("P1_INK_NATIVE_PASS")
	quit(0)
