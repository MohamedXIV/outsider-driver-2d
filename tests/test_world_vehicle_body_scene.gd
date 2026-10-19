extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","margin_gate"))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body)
	assert(body.bind(world,"player"))
	var block: StaticBody2D=StaticBody2D.new()
	block.collision_layer=16
	block.collision_mask=16
	var collider: CollisionShape2D=CollisionShape2D.new()
	var rectangle: RectangleShape2D=RectangleShape2D.new()
	rectangle.size=Vector2(30,30)
	collider.shape=rectangle
	block.add_child(collider)
	var travel: Dictionary=SandboxVehicleExecution.trip(world,"player")
	block.position=SandboxVehicleExecution.point(travel,1.8)
	root.add_child(block)
	await physics_frame
	var previous: float=0.0
	var peak: float=0.0
	for frame in range(120):
		assert(body.step(1.0/60.0))
		var speed: float=float(world.vehicle_execution["player"]["speed"])
		assert(speed-previous<=SandboxVehicleKinematics.ACCELERATION/60.0+.001)
		assert(previous-speed<=SandboxVehicleKinematics.SERVICE_BRAKE/60.0+.001)
		peak=maxf(peak,speed)
		previous=speed
		await physics_frame
	assert(peak>1.0,"A stopped spawn is not a braking demonstration")
	assert(float(world.vehicle_execution["player"]["progress"])<1.8)
	assert(float(world.vehicle_execution["player"]["speed"])<.01)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	var stopped: Vector2=body.position
	block.queue_free()
	await physics_frame
	for frame in range(60):
		assert(body.step(1.0/60.0))
		await physics_frame
	assert(body.position.distance_to(stopped)>1.0)
	body.release(.5)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	body.queue_free()
	print("WORLD_VEHICLE_BODY_PASS real taxi ID, native obstacle sweep, gradual acceleration, saved stop and departure")
	quit()
