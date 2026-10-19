class_name SandboxCityView
extends Node2D

signal waypoint_clicked(district: String)
const SCALE: float = 0.12
var world: SandboxWorld
var preview_nodes: Array[String] = []
var visual_fraction: float = 0.0
var local_active_npc_id: String = ""
var local_active_npc_ids: Array[String]=[]
var reduced_motion: bool = false
var ui_rtl: bool = false
const DEFAULT_ZOOM: float = 2.6
const MIN_ZOOM: float = 1.25
const MAX_ZOOM: float = 4.0
var zoom_preference: float = DEFAULT_ZOOM
var _zoom: float = DEFAULT_ZOOM
var _camera_initialized: bool = false

func set_manual_zoom(value: float) -> void:
	if is_finite(value):
		zoom_preference = clampf(value, MIN_ZOOM, MAX_ZOOM)

var _heading: float = 0.0
var _heading_initialized: bool = false
var _last_parked_stop: String = ""

# Road tangents belong to the same projected geometry as the taxi's location.
# A settled trip's last completed road edge gives the parked vehicle a physical
# arrival direction even after the active route has been cleared.
static func edge_heading(from: String, to: String, fraction: float) -> float:
	var t: float = clampf(fraction, 0.0, 1.0)
	var p: Vector2 = project(SandboxRoads.sample_edge(from, to, maxf(0.0, t - .002)))
	var q: Vector2 = project(SandboxRoads.sample_edge(from, to, minf(1.0, t + .002)))
	return (q - p).angle() if p.distance_squared_to(q) > .000001 else 0.0

static func world_road_heading(state: SandboxWorld, fraction: float = 0.0) -> float:
	if state.is_travelling():
		var elapsed: float = SandboxDirectedLanes.taxi_elapsed_minutes(state,fraction)
		var tangent: Vector2 = SandboxDirectedLanes.route_screen_tangent_at_minutes(
				state.route_nodes,elapsed)
		if tangent.length_squared() > 0.000001: return tangent.angle()
		var a: String = state.route_nodes[state.route_segment]
		var b: String = state.route_nodes[state.route_segment+1]
		return edge_heading(a,b,float(state.route_edge_elapsed)/float(SandboxRoads.edge_minutes(a,b)))
	for i in range(state.events.size() - 1, -1, -1):
		var event: Dictionary = state.events[i]
		if event.get("kind", "") != "route_segment_completed": continue
		var detail: Dictionary = event.get("detail", {})
		var a: String = str(detail.get("from", ""))
		var b: String = str(detail.get("to", ""))
		if b == state.player_district and SandboxRoads.connected(a, b):
			return edge_heading(a, b, 1.0)
	# Before the first trip, park aligned with an authored road adjoining home.
	var links: Array = SandboxRoads.LINKS.get(state.player_district, [])
	if not links.is_empty():
		return edge_heading(str(links[0]), state.player_district, 1.0)
	return 0.0

func restore_taxi_heading(saved: Variant = null) -> void:
	_heading = wrapf(float(saved), -PI, PI) if (saved is float or saved is int) and is_finite(float(saved)) else \
			world_road_heading(world, visual_fraction)
	_heading_initialized = true
	_last_parked_stop = world.player_district if not world.is_travelling() else ""

func saved_taxi_heading() -> float:
	if not _heading_initialized: restore_taxi_heading()
	return wrapf(_heading, -PI, PI)
var _blocks: Array[Dictionary] = []
var _layers: Dictionary = {}

static func project(p: Vector3) -> Vector2:
	return SandboxIsoPresentation.project(p)

func _ready() -> void:
	# Authored street geometry determines every lot. No runtime population here.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7209
	for edge in SandboxCityData.EDGES:
		var ends: PackedStringArray = str(edge).split("|")
		for i in range(2, 12):
			var t: float = float(i) / 13.0
			var a: Vector3 = SandboxRoads.sample_edge(ends[0], ends[1], t)
			if a.y > 20: continue
			var b: Vector3 = SandboxRoads.sample_edge(ends[0], ends[1], minf(t + .01,1))
			var tangent: Vector2 = (project(b)-project(a)).normalized()
			for side in [-1,1]:
				var at: Vector2 = project(a) + tangent.orthogonal()*float(side)*rng.randf_range(45,75)
				var valid: bool = true
				for other in SandboxCityData.EDGES:
					var pair: PackedStringArray = str(other).split("|")
					for j in range(21):
						var road: Vector3=SandboxRoads.sample_edge(pair[0],pair[1],float(j)/20)
						if at.distance_to(project(road)) < 32:
							valid = false
						if road.y>0.0:
							road.y=0.0
							# Reserve actual ground under the deck for supports and
							# the underpass; facade footprints cannot occupy a pier.
							if Rect2(at,Vector2(42,45)).grow(30).has_point(project(road)): valid=false
				for existing in _blocks:
					if at.distance_to(existing["at"]) < 42: valid=false
				if valid:
					_blocks.append({"at":at,"size":Vector2(rng.randf_range(22,42),rng.randf_range(23,45)),
						"region":SandboxRoads.district_for(ends[0]),"style":rng.randi_range(0,3)})

	# Godot retains static CanvasItem drawing commands. Camera movement does
	# not require rebuilding curves, facades and supports every frame.
	for role in ["background","structure","ground","deck","above"]:
		var layer: Node2D=Node2D.new()
		layer.name=role.capitalize();layer.z_index=_layers.size()
		layer.draw.connect(paint.bind(layer,role))
		_layers[role]=layer;add_child(layer)

func _process(delta: float) -> void:
	if world == null: return
	if not _heading_initialized: restore_taxi_heading()
	var taxi: Vector2 = SandboxDirectedLanes.taxi_screen(world,visual_fraction)
	var ahead: Vector2 = taxi
	if world.is_travelling():
		_last_parked_stop = ""
		var elapsed: float = SandboxDirectedLanes.taxi_elapsed_minutes(world,visual_fraction)
		var tangent: Vector2 = SandboxDirectedLanes.route_screen_tangent_at_minutes(
				world.route_nodes,elapsed)
		if tangent.length_squared() > .000001:
			_heading = SandboxVehicleKinematics.turn_heading(_heading,tangent.angle(),delta)
			ahead += tangent.normalized()*65
	elif _last_parked_stop != world.player_district:
		# A just-finished route has no active nodes. Face its last legal edge,
		# not the arbitrary global zero angle used by a newly created renderer.
		restore_taxi_heading()
	var camera: Camera2D = get_parent().get_node("Camera2D")
	var framing: Vector2=Vector2(70 if ui_rtl else -70,-45)
	var target: Vector2=taxi + framing if reduced_motion else taxi + framing + (ahead-taxi)*.5
	camera.position = target if reduced_motion or not _camera_initialized else \
			camera.position.lerp(target,1.0-exp(-8.0*maxf(delta,0.0)))
	_camera_initialized=true
	_zoom = zoom_preference if reduced_motion else lerpf(_zoom, zoom_preference, 1.0-exp(-8.0*maxf(delta,0.0)))
	camera.zoom = Vector2.ONE * _zoom
	_layers["ground"].queue_redraw()
	_layers["above"].queue_redraw()

func _road(canvas: Node2D, a: String, b: String, elevated: bool, pass_index: int=-1) -> void:
	# The first 2:1 street slice has authored two-lane edge/curb geometry.
	# Route length, edge timing and legal graph remain in SandboxRoads.
	if not elevated and (a == "clinic" or b == "clinic"):
		SandboxIsoPresentation.draw_clinic_road(canvas, a, b, pass_index)
		return
	if not elevated and SandboxRoads.edge_key(a,b) == "freight_cross|quay_gate":
		SandboxIsoPresentation.draw_arterial_road(canvas,a,b,pass_index)
		return
	var points: PackedVector2Array = []
	for i in range(49): points.append(project(SandboxRoads.sample_edge(a,b,float(i)/48)))
	if elevated and pass_index in [-1,0]:
		var underside: PackedVector2Array=[]
		for i in range(49):
			var p: Vector3=SandboxRoads.sample_edge(a,b,float(i)/48.0)
			underside.append(points[i]+Vector2(0,SandboxBridgePresentation.thickness(p.y)))
		canvas.draw_polyline(underside,Color("4d605a"),33.0,true)
	if pass_index in [-1,0]: canvas.draw_polyline(points,Color("202e32"),34,true)
	if pass_index in [-1,1]: canvas.draw_polyline(points,Color("8c9d91") if elevated else Color("667773"),28,true)
	if pass_index in [-1,2]: canvas.draw_polyline(points,Color("374b50"),23,true)
	if pass_index not in [-1,3]: return
	for i in range(0,47,3):
		canvas.draw_line(points[i],points[i+1],Color("d2bc7d"),1.1,true)
	if elevated:
		for i in range(4,46,8):
			var normal: Vector2=(points[i+1]-points[i]).normalized().orthogonal()
			canvas.draw_line(points[i]-normal*11.0,points[i]+normal*11.0,Color("637570"),1.0,true)
		for side in [-1,1]:
			var rail: PackedVector2Array = []
			for i in range(49):
				if SandboxRoads.map_position(a).y>0.0 and points[i].distance_to(points[0])<17.0: continue
				if SandboxRoads.map_position(b).y>0.0 and points[i].distance_to(points[48])<17.0: continue
				var normal: Vector2 = (points[mini(i+1,48)]-points[maxi(0,i-1)]).normalized().orthogonal()
				rail.append(points[i]+normal*float(side)*14)
			canvas.draw_polyline(rail,Color("d2ccad"),1.6,true)

func paint(canvas: Node2D, role: String) -> void:
	if world == null: return
	if role=="structure":
		for key in SandboxCityData.EDGES:
			var pair: PackedStringArray=str(key).split("|")
			if SandboxRoads.map_position(pair[0]).y>0 or SandboxRoads.map_position(pair[1]).y>0:
				SandboxBridgePresentation.paint_structure(canvas,pair[0],pair[1])
		return
	if role in ["ground","above"]:
		_draw_people(canvas,role=="above")
		var above: bool=world.player_position(visual_fraction).y>0
		if world.is_travelling():
			above=above or SandboxRoads.map_position(world.route_nodes[world.route_segment]).y>0 or SandboxRoads.map_position(world.route_nodes[world.route_segment+1]).y>0
		if above==(role=="above"): _taxi(canvas)
		return
	if role=="deck":
		# Paint outlines, curbs and surfaces in separate passes so one edge's
		# butt end cannot cover its legal neighbor's asphalt at the ramp join.
		for pass_index in range(4):
			for key in SandboxCityData.EDGES:
				var pair: PackedStringArray=str(key).split("|")
				if SandboxRoads.map_position(pair[0]).y>0 or SandboxRoads.map_position(pair[1]).y>0:
					_road(canvas,pair[0],pair[1],true,pass_index)
			if pass_index==3: continue
			for node in SandboxCityData.NODES:
				var at: Vector3=SandboxRoads.map_position(str(node))
				if at.y<=0.0 or SandboxRoads.LINKS[node].size()!=2: continue
				canvas.draw_circle(project(at),[17.0,14.0,11.5][pass_index],
					[Color("202e32"),Color("8c9d91"),Color("374b50")][pass_index])
		return
	canvas.draw_rect(Rect2(-1500,-1500,6000,6000),Color("263c3e"))
	# The working cargo basin is water, never a driveable surface.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-1000,40),Vector2(-40,40),Vector2(70,300),Vector2(330,510),Vector2(590,730),Vector2(600,990),Vector2(-1000,990)]),Color("162e38"))
	for i in range(30):
		var y: float = 95+float(i)*28
		canvas.draw_line(Vector2(-300,y),Vector2(40+float(i)*12,y),Color("25434a"),1)
	# District ground tint and built landmarks are persistent geography.
	for node in SandboxCityData.NODES:
		var p: Vector2 = project(SandboxRoads.map_position(node))
		var color: Color = SandboxCityData.REGIONS[SandboxRoads.district_for(node)]["color"]
		canvas.draw_circle(p,95,Color(color,.075))
	for block in _blocks:
		var at: Vector2 = block["at"]
		var extent: Vector2 = block["size"]
		var col: Color = SandboxCityData.REGIONS[block["region"]]["color"]
		var lift: float=12 if block["region"]=="outer_margin" else 24 if block["region"]=="civic_core" else 16
		var roof: PackedVector2Array=PackedVector2Array([at+Vector2(-5,-lift),at+Vector2(extent.x-5,-lift-10),at+Vector2(extent.x,extent.y-lift-10),at+Vector2(0,extent.y-lift)])
		canvas.draw_rect(Rect2(at+Vector2(7,9),extent),Color("172e33"))
		canvas.draw_colored_polygon(PackedVector2Array([roof[2],roof[3],at+Vector2(0,extent.y),at+extent-Vector2(0,10)]),col.darkened(.28))
		canvas.draw_colored_polygon(PackedVector2Array([roof[1],roof[2],at+extent-Vector2(0,10),at+Vector2(extent.x-5,-10)]),col.darkened(.45))
		canvas.draw_colored_polygon(roof,col.darkened(.05))
		canvas.draw_line(roof[3],roof[2],col.lightened(.15),1)
		for k in range(3):
			var lamp: Vector2 = at+Vector2(5+float(k)*8,extent.y-3)
			canvas.draw_line(lamp,lamp+Vector2(4,0),Color("efc483") if int(block["style"])%2==0 else Color("8abbb0"),2)
		if block["region"] == "outer_margin":
			canvas.draw_rect(Rect2(at+Vector2(3,4),Vector2(12,8)),Color("62796e"))
		elif block["region"] == "upper_terraces":
			canvas.draw_circle(at+Vector2(10,10),8,Color("658a79"))
	for key in SandboxCityData.EDGES:
		var pair: PackedStringArray = str(key).split("|")
		if SandboxRoads.map_position(pair[0]).y == 0 and SandboxRoads.map_position(pair[1]).y == 0:
			_road(canvas,pair[0],pair[1],false)
	# Patchworks is an inhabited repair court with a shutter, shelter and stall.
	var home: Vector2=project(SandboxRoads.map_position("garage"))+Vector2(38,-32)
	canvas.draw_colored_polygon(PackedVector2Array([home,home+Vector2(48,-12),home+Vector2(58,20),home+Vector2(10,32)]),Color("b78b62"))
	canvas.draw_colored_polygon(PackedVector2Array([home+Vector2(10,32),home+Vector2(58,20),home+Vector2(58,44),home+Vector2(10,56)]),Color("715e4b"))
	for i in range(5): canvas.draw_line(home+Vector2(18,34+i*4),home+Vector2(48,27+i*4),Color("9b9d83"),2)
	canvas.draw_circle(home+Vector2(64,48),5,Color("c6b58d"))
	canvas.draw_line(home+Vector2(-8,53),home+Vector2(8,50),Color("c4b392"),4)
	for stop in SandboxRoads.DISTRICTS:
		var p: Vector2 = project(SandboxRoads.map_position(stop))
		canvas.draw_circle(p+Vector2(24,-20),4,Color("e7bd78"))
		canvas.draw_line(p+Vector2(24,-20),p+Vector2(24,-4),Color("afad94"),2)
		canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-45,-38),SandboxRoads.location_name(stop),HORIZONTAL_ALIGNMENT_CENTER,150,12,Color("f0d7a4"))
	SandboxIsoPresentation.draw_clinic(canvas)
	var shop: Vector2 = project(SandboxRoads.map_position("market"))+Vector2(37,13)
	canvas.draw_rect(Rect2(shop,Vector2(40,24)),Color("668f80"))
	for i in range(5): canvas.draw_rect(Rect2(shop+Vector2(i*8,-2),Vector2(8,6)),Color("deb68a") if i%2==0 else Color("9b735b"))
	canvas.draw_string(ThemeDB.fallback_font,shop+Vector2(-4,38),"LINGUIST",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("efd5a3"))

func _draw_people(canvas: Node2D, elevated: bool) -> void:
	for npc in world.residents:
		if not str(npc.get("taxi_offer","")).is_empty(): continue
		if npc.get("passenger_alight", {}).get("status", "") in ["walking", "offscreen", "arrived"]:
			# The same resident is represented by the local native actor or
			# is inside the clinic; never draw a second static node marker.
			continue
		if (str(npc.get("id",""))==local_active_npc_id or local_active_npc_ids.has(str(npc.get("id","")))) \
				or npc.get("local_pedestrian_trip",{}).get("status","")=="offscreen": continue
		var pos: Vector3 = world.npc_position(npc,visual_fraction)
		if (pos.y>0) != elevated: continue
		var shuttle: Dictionary=SandboxWorldTraffic.shuttle_pose(world,npc,visual_fraction)
		if not shuttle.is_empty():
			# Same resident and world trip, shown as transport rather than a
			# second walking NPC (or an invented municipal driver).
			var here: Vector2=project(shuttle["render_position"])
			_draw_world_shuttle(canvas,here,float(shuttle["render_heading"]))
			continue
		var p: Vector2 = project(pos)+Vector2(15,12)
		canvas.draw_circle(p+Vector2(2,3),4,Color("172a30"))
		canvas.draw_line(p,p-Vector2(0,5),Color("c3b797"),4)
		canvas.draw_circle(p-Vector2(0,6),2.5,Color("a5bbac"))

# A world-owned passenger's independently timed shuttle trip. The car
# silhouette is presentation only; city travel/arrival stays in SandboxWorld.
func _draw_world_shuttle(canvas: Node2D, point: Vector2, heading: float) -> void:
	SandboxIsoPresentation.draw_vehicle(canvas, point, heading, false)


func _taxi(canvas: Node2D) -> void:
	# Render the world-owned taxi on its authored directed lane trajectory,
	# instead of displacing a flat sprite by an arbitrary screen offset.
	# Economic route minutes and collision authority remain with SandboxWorld.
	var taxi: Vector2 = SandboxDirectedLanes.taxi_screen(world,visual_fraction)
	SandboxIsoPresentation.draw_vehicle(canvas, taxi, _heading, true)
