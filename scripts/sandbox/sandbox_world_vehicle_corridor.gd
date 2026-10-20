class_name SandboxWorldVehicleCorridor
extends Node2D

# Scene lifetime adapter. The World owns journeys, reservations and delays;
# this bounded set of invisible bodies supplies collision execution only.
const ENTER_RADIUS: float=420.0
const LEAVE_RADIUS: float=540.0
var world: SandboxWorld
var bodies: Dictionary={}
var parked: StaticBody2D

func attach(state: SandboxWorld) -> void:
	if world==state: return
	_clear(false)
	world=state
	world.vehicle_executor=step
	reconcile()

func _clear(handoff: bool) -> void:
	if world!=null and world.vehicle_executor==step: world.vehicle_executor=Callable()
	for id in bodies.keys(): _remove(str(id),handoff)
	_remove_parked()

func _exit_tree() -> void:
	_clear(true)

func _remove(id: String,handoff: bool) -> void:
	var body: SandboxWorldVehicleBody=bodies[id]
	if handoff: body.release(world.vehicle_fraction)
	body.collision_layer=0
	body.collision_mask=0
	body.queue_free()
	bodies.erase(id)

func _eligible(id: String) -> bool:
	var trip: Dictionary=SandboxVehicleExecution.trip(world,id)
	if trip.is_empty(): return false
	var segment: Dictionary=SandboxVehicleExecution.segment(trip,SandboxVehicleExecution.progress(world,id,world.vehicle_fraction))
	return not segment.is_empty() and SandboxDirectedLanes.has_profile(segment["from"],segment["to"]) \
		and SandboxRoads.map_position(segment["from"]).y==0.0 and SandboxRoads.map_position(segment["to"]).y==0.0

func _remove_parked() -> void:
	if parked==null: return
	parked.collision_layer=0
	parked.collision_mask=0
	parked.queue_free()
	parked=null

func _sync_parked() -> void:
	var pose: Dictionary=world.vehicle_parking.get("player",{})
	if world.is_travelling() or pose.is_empty():
		_remove_parked();return
	if parked==null:
		parked=StaticBody2D.new()
		parked.collision_layer=16
		parked.collision_mask=2|4|16
		var shape: CollisionShape2D=CollisionShape2D.new()
		var box: RectangleShape2D=RectangleShape2D.new()
		box.size=SandboxWorldVehicleBody.BODY_SIZE
		shape.shape=box
		parked.add_child(shape)
		add_child(parked)
	parked.position=Vector2(float(pose["x"]),float(pose["y"]))
	parked.rotation=float(pose["heading"])

func reconcile() -> void:
	if world==null: return
	_sync_parked()
	var focus: Vector2=SandboxCityView.project(world.player_position(world.vehicle_fraction))
	var candidates: Array[String]=["player"]
	for npc in world.residents:
		if npc.get("transit_method","")=="shuttle": candidates.append(str(npc["id"]))
	for id in bodies.keys():
		if not world.vehicle_execution.has(id) or not candidates.has(id) or not _eligible(str(id)) or bodies[id].position.distance_to(focus)>LEAVE_RADIUS:
			_remove(str(id),true)
	for id in candidates:
		if bodies.has(id) or not _eligible(id): continue
		var at: Vector2=SandboxVehicleExecution.screen(world,id,world.vehicle_fraction)
		if at.distance_to(focus)>ENTER_RADIUS: continue
		var body: SandboxWorldVehicleBody=SandboxWorldVehicleBody.new()
		add_child(body)
		if body.bind(world,id,world.vehicle_fraction): bodies[id]=body
		else: body.queue_free()

	# A restored native cursor outside this loaded corridor must resume
	# aggregate execution rather than hold an unseen shuttle indefinitely.
	for id in world.vehicle_execution.keys():
		if not bodies.has(id) and bool(world.vehicle_execution[id]["native"]):
			SandboxVehicleExecution.unbind(world,str(id),world.vehicle_fraction)

func step(seconds: float) -> void:
	if world==null or not is_finite(seconds) or seconds<=0.0: return
	reconcile()
	var left: float=seconds
	while left>.0000001:
		var dt: float=minf(left,1.0/60.0)
		# Stable genuine IDs make same-frame reservation admission deterministic.
		var ids: Array=bodies.keys()
		ids.sort()
		for id in ids:
			if not SandboxVehicleExecution.trip(world,str(id)).is_empty(): bodies[id].step(dt)
		left-=dt
