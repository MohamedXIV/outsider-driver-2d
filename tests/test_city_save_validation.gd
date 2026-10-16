extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.accept("offer:npc:07:480"));world.advance(1)
	var forged: Dictionary=world.snapshot()
	forged["residents"][7]["taxi_offer"]=""
	assert(not SandboxWorld.new().restore_snapshot(forged),"Accepted passenger needs matching taxi tag")
	forged=world.snapshot();forged["offers"]=Array(forged["offers"],TYPE_NIL,"",null);forged["offers"].append(null)
	assert(not SandboxWorld.new().restore_snapshot(forged),"Malformed offers reject cleanly")
	forged=world.snapshot();forged["events"]=Array(forged["events"],TYPE_NIL,"",null);forged["events"].append(null)
	assert(not SandboxWorld.new().restore_snapshot(forged),"Malformed events reject cleanly")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("CITY_SAVE_VALIDATION_PASS passenger inverse and malformed arrays")
	quit()
