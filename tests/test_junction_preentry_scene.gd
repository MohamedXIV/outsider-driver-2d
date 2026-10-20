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
	# A save can occur in the exact frame a physical owner clears the box.
	for id in traffic.IDS:
		traffic.distances[id]=159.9 if id=="main" else 50.0
		traffic._place(id)
	traffic.priority.owner="main";traffic.priority.queue.assign(["branch","following"])
	# Already accelerating when the vehicle is about to clear the box.
	traffic.actors["main"].current_speed=12.0
	traffic.step(1.0/60.0)
	assert(traffic.actors["main"].position.x>=traffic.EXIT_X)
	assert(SandboxJunctionTraffic.valid_snapshot(traffic.snapshot()),"The clearance frame must remain saveable")
	print("JUNCTION_PREENTRY_PASS admission and FIFO survive save before movement; ghost owners rejected")
	quit()
