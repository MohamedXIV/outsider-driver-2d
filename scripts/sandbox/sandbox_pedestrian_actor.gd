class_name SandboxPedestrianActor
extends CharacterBody2D

signal reached_site(npc_id: String)
const SPEED: float = 72.0
const CROSS_X: float = SandboxStreetModule.CROSS_X
const NORTH_Y: float = SandboxStreetModule.NORTH_Y
const SOUTH_Y: float = SandboxStreetModule.SOUTH_Y
var npc_id: String = ""
var slot: int=0
var destination: Vector2
var crossing_reserved: bool = false
var crossing_completed: bool = false
var did_arrive: bool = false
var block_for_player: bool = false
var traffic: CharacterBody2D
var traffic_following: CharacterBody2D
var _agent: NavigationAgent2D
var _target_set: bool = false
var _motion_permitted: bool = false
var path_blocked: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 2 | 4 | 8 | 16
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = SandboxStreetModule.PEDESTRIAN_RADIUS
	shape.shape = circle
	add_child(shape)
	_agent = NavigationAgent2D.new()
	_agent.navigation_layers = 1
	_agent.path_desired_distance = 5.0
	_agent.target_desired_distance = 2.0
	_agent.radius = 8.0
	_agent.max_speed = SPEED
	_agent.avoidance_enabled = true
	# Keep the leading resident on course into the counter bay; the follower
	# supplies full local avoidance instead of pushing the leader past its
	# destination and outside the World handoff corridor.
	_agent.avoidance_priority = 0.75 if slot==0 else 0.5
	_agent.velocity_computed.connect(_on_safe_velocity)
	add_child(_agent)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	_motion_permitted=false
	if did_arrive:
		# An arrived body cannot reciprocate avoidance. Passing walkers must
		# take full responsibility for going around the stationary resident.
		_agent.avoidance_priority=1.0
		_agent.set_velocity(Vector2.ZERO)
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
	if global_position.distance_to(get_parent().to_global(destination)) <= 3.0:
		did_arrive = true
		velocity = Vector2.ZERO
		_agent.set_velocity(Vector2.ZERO)
		reached_site.emit(npc_id)
		return
	# Avoidance can displace a body after the agent consumed its final path
	# point. A finished path is not physical arrival: ask Godot for a new
	# path from the actual body rather than drifting with a zero intention.
	if _agent.is_navigation_finished():
		_agent.target_position=get_parent().to_global(destination)
	var next: Vector2=_agent.get_next_path_position()
	path_blocked=not _agent.is_target_reachable()
	if path_blocked:
		# An unreachable goal must not claim the road from the safe pavement.
		# Once physically in the road, retain the reservation and fail closed.
		if SandboxStreetModule.NORTH_SIDEWALK.encloses(Rect2(position-Vector2.ONE*7.0,Vector2.ONE*14.0)):
			crossing_reserved=false
		velocity=Vector2.ZERO;_agent.set_velocity(Vector2.ZERO)
		return
	# A crossing is completed only after the physical body clears the road.
	# This must be checked before the next right-of-way wait, otherwise a
	# resident already on the south pavement could remain blocked forever.
	if crossing_reserved and SandboxStreetModule.crossing_clear(position):
		crossing_completed = true
	# The crossing is the ONLY link between the two walkable sidewalk meshes.
	# A walker already IN the asphalt must finish rather than yield to a
	# trailing car that is itself waiting behind their collision body.
	var physically_committed: bool = crossing_reserved and SandboxStreetModule.ROAD.has_point(position)
	if not physically_committed and not crossing_completed and position.x >= CROSS_X - 19.0:
		crossing_reserved = true
		if block_for_player or (traffic != null and \
				not SandboxStreetPriority.pedestrian_may_enter(traffic.position.x)) \
				or (traffic_following != null and \
				not SandboxStreetPriority.pedestrian_may_enter(traffic_following.position.x)):
			velocity = Vector2.ZERO
			_agent.set_velocity(Vector2.ZERO)
			return
	_motion_permitted=true
	var wanted: Vector2 = global_position.direction_to(next) * SPEED
	_agent.set_velocity(wanted)

func _on_safe_velocity(safe_velocity: Vector2) -> void:
	if did_arrive or not _motion_permitted:
		velocity=Vector2.ZERO
		return
	velocity = safe_velocity
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(1,2), 8.0, Color("213339"))
	draw_circle(Vector2.ZERO, 6.0, Color("d5be91") if slot==0 else Color("91bdd5"))
	draw_circle(Vector2(-1,-2), 2.0, Color("496778"))
