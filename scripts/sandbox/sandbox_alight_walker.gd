class_name SandboxAlightWalker
extends CharacterBody2D

signal reached(goal_position: Vector2)
var goal_position: Vector2 = Vector2.ZERO
var _agent: NavigationAgent2D
var _target_ready: bool = false
var _arrived: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 2 | 4
	var shape: CollisionShape2D = CollisionShape2D.new()
	var body: CircleShape2D = CircleShape2D.new()
	body.radius = SandboxAlightGeometry.BODY_RADIUS
	shape.shape = body
	add_child(shape)
	_agent = NavigationAgent2D.new()
	_agent.navigation_layers = 1
	_agent.path_desired_distance = 3.0
	_agent.target_desired_distance = 2.5
	_agent.radius = SandboxAlightGeometry.BODY_RADIUS
	add_child(_agent)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if _arrived: return
	if NavigationServer2D.map_get_iteration_id(_agent.get_navigation_map()) == 0: return
	if not _target_ready:
		_agent.target_position = goal_position
		_target_ready = true
	if global_position.distance_to(goal_position) <= 3.0:
		_arrived = true
		velocity = Vector2.ZERO
		reached.emit(global_position)
		return
	var next: Vector2 = _agent.get_next_path_position()
	if not _agent.is_target_reachable(): # No imagined arrival through obstructed ground.
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(next) * SandboxAlightGeometry.WALK_SPEED
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(1,3),7.5,Color("172b30"))
	draw_circle(Vector2.ZERO,6.0,Color("c8b592"))
	draw_circle(Vector2(0,-3),2.5,Color("86b5aa"))
