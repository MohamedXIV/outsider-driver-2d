class_name SandboxPedestrianActor
extends CharacterBody2D

signal reached_site(npc_id: String)
const SPEED: float = 72.0
const CROSS_X: float = SandboxStreetModule.CROSS_X
const NORTH_Y: float = SandboxStreetModule.NORTH_Y
const SOUTH_Y: float = SandboxStreetModule.SOUTH_Y
var npc_id: String = ""
var destination: Vector2
var crossing_reserved: bool = false
var crossing_completed: bool = false
var did_arrive: bool = false
var block_for_player: bool = false
var traffic: CharacterBody2D
var _agent: NavigationAgent2D
var _target_set: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 4
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = SandboxStreetModule.PEDESTRIAN_RADIUS
	shape.shape = circle
	add_child(shape)
	_agent = NavigationAgent2D.new()
	_agent.navigation_layers = 1
	_agent.path_desired_distance = 5.0
	_agent.target_desired_distance = 9.0
	_agent.radius = 8.0
	_agent.max_speed = SPEED
	_agent.avoidance_enabled = true
	_agent.velocity_computed.connect(_on_safe_velocity)
	add_child(_agent)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if did_arrive:
		velocity = Vector2.ZERO
		return
	# Navigation maps require a server synchronization before the first query.
	if NavigationServer2D.map_get_iteration_id(_agent.get_navigation_map()) == 0:
		return
	if not _target_set:
		# Destination is authored in the PARENT street-module coordinates,
		# not the moving character's local frame. Actor.to_global() would
		# incorrectly add the character's current position to the target.
		_agent.target_position = get_parent().to_global(destination)
		_target_set = true
	# NavigationAgent.is_navigation_finished() alone may be true for a
	# clipped/unreachable path. Arrival requires actual site proximity.
	if global_position.distance_to(get_parent().to_global(destination)) <= 9.0:
		did_arrive = true
		velocity = Vector2.ZERO
		_agent.set_velocity(Vector2.ZERO)
		reached_site.emit(npc_id)
		return
	# A crossing is completed only after the physical body clears the road.
	# This must be checked before the next right-of-way wait, otherwise a
	# resident already on the south pavement could remain blocked forever.
	if crossing_reserved and SandboxStreetModule.crossing_clear(position):
		crossing_completed = true
	# The crossing is the ONLY link between the two walkable sidewalk meshes.
	# Local right-of-way is separate from NavigationAgent's pathfinding.
	if not crossing_completed and position.x >= CROSS_X - 19.0:
		crossing_reserved = true
		if block_for_player or (traffic != null and \
				not SandboxStreetPriority.pedestrian_may_enter(traffic.position.x)):
			velocity = Vector2.ZERO
			_agent.set_velocity(Vector2.ZERO)
			return
	var next: Vector2 = _agent.get_next_path_position()
	var wanted: Vector2 = global_position.direction_to(next) * SPEED
	_agent.set_velocity(wanted)

func _on_safe_velocity(safe_velocity: Vector2) -> void:
	if did_arrive:
		return
	velocity = safe_velocity
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(1,2), 8.0, Color("213339"))
	draw_circle(Vector2.ZERO, 6.0, Color("d5be91"))
	draw_circle(Vector2(-1,-2), 2.0, Color("496778"))
