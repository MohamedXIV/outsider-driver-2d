class_name SandboxStreetPilot
extends Node2D

# Reusable bounded Outer Margin street slice: standalone test or main-scene actor.
# Separate 2D NavigationRegions for sidewalks, a NavigationLink2D at the
# marked crossing, native CharacterBody2D movement and two yielding lane cars.
# The visible resident always belongs to one shared SandboxWorld; there
# is no second fake population or autonomous city traffic manager.
const CROSS_X: float = SandboxStreetModule.CROSS_X
const NORTH_Y: float = SandboxStreetModule.NORTH_Y
const SOUTH_Y: float = SandboxStreetModule.SOUTH_Y
const SITE: String = SandboxLocalPedestrianTrip.PATCHWORKS_PARTS
var world: SandboxWorld = SandboxWorld.new(8)
var pedestrian: SandboxPedestrianActor
var car: CharacterBody2D
var follower: CharacterBody2D
var car_yielded: bool = false
var world_reported_arrival: bool = false
var walking_npc_id: String = "npc:07"
var embedded: bool = false
var resume_state: Dictionary = {}

func visual_snapshot() -> Dictionary:
	if pedestrian == null or car == null or follower == null:
		return {}
	return {
		"npc_id": walking_npc_id,
		"pedestrian_x": pedestrian.position.x,
		"pedestrian_y": pedestrian.position.y,
		"car_x": car.position.x,
		"car_y": car.position.y,
		"follower_x": follower.position.x,
		"follower_y": follower.position.y,
		"crossing_reserved": pedestrian.crossing_reserved,
		"crossing_completed": pedestrian.crossing_completed,
		"did_arrive": pedestrian.did_arrive
	}


func _ready() -> void:
	if not embedded:
		# Standalone test mode still derives its pedestrian from live seeded
		# world needs, never a hard-coded guaranteed passenger.
		walking_npc_id = SandboxLocalPedestrianTrip.candidate(world)
		if walking_npc_id.is_empty():
			push_error("No available Patchworks resident for local walking test")
			return
	SandboxStreetModule.install_navigation(self)
	SandboxStreetModule.install_east_junction(self)
	# Two real Godot CharacterBody2D lane vehicles in this bounded slice.
	# These are ambient traffic actors, not extra world residents or taxis.
	car = _make_lane_car("LocalTrafficCar",
			SandboxStreetModule.VEHICLE_START+Vector2(70,0))
	follower = _make_lane_car("LocalFollowingCar",SandboxStreetModule.VEHICLE_START)
	pedestrian = SandboxPedestrianActor.new()
	pedestrian.name = "ResidentWalkingToPartsCounter"
	pedestrian.position = SandboxStreetModule.START
	pedestrian.destination = SandboxStreetModule.SITE
	pedestrian.npc_id = walking_npc_id
	pedestrian.traffic = car
	pedestrian.traffic_following = follower
	pedestrian.reached_site.connect(_on_resident_arrived)
	add_child(pedestrian)
	var current_trip: Dictionary = world.resident(walking_npc_id).get("local_pedestrian_trip", {})
	if current_trip.is_empty():
		assert(SandboxLocalPedestrianTrip.begin(world, walking_npc_id, SITE))
	elif current_trip.get("site", "") != SITE:
		push_error("Resident has a different local walking destination")
		return
	if resume_state.get("npc_id", "") == walking_npc_id:
		pedestrian.position = Vector2(
				clampf(float(resume_state.get("pedestrian_x",SandboxStreetModule.START.x)),100.0,560.0),
				clampf(float(resume_state.get("pedestrian_y",NORTH_Y)),300.0,404.0))
		car.position = Vector2(
				clampf(float(resume_state.get("car_x",SandboxStreetModule.VEHICLE_START.x+70.0)),100.0,570.0),
				clampf(float(resume_state.get("car_y",350.0)),330.0,374.0))
		follower.position = Vector2(
				minf(float(resume_state.get("follower_x",SandboxStreetModule.VEHICLE_START.x)),
						car.position.x-SandboxStreetPriority.FOLLOW_SPACING),
				clampf(float(resume_state.get("follower_y",350.0)),330.0,374.0))
		pedestrian.crossing_reserved = bool(resume_state.get("crossing_reserved",false))
		pedestrian.crossing_completed = bool(resume_state.get("crossing_completed",false))
		pedestrian.did_arrive = bool(resume_state.get("did_arrive",false))
	if current_trip.get("status", "") == "arrived":
		pedestrian.did_arrive = true
		pedestrian.position = SandboxStreetModule.SITE
		world_reported_arrival = true
	if embedded:
		queue_redraw()
		return
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(325, 355)
	camera.zoom = Vector2(1.7,1.7)
	camera.enabled = true
	add_child(camera)
	var notes: CanvasLayer = CanvasLayer.new()
	add_child(notes)
	var label: Label = Label.new()
	label.text = "OUTER MARGIN / Native Godot sidewalk + marked crossing pilot (issue #59 / #60)"
	label.position = Vector2(24,20)
	label.add_theme_color_override("font_color",Color("f1e1bd"))
	notes.add_child(label)
	queue_redraw()

func _make_lane_car(label: String, start: Vector2) -> CharacterBody2D:
	var vehicle: SandboxTrafficVehicle=SandboxTrafficVehicle.new()
	vehicle.name=label
	vehicle.position=start
	vehicle.collision_layer=4
	vehicle.collision_mask=2
	var hitbox: CollisionShape2D=CollisionShape2D.new()
	var shape: RectangleShape2D=RectangleShape2D.new()
	shape.size=Vector2(25,17)
	hitbox.shape=shape
	vehicle.add_child(hitbox)
	add_child(vehicle)
	return vehicle


func _physics_process(delta: float) -> void:
	# This one visible vehicle uses a lane and yields to the marked crossing.
	# Crossing priority is traffic policy, not an automatic NavMesh feature.
	if car == null or follower == null or pedestrian == null:
		return
	pedestrian.block_for_player = embedded and \
			(SandboxStreetRouteBinding.taxi_occupies_crosswalk(world) \
			or SandboxWorldTraffic.occupies_zebra(world))
	var occupied: bool = pedestrian.crossing_reserved and not pedestrian.crossing_completed
	var traffic_speed: float = SandboxStreetPriority.vehicle_velocity(
			car.position.x,pedestrian.crossing_reserved,
			pedestrian.crossing_completed,delta)
	if occupied and car.position.x <= SandboxStreetPriority.stop_line()+0.1:
		car_yielded = true
	car.velocity = Vector2(traffic_speed,0.0)
	car.move_and_slide()
	# The trailing body respects both the same pedestrian stop policy and
	# a non-overlapping physical headway behind the leader's latest position.
	var following_speed: float=SandboxStreetPriority.follower_velocity(
			follower.position.x,car.position.x,pedestrian.crossing_reserved,
			pedestrian.crossing_completed,delta)
	follower.velocity=Vector2(following_speed,0.0)
	follower.move_and_slide()
	queue_redraw()

func _on_resident_arrived(npc_id: String) -> void:
	if world_reported_arrival:
		return
	world_reported_arrival = SandboxLocalPedestrianTrip.arrive(world,npc_id,SITE)

func _draw() -> void:
	SandboxStreetModule.paint(self)
	SandboxStreetModule.paint_east_junction(self)

func _process(_delta: float) -> void:
	if car != null:
		car.queue_redraw()
	if follower != null:
		follower.queue_redraw()
