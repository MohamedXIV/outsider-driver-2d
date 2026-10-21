extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var pilot: SandboxStreetPilot=load("res://scenes/street_pilot.tscn").instantiate()
	root.add_child(pilot)
	var actor: SandboxPedestrianActor=pilot.pedestrian
	actor.set_physics_process(false)
	for i in range(3): await physics_frame
	# A consumed final path can be displaced by native avoidance. Preserve
	# the actual displaced pose; only a fresh native path may finish it.
	actor.position=SandboxStreetModule.SITE
	actor._agent.target_position=actor.global_position
	for i in range(3):
		await physics_frame
		actor._agent.get_next_path_position()
	assert(actor._agent.is_navigation_finished())
	actor.position-=Vector2(40,0)
	actor._target_set=true
	actor.crossing_completed=true
	actor.set_physics_process(true)
	for i in range(180):
		await physics_frame
		if actor.did_arrive: break
	assert(actor.did_arrive, "A consumed nav path must replan from the displaced physical body")
	assert(actor.position.distance_to(SandboxStreetModule.SITE)<3.1)
	print("PEDESTRIAN_REPLAN_PASS native final-path displacement cannot strand a resident")
	quit()
