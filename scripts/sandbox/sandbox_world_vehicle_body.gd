class_name SandboxWorldVehicleBody
extends CharacterBody2D

# A replaceable physical adapter for an EXISTING World journey. No drawing,
# resident creation, fare completion or independent route timer lives here.
var world: SandboxWorld
var vehicle_id: String=""
var _identity: String=""
var identity: String:
	get: return _identity
const BODY_SIZE: Vector2=SandboxVehicleKinematics.BODY_SIZE
const CLEARANCE: float=SandboxVehicleKinematics.CLEARANCE
var _query: PhysicsShapeQueryParameters2D
var _space_transform: Transform2D
var _motion_query: PhysicsTestMotionParameters2D=PhysicsTestMotionParameters2D.new()
var _peers: Array=[]

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
	_query=PhysicsShapeQueryParameters2D.new()
	_query.shape=rectangle;_query.exclude=[get_rid()]
	_query.collision_mask=collision_mask;_query.margin=.15
	position=SandboxVehicleExecution.screen(world,id,fraction)
	rotation=SandboxVehicleExecution.heading(world,id,fraction)
	add_to_group("_world_vehicle_execution_bodies")
	return true

func release(fraction: float=0.0) -> void:
	if world!=null: SandboxVehicleExecution.unbind(world,vehicle_id,fraction)

# Monotone cumulative lane length avoids both repeated curve inversion and
# the ambiguous chord inverse on a bend that turns back towards its origin.
const ARC_STEP: float=.02
var _arc: PackedFloat64Array=[]
var _arc_points: PackedVector2Array=[]
var _arc_total: float=0.0
var _arc_key: String=""

func _prepare_arc(travel: Dictionary) -> void:
	var key: String=str(travel.get("geometry_nodes",travel["nodes"]))+str(travel.get("incoming_node",""))
	if not _arc.is_empty() and key==_arc_key: return
	_arc_key=key;_arc.clear();_arc_points.clear()
	_arc_total=float(SandboxRoads.path_minutes(SandboxVehicleExecution.geometry_nodes(travel)))
	_arc.append(0.0)
	var previous: Vector2=SandboxVehicleExecution.point(travel,0.0)
	_arc_points.append(previous)
	for index in range(1,int(ceil(_arc_total/ARC_STEP))+1):
		var point: Vector2=SandboxVehicleExecution.point(travel,minf(_arc_total,float(index)*ARC_STEP))
		_arc.append(_arc[-1]+previous.distance_to(point))
		_arc_points.append(point)
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


func _sample_point(at: float) -> Vector2:
	var index: int=mini(int(clampf(at,0.0,_arc_total)/ARC_STEP),_arc_points.size()-2)
	return _arc_points[index].lerp(_arc_points[index+1],clampf((at-float(index)*ARC_STEP)/ARC_STEP,0.0,1.0))

# Kinematic server transforms commit on the next engine physics frame. A
# manual World advance can execute several vehicles before that frame. Use
# their actual current footprints, while retaining native sweeps for obstacles.
func _refresh_peers() -> void:
	_peers.clear()
	var excluded: Array[RID]=[get_rid()]
	for peer in get_tree().get_nodes_in_group("_world_vehicle_execution_bodies"):
		if peer==self or peer.world!=world or peer.collision_layer==0: continue
		_peers.append(peer);excluded.append(peer.get_rid())
	_query.exclude=excluded
	_motion_query.exclude_bodies=excluded

func _motion_blocked(point: Vector2) -> bool:
	_motion_query.from=global_transform
	_motion_query.motion=_space_transform.basis_xform(point-position)
	return PhysicsServer2D.body_test_motion(get_rid(),_motion_query)

func _peer_clear(pose: Transform2D) -> bool:
	var half: Vector2=BODY_SIZE*.5
	for peer in _peers:
		var other: Transform2D=peer.global_transform
		var offset: Vector2=other.origin-pose.origin
		var separated: bool=false
		for basis in [pose.x,pose.y,other.x,other.y]:
			var axis: Vector2=Vector2(basis).normalized()
			var reach: float=half.x*(absf(axis.dot(pose.x))+absf(axis.dot(other.x))) \
				+half.y*(absf(axis.dot(pose.y))+absf(axis.dot(other.y)))
			if absf(axis.dot(offset))>reach+_query.margin:
				separated=true;break
		if not separated: return false
	return true

func _pose_clear(at: Vector2,facing: float) -> bool:
	_query.transform=_space_transform*Transform2D(facing,at)
	return _peer_clear(_query.transform) and get_world_2d().direct_space_state.intersect_shape(_query,1).is_empty()

func _turn_clear(at: Vector2,current: float,facing: float) -> bool:
	var angle: float=angle_difference(current,facing)
	var samples: int=maxi(1,int(ceil(absf(angle)/.02)))
	for index in range(1,samples+1):
		if not _pose_clear(at,current+angle*float(index)/float(samples)): return false
	return true


func step(delta: float) -> bool:
	if world==null or not is_finite(delta) or delta<=0.0: return false
	_space_transform=global_transform*transform.affine_inverse()
	var travel: Dictionary=SandboxVehicleExecution.trip(world,vehicle_id)
	var state: Dictionary=world.vehicle_execution.get(vehicle_id,{})
	if travel.is_empty() or state.is_empty() or not bool(state["native"]): return false
	_refresh_peers()
	var at: float=float(state["progress"])
	var speed: float=float(state["speed"])
	var direction: Vector2=SandboxVehicleExecution.tangent(travel,at)
	var alignment: float=maxf(0.0,cos(angle_difference(float(state["heading"]),direction.angle())))
	var target: float=SandboxVehicleKinematics.CRUISE*alignment*alignment
	var reason: String="motion"
	var available: float=36.0
	var total: float=float(SandboxRoads.path_minutes(SandboxVehicleExecution.geometry_nodes(travel)))
	var limit: float=minf(total,float(travel["base"])+world.vehicle_fraction+SandboxVehicleExecution.LOOKAHEAD_MINUTES)
	available=minf(available,position.distance_to(SandboxVehicleExecution.point(travel,limit)))
	if total-at<=SandboxVehicleExecution.LOOKAHEAD_MINUTES:
		available=minf(available,position.distance_to(SandboxVehicleExecution.point(travel,total)))
		if available<36.0: reason="arrival"
	var crossing_clearance: float=SandboxVehicleCrossings.clearance(world,travel,at,position)
	if crossing_clearance<available:
		available=crossing_clearance;reason="pedestrian"
	var junction_stop: float=SandboxVehicleJunctions.stop_progress(world,vehicle_id)
	if is_finite(junction_stop):
		var hold_clearance: float=BODY_SIZE.x*.5+CLEARANCE
		var clinic: Dictionary=world.vehicle_junctions.get("clinic",{})
		if not clinic.is_empty() and clinic["vehicle"]!=vehicle_id and SandboxVehicleJunctions.next_window(travel,at).get("junction","")=="clinic":
			# The authored frontage bay lies outside the ordinary lane connector.
			# Queue outside its full curb/standback envelope while another genuine
			# journey owns this conflict, so its merge can clear the incoming lane.
			hold_clearance+=SandboxVehicleBays.CAR_OFFSET+SandboxVehicleBays.SHUTTLE_STANDOFF
		var junction_clearance: float=maxf(0.0,position.distance_to(SandboxVehicleExecution.point(travel,junction_stop))-hold_clearance)
		if junction_clearance<available: reason="junction"
		available=minf(available,junction_clearance)
	if travel["held"]:
		target=0.0;available=0.0;reason="world_crossing"
	else:
		# Sweep the real collision shape over the curved lane, rather than
		# treating an unobstructed tangent as permission to cross a junction.
		for sample in range(1,19):
			var distance: float=float(sample)*2.0
			if distance>available: break
			var cursor: float=_at_distance(travel,at,distance)
			var point: Vector2=_sample_point(cursor)
			var predicted: float=SandboxVehicleKinematics.turn_heading(float(state["heading"]),(_sample_point(cursor+.01)-_sample_point(cursor-.01)).angle(),distance/maxf(speed,1.0))
			if _motion_blocked(point) or not _pose_clear(point,predicted):
				available=maxf(0.0,distance-2.0-CLEARANCE)
				reason="vehicle";break
		target=minf(target,SandboxVehicleKinematics.braking_speed(available,delta))
	var next: float=SandboxVehicleKinematics.next_speed(speed,target,delta)
	var distance: float=minf(available,next*delta)
	var cursor: float=_at_distance(travel,at,distance) if distance>0.0 else at
	var point: Vector2=SandboxVehicleExecution.point(travel,cursor)
	# Vector2 precision can leave a subpixel residual forever. Commit the exact
	# authored endpoint only after service braking has reduced speed to rest.
	if reason in ["arrival","motion"] and next<.05 and point.distance_to(SandboxVehicleExecution.point(travel,limit))<.001:
		cursor=limit;point=SandboxVehicleExecution.point(travel,limit);next=0.0
	var desired: float=SandboxVehicleExecution.tangent(travel,cursor).angle()
	var facing: float=float(state["heading"]) if travel["held"] or (reason=="junction" and distance<.000001) else SandboxVehicleKinematics.turn_heading(float(state["heading"]),desired,delta)
	# The final sweep fails closed, including obstacles inserted this frame.
	if _motion_blocked(point) or not _turn_clear(point,float(state["heading"]),facing):
		cursor=at;point=position;next=0.0;reason="vehicle";facing=float(state["heading"])
	if not SandboxVehicleExecution.report(world,vehicle_id,cursor,next,facing,reason,point): return false
	position=point
	rotation=facing
	return true
