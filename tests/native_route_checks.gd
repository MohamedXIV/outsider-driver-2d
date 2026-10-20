extends RefCounted

# Planned road minutes are an estimate, not a physical arrival command. Keep
# every original arrival/identity/economy assertion and bound extra World holds.
static func finish(world: SandboxWorld,domain_only_restore: bool=false) -> bool:
	if domain_only_restore:
		assert(not world.vehicle_executor.is_valid())
		# This copy intentionally has no native scene. Hand its saved cursors
		# off explicitly at their saved clock, preserving the execution ledger.
		for id in world.vehicle_execution.keys():
			if bool(world.vehicle_execution[id]["native"]): SandboxVehicleExecution.unbind(world,str(id),world.vehicle_fraction)
	if world.is_travelling():
		assert(world.advance(world.remaining_minutes))
		for delay in range(60):
			if not world.is_travelling(): break
			assert(world.advance(1))
	assert(not world.is_travelling(),"Real physical arrival must precede the next route or alight")
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	return true
