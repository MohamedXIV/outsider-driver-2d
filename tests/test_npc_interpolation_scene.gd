extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var world: SandboxWorld = scene._world
	assert(not world.is_travelling())
	var npc: Dictionary = world.resident("npc:07")
	var nodes: Array[String] = SandboxRoads.path("garage", "market")
	npc["transit_nodes"] = nodes
	npc["transit_started"] = world.minute
	npc["transit_until"] = world.minute + SandboxRoads.path_minutes(nodes) * 4
	npc["transit_method"] = "walking"
	npc["transit_to"] = "market"
	npc["transit_from_offer"] = "test:parked-npc"
	npc["activity"] = "travelling"
	var p0: Vector3 = world.npc_position(npc,0.0)
	scene._process(0.25)
	assert(is_equal_approx(scene._city.visual_fraction,0.25))
	var p1: Vector3 = world.npc_position(npc,scene._city.visual_fraction)
	scene._process(0.45)
	assert(is_equal_approx(scene._city.visual_fraction,0.70))
	var p2: Vector3 = world.npc_position(npc,scene._city.visual_fraction)
	assert(p1.distance_to(p0)>0.0)
	assert(p2.distance_to(p1)>0.0)
	assert(not world.is_travelling())
	print("NPC_INTERPOLATION_PASS parked taxi continuously updates resident render fraction")
	quit()
