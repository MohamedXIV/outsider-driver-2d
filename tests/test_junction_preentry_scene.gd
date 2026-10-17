extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var traffic: SandboxJunctionTraffic=SandboxJunctionTraffic.new();root.add_child(traffic)
	traffic.set_physics_process(false)
	traffic.distances={"main":50.0,"branch":50.0,"following":8.0}
	for id in traffic.IDS: traffic._place(id)
	traffic.priority.request("main");traffic.priority.request("branch")
	assert(traffic.priority.admit(true)=="main")
	var saved: Dictionary=traffic.snapshot()
	traffic.free();traffic=SandboxJunctionTraffic.new();traffic.resume_state=saved;root.add_child(traffic)
	traffic.set_physics_process(false)
	assert(traffic.priority.owner=="main","Save at the stop line must preserve the admitted owner before its first movement")
	assert(traffic.priority.queue==["branch"])
	assert(SandboxJunctionTraffic.valid_snapshot(saved))
	saved["owner"]="unknown";assert(not SandboxJunctionTraffic.valid_snapshot(saved))
	print("JUNCTION_PREENTRY_PASS admission and FIFO survive save before movement; ghost owners rejected")
	quit()
