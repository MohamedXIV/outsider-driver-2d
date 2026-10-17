class_name SandboxIsoPresentation
extends RefCounted

# Constant axonometric view shared by road, vehicle and 3D-looking facades.
# Camera2D still owns framing/zoom. There is no perspective foreshortening.
# Horizontal world X and Z produce the two symmetric 2:1 diamond axes.
const WORLD_TO_SCREEN: float = 0.105
const HEIGHT_TO_SCREEN: float = 0.36
const CLINIC_ROAD_OUTER: float = 43.0
const CLINIC_ASPHALT: float = 29.0
const LANE_SHIFT: float = 7.2
const CAR_ELEVATION: float = 7.0

static func project(point: Vector3) -> Vector2:
	return Vector2((point.x-point.z)*WORLD_TO_SCREEN,
			(point.x+point.z)*WORLD_TO_SCREEN*0.5-point.y*HEIGHT_TO_SCREEN)

static func lane_offset(heading: float) -> Vector2:
	# One signed visual lane: following a reversed route flips this vector.
	return Vector2.RIGHT.rotated(heading).orthogonal()*LANE_SHIFT

static func road_points(a: String, b: String) -> PackedVector2Array:
	var points: PackedVector2Array=[]
	for i in range(49):
		points.append(project(SandboxRoads.sample_edge(a,b,float(i)/48.0)))
	return points

static func draw_clinic_road(canvas: Node2D, a: String, b: String, pass_index: int) -> void:
	var centre: PackedVector2Array=road_points(a,b)
	match pass_index:
		-1:
			for i in range(4): draw_clinic_road(canvas,a,b,i)
		0:
			canvas.draw_polyline(centre, Color("1a343a"),CLINIC_ROAD_OUTER,true)
		1:
			# Sidewalk shoulders on *both* sides; future path ownership must
			# use authored world geometry, not these pixels as navigation.
			canvas.draw_polyline(centre, Color("8d9d8c"),40.0,true)
		2:
			canvas.draw_polyline(centre, Color("36484c"),CLINIC_ASPHALT,true)
		3:
			var left: PackedVector2Array=[]
			var right: PackedVector2Array=[]
			for i in range(49):
				var tangent: Vector2=(centre[mini(i+1,48)]-centre[maxi(0,i-1)]).normalized()
				if tangent.length_squared()<0.5: continue
				var normal: Vector2=tangent.orthogonal()
				left.append(centre[i]-normal*15.0)
				right.append(centre[i]+normal*15.0)
			canvas.draw_polyline(left,Color("c5c5a6"),1.6,true)
			canvas.draw_polyline(right,Color("c5c5a6"),1.6,true)
			for i in range(3,45,5):
				canvas.draw_line(centre[i],centre[i+2],Color("cfbd80"),1.25,true)

static func vehicle_quad(anchor: Vector2, heading: float, height: float = 0.0) -> PackedVector2Array:
	var facing: Vector2=Vector2.RIGHT.rotated(heading)
	var side: Vector2=facing.orthogonal()
	var lift: Vector2=Vector2(0.0,-height)
	return PackedVector2Array([
		anchor+facing*-12.0+side*-6.5+lift,
		anchor+facing*13.0+side*-6.5+lift,
		anchor+facing*13.0+side*6.5+lift,
		anchor+facing*-12.0+side*6.5+lift])

static func draw_vehicle(canvas: Node2D, at: Vector2, heading: float, taxi: bool) -> void:
	var base: PackedVector2Array=vehicle_quad(at,heading)
	var roof: PackedVector2Array=vehicle_quad(at,heading,CAR_ELEVATION)
	var paint: Color=Color("da9e5e") if taxi else Color("78a8a2")
	var trim: Color=Color("f1d7a4") if taxi else Color("bad8d2")
	canvas.draw_colored_polygon(PackedVector2Array([
		base[0]+Vector2(3,5),base[1]+Vector2(3,5),
		base[2]+Vector2(3,5),base[3]+Vector2(3,5)]),Color(0.02,0.07,0.08,0.42))
	canvas.draw_colored_polygon(base,paint.darkened(.51))
	# Four vertical side faces make the car visibly raised over the road.
	# Far faces first; foreground edges are drawn after roof.
	for side in [0,3,1,2]:
		var next: int=(side+1)%4
		canvas.draw_colored_polygon(PackedVector2Array([
			base[side],base[next],roof[next],roof[side]]),
			paint.darkened(.30 if side in [0,1] else .47))
	canvas.draw_colored_polygon(roof,paint.lightened(.14))
	canvas.draw_polyline(PackedVector2Array([roof[0],roof[1],roof[2],roof[3],roof[0]]),trim,1.2,true)
	var front: Vector2=(roof[1]+roof[2])*0.5
	var rear: Vector2=(roof[0]+roof[3])*0.5
	var right: Vector2=(roof[2]+roof[3])*0.5
	var left: Vector2=(roof[0]+roof[1])*0.5
	var middle: Vector2=(front+rear)*0.5
	var windshield: PackedVector2Array=PackedVector2Array([
		middle.lerp(left,.42),middle.lerp(front,.56),
		middle.lerp(right,.42),middle.lerp(rear,.24)])
	canvas.draw_colored_polygon(windshield,Color("315b62") if taxi else Color("34555c"))
	canvas.draw_line(front+Vector2(0,-1),front+Vector2(0,2),Color("ffe0a0"),2.7,true)
	if taxi: canvas.draw_circle(middle+Vector2(0,-2),2.7,Color("f5d999"))

static func clinic_doorway() -> Vector2:
	return project(SandboxRoads.map_position("clinic"))+Vector2(53,-55)

static func clinic_footprint() -> PackedVector2Array:
	var door: Vector2=clinic_doorway()
	return PackedVector2Array([
		door+Vector2(-32,-18),door+Vector2(6,-37),
		door+Vector2(58,-11),door+Vector2(20,8)])

static func draw_clinic(canvas: Node2D) -> void:
	var base: PackedVector2Array=clinic_footprint()
	var rise: Vector2=Vector2(0,-41)
	var roof: PackedVector2Array=[]
	for p in base: roof.append(p+rise)
	canvas.draw_colored_polygon(PackedVector2Array([
		base[0]+Vector2(8,12),base[1]+Vector2(8,12),
		base[2]+Vector2(8,12),base[3]+Vector2(8,12)]),Color(0.03,0.09,0.1,.45))
	canvas.draw_colored_polygon(PackedVector2Array([base[3],base[2],roof[2],roof[3]]),Color("496f75"))
	canvas.draw_colored_polygon(PackedVector2Array([base[2],base[1],roof[1],roof[2]]),Color("294e57"))
	canvas.draw_colored_polygon(PackedVector2Array([base[0],base[3],roof[3],roof[0]]),Color("3e626b"))
	canvas.draw_colored_polygon(roof,Color("8ba6a3"))
	canvas.draw_polyline(PackedVector2Array([roof[0],roof[1],roof[2],roof[3],roof[0]]),Color("aec7bc"),1.2,true)
	var entrance: Vector2=clinic_doorway()
	canvas.draw_line(entrance+Vector2(-6,0),entrance+Vector2(-6,-17),Color("192f36"),8.0,true)
	canvas.draw_circle(entrance+Vector2(-6,-19),2.3,Color("f7cd88"))
	canvas.draw_string(ThemeDB.fallback_font,roof[0]+Vector2(-7,-12),"CLINIC",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fae0b1"))
