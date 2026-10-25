extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	if not Check.ok(world.accept("offer:npc:07:480"), "world.accept('offer:npc:07:480')"): return
	world.advance(1)
	var forged: Dictionary=world.snapshot()
	forged["residents"][7]["taxi_offer"]=""
	if not Check.ok(not SandboxWorld.new().restore_snapshot(forged), "Accepted passenger needs matching taxi tag"): return
	forged=world.snapshot();forged["offers"]=Array(forged["offers"],TYPE_NIL,"",null);forged["offers"].append(null)
	if not Check.ok(not SandboxWorld.new().restore_snapshot(forged), "Malformed offers reject cleanly"): return
	forged=world.snapshot();forged["events"]=Array(forged["events"],TYPE_NIL,"",null);forged["events"].append(null)
	if not Check.ok(not SandboxWorld.new().restore_snapshot(forged), "Malformed events reject cleanly"): return
	if not Check.ok(SandboxWorld.new().restore_snapshot(world.snapshot()), "restore_snapshot(world.snapshot())"): return
	Check.finish(self, "CITY_SAVE_VALIDATION passenger inverse and malformed arrays")
