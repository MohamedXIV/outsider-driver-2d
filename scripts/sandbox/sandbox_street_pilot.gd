class_name SandboxStreetPilot
extends Node2D

# One local presenter for at most two real SandboxWorld residents. Primary
# aliases retain existing fixture access; safety always uses the whole registry.
const CROSS_X: float=SandboxStreetModule.CROSS_X
const NORTH_Y: float=SandboxStreetModule.NORTH_Y
const SOUTH_Y: float=SandboxStreetModule.SOUTH_Y
const SITE: String=SandboxLocalPedestrianTrip.PATCHWORKS_PARTS
var world: SandboxWorld
var pedestrians: Dictionary={}
var pedestrian: SandboxPedestrianActor
var walking_npc_id: String=""
var world_reported_arrival: bool=false
var car: SandboxTrafficVehicle
var follower: SandboxTrafficVehicle
var car_yielded: bool=false
var embedded: bool=false
var resume_state: Dictionary={}
var reentry_fraction: float=0.0
var junction: SandboxJunctionTraffic

func _actor_snapshot(actor: SandboxPedestrianActor) -> Dictionary:
	return {"npc_id":actor.npc_id,"pedestrian_x":actor.position.x,"pedestrian_y":actor.position.y,
		"crossing_reserved":actor.crossing_reserved,"crossing_completed":actor.crossing_completed,
		"did_arrive":actor.did_arrive}

func visual_snapshot() -> Dictionary:
	_refresh_registry()
	if car==null or follower==null: return {}
	var state: Dictionary=_actor_snapshot(pedestrian) if pedestrian!=null else {}
	state.merge({"car_x":car.position.x,"car_y":car.position.y,
		"follower_x":follower.position.x,"follower_y":follower.position.y,
		"car_speed":car.current_speed,"follower_speed":follower.current_speed,"actors":{},
		"junction":junction.snapshot() if junction!=null else {}})
	for id in pedestrians: state["actors"][id]=_actor_snapshot(pedestrians[id])
	return state

func _ready() -> void:
	if world==null: world=SandboxWorld.new(8)
	SandboxStreetModule.install_navigation(self)
	SandboxStreetModule.install_east_junction(self)
	SandboxStreetModule.install_extension(self)
	SandboxStreetModule.install_curbs(self)
	junction=SandboxJunctionTraffic.new();junction.name="NativeTJunctionTraffic"
	junction.resume_state=resume_state.get("junction",{});add_child(junction)
	car=_make_lane_car("LocalTrafficCar",SandboxStreetModule.VEHICLE_START+Vector2(70,0))
	follower=_make_lane_car("LocalFollowingCar",SandboxStreetModule.VEHICLE_START)
	var ids: Array[String]=[]
	for id in resume_state.get("actors",{}):
		if world.resident(str(id)).get("local_pedestrian_trip",{}).get("status","") in ["walking","offscreen","arrived"]:
			ids.append(str(id))
	for id in SandboxLocalPedestrianTrip.candidates(world):
		if ids.size()<2 and not ids.has(id): ids.append(id)
	for id in ids: _spawn_resident(id)
	car.position=Vector2(clampf(float(resume_state.get("car_x",180.0)),100.0,570.0),350.0)
	follower.position=Vector2(minf(float(resume_state.get("follower_x",110.0)),car.position.x-SandboxStreetPriority.FOLLOW_SPACING),350.0)
	car.current_speed=clampf(float(resume_state.get("car_speed",0.0)),0.0,SandboxVehicleKinematics.CRUISE)
	follower.current_speed=clampf(float(resume_state.get("follower_speed",0.0)),0.0,SandboxVehicleKinematics.CRUISE)
	reconcile_reservations()
	if not embedded:
		var camera: Camera2D=Camera2D.new()
		camera.position=Vector2(325,355);camera.zoom=Vector2.ONE*1.7;add_child(camera)
		var notes: CanvasLayer=CanvasLayer.new();add_child(notes)
		var label: Label=Label.new();label.position=Vector2(24,20)
		label.text="OUTER MARGIN / Native resident sidewalks and reserved crossing"
		notes.add_child(label)
	queue_redraw()

func _spawn_resident(id: String) -> void:
	var trip: Dictionary=world.resident(id).get("local_pedestrian_trip",{})
	if trip.is_empty():
		if embedded: return
		if not SandboxLocalPedestrianTrip.begin(world,id,SITE): return
		trip=world.resident(id)["local_pedestrian_trip"]
	var slot: int=int(trip.get("slot",0))
	var at: Vector2=SandboxStreetModule.waypoints(slot)[0]
	if trip.get("status","")=="offscreen":
		at=SandboxLocalPedestrianTrip.offscreen_position(world,id,reentry_fraction)
		SandboxLocalPedestrianTrip.resume(world,id,reentry_fraction)
	var saved: Dictionary=resume_state.get("actors",{}).get(id,{})
	if saved.is_empty() and resume_state.get("npc_id","")==id: saved=resume_state
	if not saved.is_empty(): at=Vector2(float(saved.get("pedestrian_x",at.x)),float(saved.get("pedestrian_y",at.y)))
	var actor: SandboxPedestrianActor=SandboxPedestrianActor.new()
	actor.name="Resident_"+id.replace(":","_");actor.npc_id=id;actor.slot=slot;actor.position=at
	actor.destination=SandboxStreetModule.destination(slot)
	actor.traffic=car;actor.traffic_following=follower
	actor.crossing_reserved=bool(saved.get("crossing_reserved",false)) or trip.get("crossing_state","") in ["reserved","entered","cleared"]
	actor.crossing_completed=SandboxStreetModule.crossing_clear(at)
	actor.reached_site.connect(_on_resident_arrived)
	pedestrians[id]=actor;add_child(actor)
	if trip.get("status","")=="arrived":
		actor.position=at if not saved.is_empty() else actor.destination;actor.did_arrive=true
	if pedestrian==null:
		pedestrian=actor;walking_npc_id=id
	world_reported_arrival=world.resident(walking_npc_id).get("local_pedestrian_trip",{}).get("status","")=="arrived"

func loaded_ids() -> Array[String]:
	_refresh_registry()
	var ids: Array[String]=[]
	for id in pedestrians: ids.append(str(id))
	return ids

func _refresh_registry() -> void:
	# A missing body is not proof of clearance. Remove invalid view references
	# while leaving the resident's authoritative trip/reservation intact.
	for id in pedestrians.keys():
		if not is_instance_valid(pedestrians[id]) or not pedestrians[id].is_inside_tree():
			pedestrians.erase(id);continue
		var npc: Dictionary=world.resident(str(id))
		if npc.get("local_pedestrian_trip",{}).get("status","")=="arrived" \
				and (npc.get("location","")!="garage" or int(npc.get("transit_until",0))>0 or not str(npc.get("taxi_offer","")).is_empty()):
			pedestrians[id].queue_free();pedestrians.erase(id)
	if not is_instance_valid(pedestrian) or not pedestrians.has(walking_npc_id):
		pedestrian=null;walking_npc_id="";world_reported_arrival=false
		if not pedestrians.is_empty():
			walking_npc_id=str(pedestrians.keys()[0]);pedestrian=pedestrians[walking_npc_id]
			world_reported_arrival=world.resident(walking_npc_id).get("local_pedestrian_trip",{}).get("status","")=="arrived"

func reconcile_reservations() -> void:
	_refresh_registry()
	for id in pedestrians:
		var actor: SandboxPedestrianActor=pedestrians[id]
		var trip: Dictionary=world.resident(str(id)).get("local_pedestrian_trip",{})
		if trip.get("status","")!="walking": continue
		var in_road: bool=SandboxStreetModule.ROAD.grow(SandboxStreetModule.PEDESTRIAN_RADIUS).has_point(actor.position)
		if actor.path_blocked: SandboxLocalPedestrianTrip.withdraw(world,str(id),actor.position)
		if actor.crossing_reserved or in_road: SandboxLocalPedestrianTrip.reserve(world,str(id))
		if in_road: SandboxLocalPedestrianTrip.entered(world,str(id))
		if SandboxStreetModule.crossing_clear(actor.position):
			actor.crossing_completed=true
			SandboxLocalPedestrianTrip.clear(world,str(id))

func crossing_occupied() -> bool:
	reconcile_reservations()
	for id in pedestrians:
		var actor: SandboxPedestrianActor=pedestrians[id]
		if SandboxStreetModule.ROAD.grow(SandboxStreetModule.PEDESTRIAN_RADIUS).has_point(actor.position): return true
		if actor.crossing_reserved and not SandboxStreetModule.crossing_clear(actor.position): return true
	return not SandboxLocalPedestrianTrip.crossing_cleared_without_actor(world,loaded_ids())

func crossing_cleared() -> bool:
	return not crossing_occupied()

func cancel_resident(id: String) -> bool:
	_refresh_registry()
	if not pedestrians.has(id): return false
	var actor: SandboxPedestrianActor=pedestrians[id]
	if not SandboxLocalPedestrianTrip.cancel(world,id,actor.position): return false
	actor.set_physics_process(false);actor._motion_permitted=false;actor.velocity=Vector2.ZERO
	actor._agent.set_velocity(Vector2.ZERO)
	pedestrians.erase(id);actor.queue_free()
	if actor==pedestrian:
		pedestrian=null;walking_npc_id="";world_reported_arrival=false
		if not pedestrians.is_empty():
			walking_npc_id=str(pedestrians.keys()[0]);pedestrian=pedestrians[walking_npc_id]
	return true

func handoff_all(clock_fraction: float=0.0) -> void:
	reconcile_reservations()
	for id in pedestrians:
		var actor: SandboxPedestrianActor=pedestrians[id]
		var slot: int=int(world.resident(str(id)).get("local_pedestrian_trip",{}).get("slot",0))
		var phase: float=minf(.999999,SandboxStreetModule.progress_of(actor.position,slot))
		SandboxLocalPedestrianTrip.handoff(world,str(id),phase,actor.position,clock_fraction)

func _make_lane_car(label: String,start: Vector2) -> SandboxTrafficVehicle:
	var vehicle: SandboxTrafficVehicle=SandboxTrafficVehicle.new()
	vehicle.name=label;vehicle.position=start;vehicle.collision_layer=4;vehicle.collision_mask=2
	var hitbox: CollisionShape2D=CollisionShape2D.new()
	var shape: RectangleShape2D=RectangleShape2D.new();shape.size=Vector2(25,17)
	hitbox.shape=shape;vehicle.add_child(hitbox);add_child(vehicle)
	return vehicle

func _physics_process(delta: float) -> void:
	if car==null or follower==null: return
	# Observe newly committed World intent, including a second resident whose
	# eligibility changed after this module was loaded.
	for id in SandboxLocalPedestrianTrip.candidates(world):
		if not pedestrians.has(id) and not world.resident(id).get("local_pedestrian_trip",{}).is_empty():
			_spawn_resident(id)
	var occupied: bool=crossing_occupied()
	for actor in pedestrians.values():
		actor.block_for_player=embedded and (SandboxStreetRouteBinding.taxi_occupies_crosswalk(world) or SandboxWorldTraffic.occupies_zebra(world))
	var walker_ahead_of_leader: bool=false
	var walker_ahead_of_follower: bool=false
	for actor in pedestrians.values():
		if actor.crossing_reserved and not actor.crossing_completed and SandboxStreetModule.ROAD.has_point(actor.position):
			walker_ahead_of_leader=walker_ahead_of_leader or actor.position.x>car.position.x
			walker_ahead_of_follower=walker_ahead_of_follower or actor.position.x>follower.position.x
	# The exact right-of-way rules still own hard barriers. A bounded motion
	# profile approaches the stop gradually instead of snapping from cruise
	# to zero in the final frame; a real walker ahead overrides comfort.
	var leader_limit: float=SandboxStreetPriority.vehicle_velocity(
			car.position.x,occupied,false,delta,walker_ahead_of_leader)
	if occupied and car.position.x<=SandboxStreetPriority.stop_line() and not walker_ahead_of_leader:
		leader_limit=minf(leader_limit,SandboxVehicleKinematics.braking_speed(
				SandboxStreetPriority.stop_line()-car.position.x,delta))
	leader_limit=minf(leader_limit,SandboxVehicleKinematics.braking_speed(
			SandboxStreetPriority.LANE_END_X-car.position.x,delta))
	car.current_speed=SandboxVehicleKinematics.next_speed(car.current_speed,leader_limit,delta)
	# Never advance beyond a protected stop line even under a long frame.
	car.current_speed=minf(car.current_speed,leader_limit)
	if occupied and car.position.x<=SandboxStreetPriority.stop_line()+.1: car_yielded=true
	car.velocity=global_transform.x.normalized()*car.current_speed
	car.move_and_slide()
	var follower_limit: float=SandboxStreetPriority.follower_velocity(
			follower.position.x,car.position.x,occupied,false,delta,walker_ahead_of_follower)
	var gap_left: float=car.position.x-SandboxStreetPriority.FOLLOW_SPACING-follower.position.x
	follower_limit=minf(follower_limit,SandboxVehicleKinematics.braking_speed(gap_left,delta))
	if occupied and follower.position.x<=SandboxStreetPriority.stop_line() and not walker_ahead_of_follower:
		follower_limit=minf(follower_limit,SandboxVehicleKinematics.braking_speed(
				SandboxStreetPriority.stop_line()-follower.position.x,delta))
	follower.current_speed=SandboxVehicleKinematics.next_speed(follower.current_speed,follower_limit,delta)
	follower.current_speed=minf(follower.current_speed,follower_limit)
	follower.velocity=global_transform.x.normalized()*follower.current_speed
	follower.move_and_slide();queue_redraw()

func _on_resident_arrived(id: String) -> void:
	_refresh_registry()
	if not pedestrians.has(id): return
	var actor: SandboxPedestrianActor=pedestrians[id]
	var slot: int=int(world.resident(id).get("local_pedestrian_trip",{}).get("slot",0))
	if actor.position.distance_to(SandboxStreetModule.destination(slot))>9.0: return
	SandboxLocalPedestrianTrip.arrive(world,id,SITE)
	if id==walking_npc_id: world_reported_arrival=true

func _draw() -> void:
	SandboxStreetModule.paint(self)
	SandboxStreetModule.paint_east_junction(self)
	SandboxStreetModule.paint_extension(self)

func _process(_delta: float) -> void:
	if car!=null: car.queue_redraw()
	if follower!=null: follower.queue_redraw()
