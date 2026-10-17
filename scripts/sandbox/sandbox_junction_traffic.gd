class_name SandboxJunctionTraffic
extends Node2D

# Three native ambient kit vehicles, with no NPC identity, fare or world clock.
# Routes lie on the existing east block / T branch and end before the next
# junction. This is deliberately bounded; it does not invent city graph edges.
const IDS: Array[String]=["main","branch","following"]
const SPEED: float=36.0
const STOP_DISTANCE: float=50.0
const EXIT_X: float=890.0
const END_X: float=1010.0
var priority: SandboxJunctionPriority=SandboxJunctionPriority.new()
var actors: Dictionary={}
var routes: Dictionary={}
var distances: Dictionary={}
var resume_state: Dictionary={}
var admitted: Array[String]=[]
var exit_blocked: bool=false

static func route(id: String) -> Curve2D:
	var path: Curve2D=Curve2D.new()
	var branch_x: float=SandboxStreetModule.T_BRANCH.get_center().x
	if id=="branch":
		path.add_point(Vector2(branch_x,240))
		path.add_point(Vector2(branch_x,326),Vector2.ZERO,Vector2(0,13.25))
		path.add_point(Vector2(SandboxStreetModule.T_BRANCH.end.x,350),Vector2(-13.25,0))
	else: path.add_point(Vector2(730,350))
	path.add_point(Vector2(END_X,350))
	return path

func _ready() -> void:
	for id in IDS:
		routes[id]=route(id)
		var initial: float=-60.0 if id=="following" else 0.0
		distances[id]=float(resume_state.get("distances",{}).get(id,initial))
		var vehicle: SandboxTrafficVehicle=SandboxTrafficVehicle.new()
		vehicle.name="Junction_"+id
		var hitbox: CollisionShape2D=CollisionShape2D.new()
		var shape: RectangleShape2D=RectangleShape2D.new();shape.size=Vector2(28,18)
		hitbox.shape=shape;vehicle.add_child(hitbox);add_child(vehicle)
		vehicle.collision_mask=2|4
		actors[id]=vehicle;_place(id)
		# Occupancy is reconstructed from physical route progress, never from a
		# saved token that could strand a queue with no body in the box.
		if _in_conflict(id): priority.owner=id
	for id in resume_state.get("queue",[]):
		if IDS.has(str(id)) and _waiting(str(id)): priority.request(str(id))

func _point(id: String, distance: float) -> Vector2:
	var path: Curve2D=routes[id]
	if distance<0.0: return path.get_point_position(0)+Vector2(distance,0)
	return path.sample_baked(distance)

func _place(id: String) -> void:
	var body: CharacterBody2D=actors[id]
	var phase: float=float(distances[id])
	body.position=_point(id,phase)
	var tangent: Vector2=_point(id,phase+.5)-_point(id,phase-.5)
	if tangent.length_squared()>.001: body.rotation=tangent.angle()

func _waiting(id: String) -> bool:
	return float(distances[id])>=STOP_DISTANCE-24.0 and float(distances[id])<=STOP_DISTANCE+.01

func _in_conflict(id: String) -> bool:
	return float(distances[id])>STOP_DISTANCE+.01 and actors[id].position.x<EXIT_X

func _exit_clear() -> bool:
	if exit_blocked: return false
	for id in IDS:
		var at: Vector2=actors[id].position
		if at.y>340.0 and at.x>=848.0 and at.x<EXIT_X+SandboxStreetPriority.FOLLOW_SPACING:
			return false
	return true

func snapshot() -> Dictionary:
	return {"distances":distances.duplicate(),"queue":priority.queue.duplicate()}

static func valid_snapshot(state: Variant) -> bool:
	if not state is Dictionary: return false
	if state.is_empty(): return true
	if not state.get("distances") is Dictionary or not state.get("queue") is Array: return false
	var seen: Array[String]=[]
	for id in state["queue"]:
		if not id is String or not IDS.has(id) or seen.has(id): return false
		seen.append(id)
	var points: Dictionary={}
	var occupants: int=0
	for id in IDS:
		var value: Variant=state["distances"].get(id)
		if not (value is int or value is float) or not is_finite(float(value)) \
				or float(value)<(-60.1 if id=="following" else -.1) or float(value)>route(id).get_baked_length()+.1: return false
		points[id]=Vector2(730+float(value),350) if float(value)<0.0 else route(id).sample_baked(float(value))
		if float(value)>STOP_DISTANCE+.01 and points[id].x<EXIT_X: occupants+=1
		if seen.has(id) and not (float(value)>=STOP_DISTANCE-24.0 and float(value)<=STOP_DISTANCE+.01): return false
	if occupants>1: return false
	for id in IDS:
		for other in IDS:
			if id==other: continue
			if points[id].distance_to(points[other])<31.0: return false
			if points[id].y>=349.9 and points[other].y>=349.9 and absf(points[id].x-points[other].x)<41.9: return false
	return true

func _physics_process(delta: float) -> void:
	step(delta)

func step(delta: float) -> void:
	if actors.is_empty() or delta<=0.0: return
	if not priority.owner.is_empty() and actors[priority.owner].position.x>=EXIT_X:
		priority.release(priority.owner,true)
	for id in IDS:
		if _waiting(id): priority.request(id)
	var before: String=priority.owner
	priority.admit(_exit_clear())
	if before.is_empty() and not priority.owner.is_empty(): admitted.append(priority.owner)
	# Move leading bodies first so the following car uses their updated space.
	var order: Array=IDS.duplicate()
	order.sort_custom(func(a: String,b: String) -> bool: return actors[a].position.x>actors[b].position.x)
	for id in order:
		var body: CharacterBody2D=actors[id]
		var current: float=float(distances[id])
		var next: float=minf(current+SPEED*delta,routes[id].get_baked_length())
		if id!=priority.owner and current<=STOP_DISTANCE: next=minf(next,STOP_DISTANCE)
		var goal: Vector2=_point(id,next)
		if goal.y>=349.9:
			for other in IDS:
				if other==id: continue
				var ahead: Vector2=actors[other].position
				if ahead.y>=349.9 and ahead.x>body.position.x:
					next=maxf(current,next-maxf(0.0,goal.x-(ahead.x-SandboxStreetPriority.FOLLOW_SPACING)))
					goal=_point(id,next)
		body.velocity=global_transform.basis_xform(goal-body.position)/delta
		body.move_and_slide()
		# Advance only by actual physical displacement; a collider blocking the
		# owner cannot time out its token or teleport through the obstruction.
		if id!="branch": distances[id]=body.position.x-730.0
		else: distances[id]=routes[id].get_closest_offset(body.position)
		var tangent: Vector2=_point(id,float(distances[id])+.5)-_point(id,float(distances[id])-.5)
		if tangent.length_squared()>.001: body.rotation=tangent.angle()
