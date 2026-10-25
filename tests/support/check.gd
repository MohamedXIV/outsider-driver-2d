class_name Check
extends RefCounted

# Fast-failing checks for --script tests (Epic #89, issue #92).
#
# A failed check prints exactly one "FAIL <file>:<line>: <message>" line and
# asks the SceneTree to quit with code 1. The gate kills the run on that line
# instead of waiting for its timeout.
#
# GDScript cannot return from the caller in here, so every call site is written
# as:   if not Check.ok(condition, "message"): return
# Keep the `return`; without it the rest of the test body still runs.

static func ok(condition: bool, message: String = "") -> bool:
	if condition:
		return true
	var where: String = "unknown"
	var stack: Array = get_stack()
	if stack.size() > 1:
		where = "%s:%d" % [stack[1]["source"], stack[1]["line"]]
	var detail: String = message if not message.is_empty() else "condition is false"
	print("FAIL %s: %s" % [where, detail])
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.quit(1)
	return false


static func finish(tree: SceneTree, name: String) -> void:
	print("PASS %s" % name)
	tree.quit(0)
