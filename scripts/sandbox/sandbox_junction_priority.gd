class_name SandboxJunctionPriority
extends RefCounted

# Bounded local admission, not a second transit simulation. The caller checks
# physical downstream space and whole-body clearance. No timer evicts a body.
var queue: Array[String]=[]
var owner: String=""

func request(id: String) -> void:
	if not id.is_empty() and id!=owner and not queue.has(id): queue.append(id)

func admit(exit_clear: bool) -> String:
	if owner.is_empty() and exit_clear and not queue.is_empty(): owner=queue.pop_front()
	return owner

func release(id: String, body_clear: bool) -> bool:
	if id!=owner or not body_clear: return false
	owner=""
	return true

func cancel(id: String) -> bool:
	if id==owner: return false
	if not queue.has(id): return false
	queue.erase(id)
	return true
