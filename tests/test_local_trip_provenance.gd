extends SceneTree
func _initialize() -> void:
	var world: SandboxWorld=SandboxWorld.new(29)
	var id: String=SandboxLocalPedestrianTrip.candidates(world)[0]
	assert(SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(SandboxLocalPedestrianTrip.handoff(world,id,.2))
	var forged: Dictionary=world.snapshot()
	for npc in forged["residents"]:
		if npc["id"]==id: npc["local_pedestrian_trip"]["status"]="walking"
	forged["events"].append({"minute":world.minute,"kind":"local_pedestrian_resumed","subject":id,
		"detail":{"site":SandboxLocalPedestrianTrip.PATCHWORKS_PARTS,"progress":.99}})
	assert(not SandboxWorld.new().restore_snapshot(forged),"Resume cannot invent progress without elapsed world time")
	forged=world.snapshot()
	for npc in forged["residents"]:
		if npc["id"]==id:
			npc["local_pedestrian_trip"]["status"]="arrived";npc["local_pedestrian_trip"]["arrived"]=world.minute
	forged["events"].append({"minute":world.minute,"kind":"local_pedestrian_arrived","subject":id,
		"detail":{"site":SandboxLocalPedestrianTrip.PATCHWORKS_PARTS}})
	assert(not SandboxWorld.new().restore_snapshot(forged),"Offscreen arrival must have completed its own distance")
	world.advance(1);assert(SandboxLocalPedestrianTrip.resume(world,id)>=.2)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	assert(SandboxLocalPedestrianTrip.handoff(world,id,.4));world.advance(20)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("LOCAL_TRIP_PROVENANCE_PASS time-grounded resume and arrival, real replay")
	quit()
