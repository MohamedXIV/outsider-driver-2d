extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _scene() -> Node:
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	scene._world=SandboxWorld.new(29);scene._city.world=scene._world;scene._process(.1)
	for actor in scene._street_pilot.pedestrians.values():
		actor.set_physics_process(false);actor._agent.avoidance_enabled=false
	return scene
func _run() -> void:
	var scene: Node=_scene()
	var pilot: SandboxStreetPilot=scene._street_pilot
	var lost: SandboxPedestrianActor=pilot.pedestrians["npc:04"]
	lost.position=Vector2(312,350);lost.crossing_reserved=true;pilot.reconcile_reservations()
	scene._on_save()
	var safe_save: String=FileAccess.get_file_as_string(SandboxSave.PATH)
	scene._street_pilot=null
	scene._on_save()
	assert(FileAccess.get_file_as_string(SandboxSave.PATH)==safe_save,"A wholly absent presenter cannot overwrite the last native state")
	scene._street_pilot=pilot
	lost.free() # Registry still references a freed body, unlike ordinary unload.
	assert(not pilot.loaded_ids().has("npc:04"),"A freed actor cannot count as a loaded body")
	assert(pilot.crossing_occupied() and not pilot.crossing_cleared())
	scene._on_save()
	assert(FileAccess.get_file_as_string(SandboxSave.PATH)==safe_save,"Missing physical state must not overwrite the last recoverable save")
	assert(scene._world.reposition("market","margin_gate"))
	for tick in range(15):
		scene._process(1.0)
		if not scene._world.route_hold_id.is_empty(): break
	assert(not scene._world.route_hold_id.is_empty(),"A reservation lost before approach must hold the actual taxi")
	var shuttle_held: bool=false
	for tick in range(400):
		scene._process(1.0)
		for npc in scene._world.residents:
			if npc.get("transit_hold_crossing","")==SandboxStreetRouteBinding.CROSSING_ID: shuttle_held=true
		if shuttle_held: break
	assert(shuttle_held,"A genuinely generated shuttle must also hold for the missing reserved body")
	scene.free()
	scene=_scene();pilot=scene._street_pilot
	for id in pilot.loaded_ids():
		pilot.pedestrians[id].position=Vector2(200,313)
		assert(pilot.cancel_resident(id))
	var junction: Dictionary=pilot.junction.snapshot()
	scene._on_save();scene._on_load()
	assert(scene._street_pilot!=null,"Cancelling all pedestrians cannot discard saved local vehicles")
	assert(scene._street_pilot.pedestrians.is_empty())
	assert(scene._street_pilot.junction.snapshot()==junction)
	assert(scene._world.residents.size()==9 and SandboxWorld.new().restore_snapshot(scene._world.snapshot()))
	scene.free()
	scene=_scene();pilot=scene._street_pilot
	for actor in pilot.pedestrians.values():
		actor.position=actor.destination;actor.did_arrive=true;pilot._on_resident_arrived(actor.npc_id)
	var departed: bool=false
	for tick in range(1000):
		scene._world.advance(1)
		if int(scene._world.resident("npc:04").get("transit_until",0))>scene._world.minute:
			departed=true;break
	assert(departed,"Canonical routines must generate an independent subsequent trip")
	assert(not pilot.loaded_ids().has("npc:04"),"A completed local actor cannot hide a resident's subsequent real trip")
	scene.free()
	scene=_scene();pilot=scene._street_pilot
	for actor in pilot.pedestrians.values():
		actor.position=actor.destination;actor.did_arrive=true;pilot._on_resident_arrived(actor.npc_id)
	var accepted: bool=false
	for tick in range(200):
		scene._world.advance(1)
		for offer in scene._world.open_offers():
			if offer["npc_id"]=="npc:04" and offer["origin"]=="garage" and offer["channel"]!="official":
				accepted=scene._world.accept(str(offer["id"]));break
		if accepted: break
	assert(accepted)
	assert(not pilot.loaded_ids().has("npc:04"),"A real taxi passenger cannot retain a duplicate counter body")
	scene.free()
	print("INTEGRATION_ACTOR_LIFECYCLE_PASS freed-body safety before taxi approach and all-cancelled queue persistence")
	quit()
