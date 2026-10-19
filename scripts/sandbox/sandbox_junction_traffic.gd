class_name SandboxJunctionTraffic
extends Node2D

# Three native ambient kit vehicles, with no NPC identity, fare or world clock.
# Routes lie on the existing east block / T branch and end before the next
# junction. This is deliberately bounded; it does not invent city graph edges.
const IDS: Array[String]=["main","branch","following"]
# Native kit kinematics share the real vehicle motion profile. No additional
# city tick, NPC or physical entitlement is created for these ambient cars.
const SPEED: float=SandboxVehicleKinematics.CRUISE
const STOP_DISTANCE: float=50.0
const EXIT_X: float=890.0
# Three stopped bodies must fit beyond the east zebra and before the next
# marked crossing at x1100, not just clear the junction's conflict box.
const END_X: float=1070.0
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
		vehicle.current_speed=clampf(float(resume_state.get("speeds",{}).get(id,0.0)),
				0.0,SPEED)
		# Occupancy is reconstructed from physical route progress, never from a
		# saved token that could strand a queue with no body in the box.
		if _in_conflict(id): priority.owner=id
	for id in resume_state.get("queue",[]):
		if IDS.has(str(id)) and _waiting(str(id)): priority.request(str(id))
	# Admission may be saved before the body's first movement. Physical
	# reconstruction alone loses that request's FIFO ownership.
	if not str(resume_state.get("owner","")).is_empty(): priority.owner=str(resume_state["owner"])

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
	var speeds: Dictionary={}
	for id in IDS: speeds[id]=actors[id].current_speed
	return {"distances":distances.duplicate(),"queue":priority.queue.duplicate(),
			"owner":priority.owner,"speeds":speeds}

static func valid_snapshot(state: Variant) -> bool:
	if not state is Dictionary: return false
	if state.is_empty(): return true
	if not state.get("distances") is Dictionary or not state.get("queue") is Array: return false
	# Older native presenter snapshots may omit speed; they safely restart at
	# rest, but any provided speed must be finite, bounded and complete.
	var speeds: Variant=state.get("speeds",{})
	if not speeds is Dictionary: return false
	if not speeds.is_empty():
		if speeds.size()!=IDS.size(): return false
		for id in IDS:
			var speed: Variant=speeds.get(id,null)
			if not (speed is float or speed is int) or not is_finite(float(speed)) \
					or float(speed)<0.0 or float(speed)>SPEED+0.001: return false
	var owner: Variant=state.get("owner","")
	if not owner is String or (not owner.is_empty() and not IDS.has(owner)): return false
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
	if not owner.is_empty():
		if seen.has(owner) or float(state["distances"][owner])<STOP_DISTANCE-24.0 or points[owner].x>=EXIT_X: return false
		for id in IDS:
			if id!=owner and float(state["distances"][id])>STOP_DISTANCE+.01 and points[id].x<EXIT_X: return false
	for id in IDS:
		for other in IDS:
			if id==other: continue
			if points[id].distance_to(points[other])<31.0: return false
			if points[id].y>=349.9 and points[other].y>=349.9 and absf(points[id].x-points[other].x)<41.9: return false
	return true

func _physics_process(delta: float) -> void:
	step(delta)

func _release_cleared_owner() -> void:
	if not priority.owner.is_empty() and actors[priority.owner].position.x>=EXIT_X:
		priority.release(priority.owner,true)

func step(delta: float) -> void:
	if actors.is_empty() or delta<=0.0: return
	_release_cleared_owner()
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
		# Predictive service braking before a FIFO-owned stop line. Vehicle
		# admission never overrides a blocked downstream or the real body.
		var limit: float=SPEED
		if id!=priority.owner and current<=STOP_DISTANCE:
			limit=minf(limit,SandboxVehicleKinematics.braking_speed(
					STOP_DISTANCE-current))
		body.current_speed=minf(SandboxVehicleKinematics.next_speed(
				body.current_speed,limit,delta),limit)
		var next: float=minf(current+body.current_speed*delta,
				routes[id].get_baked_length())
		if id!=priority.owner and current<=STOP_DISTANCE:
			next=minf(next,STOP_DISTANCE)
		var goal: Vector2=_point(id,next)
		if goal.y>=349.9:
			for other in IDS:
				if other==id: continue
				var ahead: Vector2=actors[other].position
				if ahead.y>=349.9 and ahead.x>body.position.x:
					next=maxf(current,next-maxf(0.0,goal.x-(ahead.x-SandboxStreetPriority.FOLLOW_SPACING)))
					goal=_point(id,next)
		var start_position: Vector2=body.position
		body.velocity=global_transform.basis_xform(goal-body.position)/delta
		body.move_and_slide()
		# A hit body cannot keep accelerating against a wall. Its *actual*
		# Godot displacement, not an imagined route tick, owns kinetic speed.
		body.current_speed=clampf(body.position.distance_to(start_position)/delta,0.0,SPEED)
		# Advance only by actual physical displacement; a collider blocking the
		# owner cannot time out its token or teleport through the obstruction.
		if id!="branch": distances[id]=body.position.x-730.0
		else: distances[id]=routes[id].get_closest_offset(body.position)
		var tangent: Vector2=_point(id,float(distances[id])+.5)-_point(id,float(distances[id])-.5)
		if tangent.length_squared()>.001: body.rotation=tangent.angle()
	# Input/save callbacks may run before the next physics tick. Complete the
	# physical clearance transition in this tick so every live state is saveable.
	_release_cleared_owner()
