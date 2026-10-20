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
	for delta in [1.0/30.0,1.0/60.0,1.0/120.0,.1]:
		await _reserved_zebra(delta)
	await _late_reservation()
	quit()

func _reserved_zebra(delta: float) -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	var id: String=SandboxLocalPedestrianTrip.candidate(world)
	assert(not id.is_empty() and SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(SandboxLocalPedestrianTrip.reserve(world,id))
	assert(world.reposition("market","margin_gate"))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	await physics_frame
	var previous: float=0.0
	var peak: float=0.0
	for frame in range(ceili(8.0/delta)):
		assert(body.step(delta))
		var speed: float=float(world.vehicle_execution["player"]["speed"])
		assert(speed-previous<=SandboxVehicleKinematics.ACCELERATION*delta+.001)
		assert(previous-speed<=SandboxVehicleKinematics.SERVICE_BRAKE*delta+.001)
		previous=speed;peak=maxf(peak,speed)
		await physics_frame
		if peak>1.0 and speed<.01 and world.vehicle_execution["player"]["reason"]=="pedestrian": break
	assert(peak>1.0 and previous<.01)
	assert(not SandboxStreetRouteBinding.taxi_occupies_crosswalk(world),"The whole stopped body must remain before the reserved paint")
	assert(world.begin_crossing_yield() and SandboxWorld.new().restore_snapshot(world.snapshot()))
	var held: Transform2D=body.transform
	assert(body.step(delta) and body.transform.is_equal_approx(held))
	assert(SandboxLocalPedestrianTrip.clear(world,id) and world.release_crossing_yield())
	for frame in range(ceili(1.0/delta)):
		assert(body.step(delta))
		await physics_frame
	assert(body.position.distance_to(held.origin)>.1 and world.residents.size()==9)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("VARIABLE_ZEBRA_PASS delta=",delta," reserved source=",id," gradual stop, held pose, clear release")
	body.queue_free();await physics_frame

func _late_reservation() -> void:
	var world: SandboxWorld=SandboxWorld.new(8)
	var id: String=SandboxLocalPedestrianTrip.candidate(world)
	assert(not id.is_empty() and SandboxLocalPedestrianTrip.begin(world,id,SandboxLocalPedestrianTrip.PATCHWORKS_PARTS))
	assert(world.reposition("market","margin_gate"))
	var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
	root.add_child(body);assert(body.bind(world,"player"))
	await physics_frame
	var reserved: bool=false
	var cleared: bool=false
	for frame in range(600):
		world.vehicle_fraction=float(frame%60)/60.0
		assert(body.step(1.0/60.0))
		var occupies: bool=SandboxStreetRouteBinding.taxi_occupies_crosswalk(world)
		if not reserved and occupies:
			assert(SandboxLocalPedestrianTrip.reserve(world,id));reserved=true
		if reserved and occupies:
			assert(not SandboxStreetRouteBinding.approaching(world),"A taxi already on paint must clear before the waiting walker enters")
		if reserved and not occupies:
			cleared=true;break
		if (frame+1)%60==0: assert(world.advance_elapsed(1))
		await physics_frame
	assert(reserved and cleared and world.residents.size()==9)
	assert(SandboxWorld.new().restore_snapshot(world.snapshot()))
	print("LATE_ZEBRA_PASS actual moving taxi clears occupied paint before a newly reserved real pedestrian")
	body.queue_free();await physics_frame
