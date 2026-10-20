extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for delta in [1.0/30.0,1.0/60.0,1.0/120.0,.1]:
		var world: SandboxWorld=SandboxWorld.new(8)
		assert(world.reposition("market","margin_gate"))
		var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
		root.add_child(body);assert(body.bind(world,"player"))
		var block: StaticBody2D=StaticBody2D.new()
		block.collision_layer=16;block.collision_mask=16
		var shape: CollisionShape2D=CollisionShape2D.new()
		var rectangle: RectangleShape2D=RectangleShape2D.new()
		rectangle.size=Vector2(30,30);shape.shape=rectangle;block.add_child(shape)
		block.position=SandboxVehicleExecution.point(SandboxVehicleExecution.trip(world,"player"),1.8)
		root.add_child(block);await physics_frame
		var previous: float=0.0
		var peak: float=0.0
		for frame in range(ceili(2.0/delta)):
			assert(body.step(delta))
			var speed: float=float(world.vehicle_execution["player"]["speed"])
			assert(speed-previous<=SandboxVehicleKinematics.ACCELERATION*delta+.001)
			assert(previous-speed<=SandboxVehicleKinematics.SERVICE_BRAKE*delta+.001)
			previous=speed;peak=maxf(peak,speed)
			await physics_frame
		assert(peak>1.0 and previous<.01)
		assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
		print("VARIABLE_VEHICLE_PASS delta=",delta," peak=",peak," stop_progress=",world.vehicle_execution["player"]["progress"])
		body.queue_free();block.queue_free();await physics_frame
	quit()
