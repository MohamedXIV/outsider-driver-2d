class_name SandboxWorldVehicleBody
extends CharacterBody2D

# A replaceable physical adapter for an EXISTING World journey. No drawing,
# resident creation, fare completion or independent route timer lives here.
var world: SandboxWorld
var vehicle_id: String=""
const BODY_SIZE: Vector2=Vector2(25,13)
const CLEARANCE: float=4.0

func bind(state: SandboxWorld,id: String,fraction: float=0.0) -> bool:
	if world!=null or not SandboxVehicleExecution.bind(state,id,fraction): return false
	world=state;vehicle_id=id
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

func _at_distance(travel: Dictionary,start: float,distance: float) -> float:
	var origin: Vector2=SandboxVehicleExecution.point(travel,start)
	var low: float=start
	var high: float=minf(float(travel["base"])+world.vehicle_fraction+SandboxVehicleExecution.LOOKAHEAD_MINUTES,
		float(SandboxRoads.path_minutes(SandboxVehicleExecution.nodes_of(travel))))
	for iteration in range(24):
		var middle: float=(low+high)*.5
		if SandboxVehicleExecution.point(travel,middle).distance_to(origin)>distance: high=middle
		else: low=middle
	return low

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
			if test_move(global_transform,point-position):
				available=maxf(0.0,distance-2.0-CLEARANCE)
				reason="vehicle";break
		target=minf(target,SandboxVehicleKinematics.braking_speed(available,delta))
	var next: float=SandboxVehicleKinematics.next_speed(speed,target,delta)
	var distance: float=minf(available,next*delta)
	var cursor: float=_at_distance(travel,at,distance) if distance>0.0 else at
	var point: Vector2=SandboxVehicleExecution.point(travel,cursor)
	var desired: float=SandboxVehicleExecution.tangent(travel,cursor).angle()
	var facing: float=float(state["heading"]) if travel["held"] or (reason=="junction" and distance<.000001) else SandboxVehicleKinematics.turn_heading(float(state["heading"]),desired,delta)
	# The final sweep fails closed, including obstacles inserted this frame.
	if test_move(global_transform,point-position):
		cursor=at;point=position;next=0.0;reason="vehicle"
	if not SandboxVehicleExecution.report(world,vehicle_id,cursor,next,facing,reason,point): return false
	position=point
	rotation=facing
	return true
