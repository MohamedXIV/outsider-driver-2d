class_name SandboxAlightView
extends Node2D

# Owns physical presentation only; SandboxWorld keeps source NPC and arrival.
var world: SandboxWorld
var npc_id: String = ""
var resume_state: Dictionary = {}
var reentry_fraction: float=0.0
var walker: SandboxAlightWalker
var _trip: Dictionary

func _ready() -> void:
	_trip = world.resident(npc_id).get("passenger_alight", {})
	if _trip.is_empty(): return
	var fraction: float = 0.0
	var far_pose: Vector2=Vector2.INF
	if _trip.get("status", "") == "offscreen":
		far_pose=SandboxPassengerAlight.offscreen_position(world,npc_id,reentry_fraction)
		fraction = SandboxPassengerAlight.resume(world, npc_id,reentry_fraction)
		if fraction < 0.0: return
	elif _trip.get("status", "") != "walking": return
	var a: Vector2 = SandboxAlightGeometry.start(_trip)
	var b: Vector2 = SandboxAlightGeometry.goal(_trip)
	var direction: Vector2 = (b-a).normalized()
	var across: Vector2 = direction.orthogonal() * 12.0
	var inset: Vector2 = direction * 9.0
	var nav: NavigationPolygon = NavigationPolygon.new()
	nav.vertices = PackedVector2Array([a-inset-across,b+inset-across,b+inset+across,a-inset+across])
	nav.add_polygon(PackedInt32Array([0,1,2,3]))
	var region: NavigationRegion2D = NavigationRegion2D.new()
	region.name = "ClinicIntakePavement"
	region.navigation_layers = 1
	region.navigation_polygon = nav
	add_child(region)
	walker = SandboxAlightWalker.new()
	walker.name = "Resident_" + npc_id.replace(":", "_")
	var start_position: Vector2 = far_pose if far_pose.is_finite() else SandboxAlightGeometry.at(_trip,fraction)
	if not resume_state.is_empty() and resume_state.get("npc_id", "") == npc_id:
		start_position = Vector2(float(resume_state["x"]), float(resume_state["y"]))
	walker.position = start_position
	walker.goal_position = b
	walker.reached.connect(_on_reached)
	add_child(walker)
	queue_redraw()

func _on_reached(point: Vector2) -> void:
	if SandboxPassengerAlight.arrive(world,npc_id,point) and walker != null:
		walker.queue_free()
		walker = null

func handoff(clock_fraction: float=0.0) -> bool:
	if walker == null or not is_instance_valid(walker): return false
	return SandboxPassengerAlight.handoff(world,npc_id,
			minf(.999999,SandboxAlightGeometry.progress(_trip,walker.position)),walker.position,clock_fraction)

func visual_snapshot() -> Dictionary:
	if walker == null or not is_instance_valid(walker): return {}
	return {"npc_id":npc_id,"x":walker.position.x,"y":walker.position.y}

func _draw() -> void:
	if _trip.is_empty(): return
	var a: Vector2 = SandboxAlightGeometry.start(_trip)
	var b: Vector2 = SandboxAlightGeometry.goal(_trip)
	# A visible, connected, road-side walkway to the actual clinic intake;
	# no free crossing of traffic asphalt is offered by its navigation mesh.
	draw_line(a,b,Color("819a92"),20.0,true)
	draw_line(a,b,Color("afbbad"),14.0,true)
	draw_circle(b,10.0,Color("425960"))
	draw_circle(b,5.0,Color("e0be82"))
