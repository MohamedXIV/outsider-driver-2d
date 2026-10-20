extends SceneTree

func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(1)
	assert(world.reposition("docks","clinic"))
	assert(world.advance(41))
	assert(SandboxVehicleExecution.bind(world,"player"))
	assert(world.advance(10))
	assert(world.minute==531)
	var shuttle: String="npc:08"
	assert(world.resident(shuttle).get("transit_method","")=="shuttle")
	assert(SandboxVehicleExecution.bind(world,shuttle))
	assert(SandboxVehicleJunctions.claim(world,shuttle))
	assert(not SandboxVehicleJunctions.claim(world,"player"))
	assert(world.vehicle_junctions.size()==1)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var held: Dictionary=world.vehicle_junctions["clinic"]
	assert(held["vehicle"]==shuttle)
	var taxi_window: Dictionary=SandboxVehicleJunctions.next_window(SandboxVehicleExecution.trip(world,"player"),41.0)
	assert(not SandboxVehicleExecution.report(world,"player",float(taxi_window["entry"])+.01,0.0,0.0,"junction"))
	var copy: Dictionary=world.snapshot()
	copy["vehicle_junctions"]["clinic"]["vehicle"]="player"
	assert(not SandboxWorld.new().restore_snapshot(copy))
	var state: Dictionary=world.vehicle_execution[shuttle]
	assert(SandboxVehicleExecution.report(world,shuttle,9.8,5.0,float(state["heading"]),"motion"))
	assert(world.advance(1))
	assert(SandboxVehicleExecution.report(world,shuttle,10.8,5.0,float(state["heading"]),"motion"))
	assert(world.vehicle_junctions.is_empty())
	assert(SandboxVehicleJunctions.claim(world,"player"))
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(world.residents.size()==9)
	print("VEHICLE_JUNCTIONS_PASS real taxi and municipal service, exclusive connector, saved owner, forged owner rejected, clear and admit")
	quit()
