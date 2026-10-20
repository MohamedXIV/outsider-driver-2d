extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _quad(body: Node2D,size: Vector2) -> PackedVector2Array:
	var polygon: PackedVector2Array=[]
	for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		polygon.append(body.global_transform*(corner*size*.5))
	return polygon
func _run() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	assert(world.reposition("market","margin_gate"))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	assert(SandboxVehicleExecution.report(world,"player",0.0,0.0,0.0,"motion"))
	body.rotation=0.0
	var obstacle: StaticBody2D=StaticBody2D.new()
	obstacle.collision_layer=16
	var shape: CollisionShape2D=CollisionShape2D.new()
	var box: RectangleShape2D=RectangleShape2D.new()
	box.size=Vector2(.1,.1);shape.shape=box;obstacle.add_child(shape)
	obstacle.position=body.position+Vector2(12.2,-6.85)
	root.add_child(obstacle)
	await physics_frame
	assert(body.step(1.0/60.0))
	for polygon in Geometry2D.intersect_polygons(_quad(body,SandboxWorldVehicleBody.BODY_SIZE),_quad(obstacle,box.size)):
		if SandboxIsoPresentation.polygon_area(polygon)>.00001:
			push_error("Turning in place penetrated an existing nearby obstacle");quit(1);return
	assert(absf(body.rotation)<.0001,"Occupied angular clearance must hold the heading")
	obstacle.queue_free();await physics_frame
	assert(body.step(1.0/60.0))
	assert(absf(body.rotation)>.001 and absf(body.rotation)<=SandboxVehicleKinematics.TURN_RATE/60.0+.0001)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("WORLD_VEHICLE_ROTATION_PASS real World taxi holds occupied angular sweep then resumes bounded yaw")
	quit()
