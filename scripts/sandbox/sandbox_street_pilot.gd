class_name SandboxStreetPilot
extends Node2D

# A standalone, inspectable Outer Margin street-module prototype.
# Separate 2D NavigationRegions for sidewalks, a NavigationLink2D at the
# marked crossing, native CharacterBody2D movement and one yielding car.
# The only simulated person comes from one SandboxWorld seed fixture; there
# is no second fake population or autonomous city traffic manager.
const CROSS_X: float = 320.0
const NORTH_Y: float = 313.0
const SOUTH_Y: float = 391.0
const SITE: String = SandboxLocalPedestrianTrip.PATCHWORKS_PARTS
var world: SandboxWorld = SandboxWorld.new(8)
var pedestrian: SandboxPedestrianActor
var car: CharacterBody2D
var car_yielded: bool = false
var world_reported_arrival: bool = false
var walking_npc_id: String = "npc:07"

func _ready() -> void:
	_build_sidewalk(Rect2(100, 300, 460, 26), "NorthSidewalk")
	_build_sidewalk(Rect2(100, 378, 460, 26), "SouthSidewalk")
	var link: NavigationLink2D = NavigationLink2D.new()
	link.name = "MarkedCrosswalkOnly"
	link.navigation_layers = 1
	link.bidirectional = true
	link.start_position = Vector2(CROSS_X, NORTH_Y)
	link.end_position = Vector2(CROSS_X, SOUTH_Y)
	add_child(link)
	car = SandboxTrafficVehicle.new()
	car.name = "LocalTrafficCar"
	car.position = Vector2(110, 350)
	car.collision_layer = 4
	car.collision_mask = 2
	var car_hitbox: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(25, 17)
	car_hitbox.shape = rect
	car.add_child(car_hitbox)
	add_child(car)
	pedestrian = SandboxPedestrianActor.new()
	pedestrian.name = "ResidentWalkingToPartsCounter"
	pedestrian.position = Vector2(155, NORTH_Y)
	pedestrian.destination = Vector2(500, SOUTH_Y)
	pedestrian.npc_id = walking_npc_id
	pedestrian.traffic = car
	pedestrian.reached_site.connect(_on_resident_arrived)
	add_child(pedestrian)
	assert(SandboxLocalPedestrianTrip.begin(world, walking_npc_id, SITE))
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

func _build_sidewalk(rect: Rect2, label: String) -> void:
	var polygon: NavigationPolygon = NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])
	polygon.add_polygon(PackedInt32Array([0,1,2,3]))
	var region: NavigationRegion2D = NavigationRegion2D.new()
	region.name = label
	region.navigation_layers = 1
	region.navigation_polygon = polygon
	add_child(region)

func _physics_process(delta: float) -> void:
	# This one visible vehicle uses a lane and yields to the marked crossing.
	# Crossing priority is traffic policy, not an automatic NavMesh feature.
	if car == null or pedestrian == null:
		return
	var crossing_occupied: bool = pedestrian.crossing_reserved and not pedestrian.crossing_completed
	var must_yield: bool = crossing_occupied and car.position.x < CROSS_X - 23.0
	if must_yield:
		car_yielded = true
		car.velocity = Vector2.ZERO
	elif crossing_occupied and car.position.x < CROSS_X + 37.0:
		car.velocity = Vector2.ZERO
	else:
		car.velocity = Vector2(36.0,0.0) if car.position.x < 550.0 else Vector2.ZERO
	car.move_and_slide()
	queue_redraw()

func _on_resident_arrived(npc_id: String) -> void:
	if world_reported_arrival:
		return
	world_reported_arrival = SandboxLocalPedestrianTrip.arrive(world,npc_id,SITE)

func _draw() -> void:
	# Modular geometry: standard frontage strips and fixed lanes, no invented
	# spline bending every road. Only the marked legal crossing connects sides.
	draw_rect(Rect2(95,328,475,48),Color("3f5555"))
	draw_rect(Rect2(95,300,475,26),Color("80908a"))
	draw_rect(Rect2(95,378,475,26),Color("80908a"))
	draw_line(Vector2(95,353),Vector2(570,353),Color("d1b985"),1.5)
	for x in range(112,570,40):
		if x > 300 and x < 345:
			continue
		draw_line(Vector2(x,353),Vector2(x+19,353),Color("e1be85"),2)
	for y in range(330,377,8):
		draw_rect(Rect2(CROSS_X-13,y,26,4),Color("e5d6a4"))
	draw_rect(Rect2(450,405,110,66),Color("8b7867"))
	draw_rect(Rect2(462,416,26,36),Color("d2c49f"))
	draw_rect(Rect2(160,235,90,62),Color("768987"))
	draw_rect(Rect2(270,235,80,62),Color("9d896f"))
	draw_rect(Rect2(390,235,110,62),Color("768987"))
	# Draw only the street surface; physical actors draw with their own nodes.
	draw_string(ThemeDB.fallback_font,Vector2(454,440),"PARTS",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("28383a"))

func _process(_delta: float) -> void:
	if car != null:
		car.queue_redraw()
