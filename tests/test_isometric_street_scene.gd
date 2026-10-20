extends SceneTree
const NativeRouteChecks=preload("res://tests/native_route_checks.gd")

const EVIDENCE: String="/tmp/od2d-iso-evidence"
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(EVIDENCE)
	var origin: Vector2=SandboxCityView.project(Vector3.ZERO)
	var east: Vector2=SandboxCityView.project(Vector3(1000,0,0))-origin
	var south: Vector2=SandboxCityView.project(Vector3(0,0,1000))-origin
	assert(east.x>0 and south.x<0 and is_equal_approx(east.y,-south.x*.5))
	assert(is_equal_approx(east.y,south.y),"Isometric X and Z axes must share true 2:1 slopes")
	assert(SandboxCityView.project(Vector3(1000,120,500)).y<
			SandboxCityView.project(Vector3(1000,0,500)).y)
	var forward: Vector2=SandboxIsoPresentation.lane_offset(0.0)
	var reverse: Vector2=SandboxIsoPresentation.lane_offset(PI)
	assert(forward.distance_to(-reverse)<.0001,"Opposing traffic must switch visual lanes")
	var base: PackedVector2Array=SandboxIsoPresentation.vehicle_quad(Vector2.ZERO,.3)
	var roof: PackedVector2Array=SandboxIsoPresentation.vehicle_quad(Vector2.ZERO,.3,SandboxIsoPresentation.CAR_ELEVATION)
	assert(base.size()==4 and roof.size()==4)
	for i in range(4):
		assert(absf(roof[i].y-base[i].y+SandboxIsoPresentation.CAR_ELEVATION)<.0001)
	assert(SandboxIsoPresentation.clinic_footprint().size()==4)
	# Native and Chromium must never triangulate zero-area vehicle sides.
	# Half the body sides collapse when the wheelbase aligns with screen Y.
	var degenerate_faces: int=0
	for angle in [0.0,PI*.5,PI,PI*1.5,PI*.25]:
		var ground: PackedVector2Array=SandboxIsoPresentation.vehicle_quad(Vector2.ZERO,angle)
		var raised: PackedVector2Array=SandboxIsoPresentation.vehicle_quad(
				Vector2.ZERO,angle,SandboxIsoPresentation.CAR_ELEVATION)
		for index in range(4):
			var face: PackedVector2Array=SandboxIsoPresentation.vehicle_side_face(ground,raised,index)
			var area: float=SandboxIsoPresentation.polygon_area(face)
			assert(is_finite(area) and area>=0.0)
			if area<=0.01: degenerate_faces+=1
	assert(degenerate_faces>0,"The regression must cover genuinely degenerate side faces")
	for i in range(721):
		var angle: float=TAU*float(i)/720.0
		var ground: PackedVector2Array=SandboxIsoPresentation.vehicle_quad(Vector2(10,20),angle)
		var raised: PackedVector2Array=SandboxIsoPresentation.vehicle_quad(Vector2(10,20),angle,
				SandboxIsoPresentation.CAR_ELEVATION)
		for side in range(4):
			var face: PackedVector2Array=SandboxIsoPresentation.vehicle_side_face(ground,raised,side)
			var v0: Vector2=face[0]
			for corner in [1,2]:
				var is_good: bool=SandboxIsoPresentation.valid_triangle(
						v0,face[corner],face[corner+1])
				if is_good: assert(face[corner].is_finite())
		# Ensure all accepted triangles have nonzero signed area even at
		# cardinal and nearly-cardinal headings (720 samples).
	var sample: PackedVector2Array=SandboxIsoPresentation.road_points("clinic","docks")
	assert(sample.size()==49 and sample[0].distance_to(
			SandboxCityView.project(SandboxRoads.map_position("clinic")))<.001)
	var world: SandboxWorld=SandboxWorld.new(9)
	var offer: Dictionary={}
	for candidate in world.open_offers():
		if candidate.get("origin", "") == "garage" and SandboxPassengerAlight.applicable(candidate):
			offer=candidate
			break
	assert(not offer.is_empty() and world.accept(str(offer["id"])))
	NativeRouteChecks.finish(world)
	assert(world.player_district=="clinic")
	var before: Dictionary=world.snapshot()
	var scene: Node=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._reset_local_pedestrian()
	scene._reset_passenger_alight()
	scene._world=world
	scene._city.world=world
	scene._city.restore_taxi_heading()
	scene._sync_passenger_alight()
	assert(scene._alight_view!=null)
	assert(world.snapshot()==before)
	scene._city._camera_initialized=false
	scene._city.zoom_preference=SandboxCityView.DEFAULT_ZOOM
	scene._city._zoom=SandboxCityView.DEFAULT_ZOOM
	await _shot(scene,"iso-clinic-close")
	scene._city.zoom_preference=SandboxCityView.MIN_ZOOM
	scene._city._zoom=SandboxCityView.MIN_ZOOM
	await _shot(scene,"iso-clinic-wide")
	assert(world.snapshot()==before,"Isometric projection cannot change NPC goals or fare history")
	assert(world.events.filter(func(e: Dictionary)->bool:
		return e.get("kind","")=="fare_settled" and e.get("subject","")==offer["id"]).size()==1)
	print("ISOMETRIC_STREET_SLICE_PASS 2:1 projection, lanes, raised vehicle, real clinic fare, immutable world, two screenshot scales")
	quit()

func _shot(scene: Node,label: String) -> void:
	scene._render()
	scene._city._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(EVIDENCE.path_join(label+".png"))==OK)
