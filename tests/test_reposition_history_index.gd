extends SceneTree

# Reposition source stays tied to the last authentic World event, even as
# subsequent NPC history expands. A restored World reconstructs this derived
# lookup without persisting a second authoritative source.
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.last_reposition_event_id.is_empty())
	assert(world.reposition("clinic"))
	var first: String=str(world.events.back()["id"])
	assert(world.last_reposition_event_id==first)
	assert(SandboxVehicleExecution.trip(world,"player")["source"]==first)
	world.advance(20)
	assert(SandboxVehicleExecution.trip(world,"player")["source"]==first)
	var save: Dictionary=world.snapshot()
	var recovered: SandboxWorld=SandboxWorld.new(1)
	assert(recovered.restore_snapshot(save))
	assert(recovered.last_reposition_event_id==first)
	assert(SandboxVehicleExecution.trip(recovered,"player")["source"]==first)
	for tick in range(140):
		if not recovered.is_travelling(): break
		assert(recovered.advance(1))
	assert(recovered.player_district=="clinic")
	assert(recovered.reposition("docks"))
	var second: String=str(recovered.events.back()["id"])
	assert(second!=first)
	assert(recovered.last_reposition_event_id==second)
	assert(SandboxVehicleExecution.trip(recovered,"player")["source"]==second)
	var after: SandboxWorld=SandboxWorld.new(2)
	assert(after.restore_snapshot(recovered.snapshot()))
	assert(after.last_reposition_event_id==second)
	assert(SandboxVehicleExecution.trip(after,"player")["source"]==second)
	print("REPOSITION_HISTORY_INDEX_PASS source matches ledger before/after Save/Load and next journey")
	quit()
