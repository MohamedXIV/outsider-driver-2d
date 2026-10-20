class_name SandboxWorldVehicleBody
extends CharacterBody2D

# A replaceable physical adapter for an EXISTING World journey. No drawing,
# resident creation, fare completion or independent route timer lives here.
var world: SandboxWorld
var vehicle_id: String=""
var _identity: String=""
var identity: String:
	get: return _identity
const BODY_SIZE: Vector2=Vector2(25,13)
const CLEARANCE: float=4.0

func bind(state: SandboxWorld,id: String,fraction: float=0.0) -> bool:
	if world!=null or not SandboxVehicleExecution.bind(state,id,fraction): return false
	world=state;vehicle_id=id
	_identity=id if id=="player" or world.vehicle_departures.has(id) else "shuttle:"+str(world.vehicle_execution[id]["source"])
	collision_layer=16
	collision_mask=2|4|16
	var shape: CollisionShape2D=CollisionShape2D.new()
	var rectangle: RectangleShape2D=RectangleShape2D.new()
	rectangle.size=BODY_SIZE
	shape.shape=rectangle
	add_child(shape)
	position=SandboxVehicleExecution.screen(world,id,fraction)
	rotation=SandboxVehicleExecution.heading(world,id,fraction)
	return true

func release(fraction: float=0.0) -> void:
	if world!=null: SandboxVehicleExecution.unbind(world,vehicle_id,fraction)

# Monotone cumulative lane length avoids both repeated curve inversion and
# the ambiguous chord inverse on a bend that turns back towards its origin.
const ARC_STEP: float=.02
var _arc: PackedFloat64Array=[]
var _arc_total: float=0.0

func _prepare_arc(travel: Dictionary) -> void:
	if not _arc.is_empty(): return
	_arc_total=float(SandboxRoads.path_minutes(SandboxVehicleExecution.nodes_of(travel)))
	_arc.append(0.0)
	var previous: Vector2=SandboxVehicleExecution.point(travel,0.0)
	for index in range(1,int(ceil(_arc_total/ARC_STEP))+1):
		var point: Vector2=SandboxVehicleExecution.point(travel,minf(_arc_total,float(index)*ARC_STEP))
		_arc.append(_arc[-1]+previous.distance_to(point))
		previous=point

func _at_distance(travel: Dictionary,start: float,distance: float) -> float:
	_prepare_arc(travel)
	var index: int=mini(int(start/ARC_STEP),_arc.size()-2)
	var origin: float=lerpf(_arc[index],_arc[index+1],clampf((start-float(index)*ARC_STEP)/ARC_STEP,0.0,1.0))
	var target: float=origin+maxf(0.0,distance)
	var low: int=index
	var high: int=_arc.size()-1
	while high-low>1:
		var middle: int=(low+high)/2
		if _arc[middle]>target: high=middle
		else: low=middle
	var fraction: float=clampf((target-_arc[low])/maxf(.0000001,_arc[high]-_arc[low]),0.0,1.0)
	return minf(_arc_total,minf(float(travel["base"])+world.vehicle_fraction+SandboxVehicleExecution.LOOKAHEAD_MINUTES,
		(float(low)+fraction)*ARC_STEP))


func _pose_clear(at: Vector2,facing: float) -> bool:
	var query: PhysicsShapeQueryParameters2D=PhysicsShapeQueryParameters2D.new()
	query.shape=(get_child(0) as CollisionShape2D).shape
	query.transform=global_transform*transform.affine_inverse()*Transform2D(facing,at)
	query.collision_mask=collision_mask
	query.exclude=[get_rid()]
	# Half of the maximum .02-radian corner displacement. Consecutive
	# footprints therefore cover the angular sweep, including small obstacles.
	query.margin=.15
	return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _turn_clear(at: Vector2,current: float,facing: float) -> bool:
	var angle: float=angle_difference(current,facing)
	var samples: int=maxi(1,int(ceil(absf(angle)/.02)))
	for index in range(1,samples+1):
		if not _pose_clear(at,current+angle*float(index)/float(samples)): return false
	return true


func step(delta: float) -> bool:
	if world==null or not is_finite(delta) or delta<=0.0: return false
	var travel: Dictionary=SandboxVehicleExecution.trip(world,vehicle_id)
	var state: Dictionary=world.vehicle_execution.get(vehicle_id,{})
	if travel.is_empty() or state.is_empty() or not bool(state["native"]): return false
	var at: float=float(state["progress"])
	var speed: float=float(state["speed"])
	var direction: Vector2=SandboxVehicleExecution.tangent(travel,at)
	var alignment: float=maxf(0.0,cos(angle_difference(float(state["heading"]),direction.angle())))
	var target: float=SandboxVehicleKinematics.CRUISE*alignment*alignment
	var reason: String="motion"
	var available: float=36.0
	var total: float=float(SandboxRoads.path_minutes(SandboxVehicleExecution.nodes_of(travel)))
	if total-at<=SandboxVehicleExecution.LOOKAHEAD_MINUTES:
		available=minf(available,position.distance_to(SandboxVehicleExecution.point(travel,total)))
		if available<36.0: reason="arrival"
	var junction_stop: float=SandboxVehicleJunctions.stop_progress(world,vehicle_id)
	if is_finite(junction_stop):
		available=maxf(0.0,position.distance_to(SandboxVehicleExecution.point(travel,junction_stop))-BODY_SIZE.x*.5-CLEARANCE)
		available=minf(36.0,available)
		reason="junction"
	if travel["held"]:
		target=0.0;available=0.0;reason="world_crossing"
	else:
		# Sweep the real collision shape over the curved lane, rather than
		# treating an unobstructed tangent as permission to cross a junction.
		for sample in range(1,19):
			var distance: float=float(sample)*2.0
			if distance>available: break
			var cursor: float=_at_distance(travel,at,distance)
			var point: Vector2=SandboxVehicleExecution.point(travel,cursor)
			var predicted: float=SandboxVehicleKinematics.turn_heading(float(state["heading"]),SandboxVehicleExecution.tangent(travel,cursor).angle(),distance/maxf(speed,1.0))
			if test_move(global_transform,point-position) or not _pose_clear(point,predicted):
				available=maxf(0.0,distance-2.0-CLEARANCE)
				reason="vehicle";break
		target=minf(target,SandboxVehicleKinematics.braking_speed(available,delta))
	var next: float=SandboxVehicleKinematics.next_speed(speed,target,delta)
	var distance: float=minf(available,next*delta)
	var cursor: float=_at_distance(travel,at,distance) if distance>0.0 else at
	var point: Vector2=SandboxVehicleExecution.point(travel,cursor)
	# Vector2 precision can leave a subpixel residual forever. Commit the exact
	# authored endpoint only after service braking has reduced speed to rest.
	if reason=="arrival" and next<.05 and point.distance_to(SandboxVehicleExecution.point(travel,total))<.001:
		cursor=total;point=SandboxVehicleExecution.point(travel,total);next=0.0
	var desired: float=SandboxVehicleExecution.tangent(travel,cursor).angle()
	var facing: float=float(state["heading"]) if travel["held"] or (reason=="junction" and distance<.000001) else SandboxVehicleKinematics.turn_heading(float(state["heading"]),desired,delta)
	# The final sweep fails closed, including obstacles inserted this frame.
	if test_move(global_transform,point-position) or not _turn_clear(point,float(state["heading"]),facing):
		cursor=at;point=position;next=0.0;reason="vehicle";facing=float(state["heading"])
	if not SandboxVehicleExecution.report(world,vehicle_id,cursor,next,facing,reason,point): return false
	position=point
	rotation=facing
	return true
