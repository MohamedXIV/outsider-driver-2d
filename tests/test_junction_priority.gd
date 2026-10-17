extends SceneTree
func _initialize() -> void:
	var priority: SandboxJunctionPriority=SandboxJunctionPriority.new()
	priority.request("main");priority.request("branch");priority.request("following")
	assert(priority.admit(false)=="","Blocked downstream must prevent box entry")
	assert(priority.admit(true)=="main")
	assert(not priority.release("main",false),"No timeout or cancellation may evict an occupied body")
	assert(not priority.cancel("main"))
	assert(priority.admit(true)=="main")
	assert(priority.release("main",true))
	assert(priority.admit(true)=="branch","Earlier queued approach must not starve")
	assert(priority.cancel("following"))
	assert(priority.release("branch",true))
	assert(priority.admit(true)=="")
	var saved: Dictionary={"distances":{"main":0.0,"branch":0.0,"following":-60.0},"queue":[]}
	assert(SandboxJunctionTraffic.valid_snapshot(saved))
	saved["distances"]["following"]=0.0
	assert(not SandboxJunctionTraffic.valid_snapshot(saved),"Overlapping restored bodies must be rejected")
	saved["distances"]={"main":70.0,"branch":70.0,"following":-60.0}
	assert(not SandboxJunctionTraffic.valid_snapshot(saved),"Two saved conflict owners cannot be accepted")
	print("JUNCTION_PRIORITY_PASS FIFO, blocked exit, non-preemptible occupancy and independent cancellation")
	quit()
