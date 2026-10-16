class_name SandboxCityView
extends Node2D

signal waypoint_clicked(district: String)
const SCALE: float = 0.12
var world: SandboxWorld
var preview_nodes: Array[String] = []
var visual_fraction: float = 0.0
var reduced_motion: bool = false
var _heading: float = 0.0
var _blocks: Array[Dictionary] = []

static func project(p: Vector3) -> Vector2:
	return Vector2((p.x-p.z*.55)*SCALE, (p.x*.32+p.z*.7)*SCALE-p.y*.24)

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
						if at.distance_to(project(SandboxRoads.sample_edge(pair[0],pair[1],float(j)/20))) < 32:
							valid = false
				for existing in _blocks:
					if at.distance_to(existing["at"]) < 42: valid=false
				if valid:
					_blocks.append({"at":at,"size":Vector2(rng.randf_range(22,42),rng.randf_range(23,45)),
						"region":SandboxRoads.district_for(ends[0]),"style":rng.randi_range(0,3)})

func _process(delta: float) -> void:
	if world == null: return
	var taxi: Vector2 = project(world.player_position(visual_fraction))
	var ahead: Vector2 = taxi
	if world.is_travelling():
		var a: String = world.route_nodes[world.route_segment]
		var b: String = world.route_nodes[world.route_segment+1]
		var t: float = (float(world.route_edge_elapsed)+visual_fraction)/float(SandboxRoads.edge_minutes(a,b))
		var tangent: Vector2 = project(SandboxRoads.sample_edge(a,b,minf(.999,t+.003)))-project(SandboxRoads.sample_edge(a,b,maxf(0,t-.003)))
		if tangent.length() > .001:
			_heading = lerp_angle(_heading,tangent.angle(), minf(1,delta*7))
			ahead += tangent.normalized()*65
	var camera: Camera2D = get_parent().get_node("Camera2D")
	camera.position = taxi + Vector2(80,-45) if reduced_motion else taxi + Vector2(80,-45) + (ahead-taxi)*.5
	camera.zoom = Vector2(2.0,2.0)
	queue_redraw()

func _road(a: String, b: String, elevated: bool) -> void:
	var points: PackedVector2Array = []
	for i in range(49): points.append(project(SandboxRoads.sample_edge(a,b,float(i)/48)))
	if elevated:
		var shadows: PackedVector2Array = []
		for i in range(49):
			var ground: Vector3 = SandboxRoads.sample_edge(a,b,float(i)/48)
			ground.y=0
			shadows.append(project(ground)+Vector2(8,10))
		draw_polyline(shadows,Color(0.025,0.035,0.04,.65),38,true)
		for i in range(5,45,7):
			var p: Vector3 = SandboxRoads.sample_edge(a,b,float(i)/48)
			var ground: Vector3 = p; ground.y=0
			draw_line(project(ground)+Vector2(13,4),project(p)+Vector2(13,0),Color("6d7772"),9,true)
			draw_circle(project(ground)+Vector2(13,4),7,Color("435452"))
	draw_polyline(points,Color("202e32"),34,true)
	draw_polyline(points,Color("8c9d91") if elevated else Color("667773"),28,true)
	draw_polyline(points,Color("374b50"),23,true)
	for i in range(0,47,3):
		draw_line(points[i],points[i+1],Color("d2bc7d"),1.1,true)
	if elevated:
		for side in [-1,1]:
			var rail: PackedVector2Array = []
			for i in range(48):
				var normal: Vector2 = (points[i+1]-points[i]).normalized().orthogonal()
				rail.append(points[i]+normal*float(side)*14)
			draw_polyline(rail,Color("d2ccad"),1.6,true)

func _draw() -> void:
	if world == null: return
	draw_rect(Rect2(-1500,-1500,6000,6000),Color("263c3e"))
	# The working cargo basin is water, never a driveable surface.
	draw_colored_polygon(PackedVector2Array([Vector2(-1000,40),Vector2(-40,40),Vector2(70,300),Vector2(330,510),Vector2(590,730),Vector2(600,990),Vector2(-1000,990)]),Color("162e38"))
	for i in range(30):
		var y: float = 95+float(i)*28
		draw_line(Vector2(-300,y),Vector2(40+float(i)*12,y),Color("25434a"),1)
	# District ground tint and built landmarks are persistent geography.
	for node in SandboxCityData.NODES:
		var p: Vector2 = project(SandboxRoads.map_position(node))
		var color: Color = SandboxCityData.REGIONS[SandboxRoads.district_for(node)]["color"]
		draw_circle(p,95,Color(color,.075))
	for block in _blocks:
		var at: Vector2 = block["at"]
		var extent: Vector2 = block["size"]
		var col: Color = SandboxCityData.REGIONS[block["region"]]["color"]
		var lift: float=12 if block["region"]=="outer_margin" else 24 if block["region"]=="civic_core" else 16
		var roof: PackedVector2Array=PackedVector2Array([at+Vector2(-5,-lift),at+Vector2(extent.x-5,-lift-10),at+Vector2(extent.x,extent.y-lift-10),at+Vector2(0,extent.y-lift)])
		draw_rect(Rect2(at+Vector2(7,9),extent),Color("172e33"))
		draw_colored_polygon(PackedVector2Array([roof[2],roof[3],at+Vector2(0,extent.y),at+extent-Vector2(0,10)]),col.darkened(.28))
		draw_colored_polygon(PackedVector2Array([roof[1],roof[2],at+extent-Vector2(0,10),at+Vector2(extent.x-5,-10)]),col.darkened(.45))
		draw_colored_polygon(roof,col.darkened(.05))
		draw_line(roof[3],roof[2],col.lightened(.15),1)
		for k in range(3):
			var lamp: Vector2 = at+Vector2(5+float(k)*8,extent.y-3)
			draw_line(lamp,lamp+Vector2(4,0),Color("efc483") if int(block["style"])%2==0 else Color("8abbb0"),2)
		if block["region"] == "outer_margin":
			draw_rect(Rect2(at+Vector2(3,4),Vector2(12,8)),Color("62796e"))
		elif block["region"] == "upper_terraces":
			draw_circle(at+Vector2(10,10),8,Color("658a79"))
	for key in SandboxCityData.EDGES:
		var pair: PackedStringArray = str(key).split("|")
		if SandboxRoads.map_position(pair[0]).y == 0 and SandboxRoads.map_position(pair[1]).y == 0:
			_road(pair[0],pair[1],false)
	_draw_people(false)

	for key in SandboxCityData.EDGES:
		var pair: PackedStringArray = str(key).split("|")
		if SandboxRoads.map_position(pair[0]).y > 0 or SandboxRoads.map_position(pair[1]).y > 0:
			_road(pair[0],pair[1],true)
	_draw_people(true)
	_taxi()
	# Only a genuinely higher, constant-height deck can occlude a vehicle.
	# Ramps never cover the taxi travelling on their own rising surface.
	for key in SandboxCityData.EDGES:
		var pair: PackedStringArray=str(key).split("|")
		var a: Vector3=SandboxRoads.map_position(pair[0])
		var b: Vector3=SandboxRoads.map_position(pair[1])
		if a.y==b.y and a.y>world.player_position(visual_fraction).y+30: _road(pair[0],pair[1],true)
	# Patchworks is an inhabited repair court with a shutter, shelter and stall.
	var home: Vector2=project(SandboxRoads.map_position("garage"))+Vector2(38,-32)
	draw_colored_polygon(PackedVector2Array([home,home+Vector2(48,-12),home+Vector2(58,20),home+Vector2(10,32)]),Color("b78b62"))
	draw_colored_polygon(PackedVector2Array([home+Vector2(10,32),home+Vector2(58,20),home+Vector2(58,44),home+Vector2(10,56)]),Color("715e4b"))
	for i in range(5): draw_line(home+Vector2(18,34+i*4),home+Vector2(48,27+i*4),Color("9b9d83"),2)
	draw_circle(home+Vector2(64,48),5,Color("c6b58d"))
	draw_line(home+Vector2(-8,53),home+Vector2(8,50),Color("c4b392"),4)
	for stop in SandboxRoads.DISTRICTS:
		var p: Vector2 = project(SandboxRoads.map_position(stop))
		draw_circle(p+Vector2(24,-20),4,Color("e7bd78"))
		draw_line(p+Vector2(24,-20),p+Vector2(24,-4),Color("afad94"),2)
		draw_string(ThemeDB.fallback_font,p+Vector2(-45,-38),SandboxRoads.location_name(stop),HORIZONTAL_ALIGNMENT_CENTER,150,12,Color("f0d7a4"))
	var shop: Vector2 = project(SandboxRoads.map_position("market"))+Vector2(37,13)
	draw_rect(Rect2(shop,Vector2(40,24)),Color("668f80"))
	for i in range(5): draw_rect(Rect2(shop+Vector2(i*8,-2),Vector2(8,6)),Color("deb68a") if i%2==0 else Color("9b735b"))
	draw_string(ThemeDB.fallback_font,shop+Vector2(-4,38),"LINGUIST",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("efd5a3"))

func _draw_people(elevated: bool) -> void:
	for npc in world.residents:
		if not str(npc.get("taxi_offer","")).is_empty(): continue
		var pos: Vector3 = world.npc_position(npc,visual_fraction)
		if (pos.y>=60) != elevated: continue
		var p: Vector2 = project(pos)+Vector2(15,12)
		draw_circle(p+Vector2(2,3),4,Color("172a30"))
		draw_line(p,p-Vector2(0,5),Color("c3b797"),4)
		draw_circle(p-Vector2(0,6),2.5,Color("a5bbac"))

func _taxi() -> void:
	var taxi: Vector2 = project(world.player_position(visual_fraction))
	draw_set_transform(taxi,_heading)
	draw_rect(Rect2(-11,-5,25,14),Color(0,0,0,.35))
	for x in [-7,7]:
		for y in [-7,5]: draw_rect(Rect2(x,y,6,3),Color("172a30"))
	draw_style_box(_car_style(),Rect2(-12,-6,26,12))
	draw_rect(Rect2(-4,-5,10,10),Color("45676c"))
	draw_line(Vector2(6,-4),Vector2(6,4),Color("b8d8c9"),2)
	draw_rect(Rect2(12,-5,2,3),Color("fff0b5"))
	draw_rect(Rect2(12,2,2,3),Color("fff0b5"))
	draw_rect(Rect2(-2,-2,5,4),Color("e9cd8e"))
	draw_set_transform(Vector2.ZERO)

func _car_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color=Color("d69b55"); style.set_corner_radius_all(4)
	style.border_color=Color("f2ca86"); style.set_border_width_all(1)
	return style
