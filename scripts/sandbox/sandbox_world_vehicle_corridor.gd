class_name SandboxWorldVehicleCorridor
extends Node2D

# Scene lifetime adapter. The World owns journeys, reservations and delays;
# this bounded set of invisible bodies supplies collision execution only.
const ENTER_RADIUS: float=420.0
const LEAVE_RADIUS: float=540.0
var world: SandboxWorld
var bodies: Dictionary={}
var parked: StaticBody2D
var curb_residents: Dictionary={}

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
	for actor in curb_residents.values():
		actor.collision_layer=0;actor.queue_free()
	curb_residents.clear()

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
	# Aggregate and older sourced holds can project onto the paint. Preserve
	# their exact pose until clear, then enter native execution without a jump.
	if trip["held"] and (not world.vehicle_execution.has(id) or SandboxVehicleCrossings.native_occupies(SandboxVehicleCrossings.context(world),id)): return false
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

func _sync_curb_residents(focus: Vector2) -> void:
	var present: Array[String]=[]
	for npc in world.residents:
		var at: Vector2=SandboxVehicleDepartures.resident_screen(world,npc,world.vehicle_fraction)
		if not at.is_finite() or at.distance_to(focus)>LEAVE_RADIUS: continue
		var id: String=str(npc["id"])
		present.append(id)
		if not curb_residents.has(id):
			var actor: StaticBody2D=StaticBody2D.new()
			actor.collision_layer=2;actor.collision_mask=16
			var collider: CollisionShape2D=CollisionShape2D.new()
			var shape: CircleShape2D=CircleShape2D.new()
			shape.radius=SandboxAlightGeometry.BODY_RADIUS
			collider.shape=shape;actor.add_child(collider);add_child(actor)
			curb_residents[id]=actor
		curb_residents[id].position=at
	for id in curb_residents.keys():
		if not present.has(id):
			curb_residents[id].collision_layer=0;curb_residents[id].queue_free();curb_residents.erase(id)


func reconcile() -> void:
	if world==null: return
	_sync_parked()
	var focus: Vector2=SandboxCityView.project(world.player_position(world.vehicle_fraction))
	_sync_curb_residents(focus)
	var candidates: Array[String]=["player"]
	for id in world.vehicle_departures:
		if not SandboxVehicleDepartures.trip(world,str(id)).is_empty(): candidates.append(str(id))
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
	if world==null or not is_finite(seconds) or seconds<0.0: return
	reconcile()
	var left: float=seconds
	while left>.0000001:
		var dt: float=minf(left,1.0/60.0)
		# Stable genuine IDs make same-frame reservation admission deterministic.
		var ids: Array=bodies.keys()
		ids.sort()
		var changed: bool=false
		for id in ids:
			if SandboxVehicleExecution.trip(world,str(id)).is_empty(): continue
			var body: SandboxWorldVehicleBody=bodies[id]
			var before: Transform2D=body.transform
			if not body.step(dt):
				push_error("World rejected physical vehicle execution: "+str(id));return
			changed=changed or body.transform!=before or float(world.vehicle_execution[id]["speed"])>.000001
		left-=dt
		# A manual time-skip has no external physics frame inside this call.
		# Once every loaded body is stopped and unchanged, resweep at the next
		# World boundary instead of repeating identical blocked queries 60 times.
		if not changed: return
