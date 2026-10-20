class_name SandboxCabGearPlate
extends Control

# Small non-interactive diegetic instrument plate. Names and status come
# from actual equipment state, not inferred capabilities or hidden knowledge.
var kind: String=""
var heading: Label
var status: Label
var rtl: bool=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=74.0
	heading=Label.new()
	heading.name="DeviceName"
	heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	heading.add_theme_font_size_override("font_size",16)
	heading.add_theme_color_override("font_color",Color("f1ddaf"))
	add_child(heading)
	status=Label.new()
	status.name="DeviceStatus"
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	status.add_theme_font_size_override("font_size",14)
	status.add_theme_color_override("font_color",Color("c0d0c5"))
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	resized.connect(_arrange)
	_arrange()

func present(device_kind: String, device_name: String, device_status: String,
		is_arabic: bool) -> void:
	kind=device_kind
	rtl=is_arabic
	if heading==null: return
	heading.text=device_name
	status.text=device_status
	_arrange()

func _arrange() -> void:
	if heading==null: return
	var x: float=14.0 if rtl else 72.0
	var text_width: float=maxf(110.0,size.x-88.0)
	heading.position=Vector2(x,9.0)
	heading.size=Vector2(text_width,23.0)
	status.position=Vector2(x,33.0)
	status.size=Vector2(text_width,35.0)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
	queue_redraw()

func _draw() -> void:
	if size.x<=0.0: return
	var bg: StyleBoxFlat=StyleBoxFlat.new()
	bg.bg_color=Color("223a3a")
	bg.border_color=Color("637b72")
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	draw_style_box(bg,Rect2(Vector2.ZERO,size))
	var centre: Vector2=Vector2(size.x-37.0 if rtl else 37.0,37.0)
	var brass: Color=Color("c8af78")
	var surface: Color=Color("182a2d")
	draw_circle(centre,26.0,surface)
	draw_arc(centre,24.0,0.0,TAU,32,Color("677f76"),1.5,true)
	match kind:
		"gps":
			# Road split and a destination marker: route hardware, not magic GPS.
			draw_line(centre+Vector2(-11,14),centre+Vector2(-1,-13),brass,2.5,true)
			draw_line(centre+Vector2(-1,-13),centre+Vector2(12,-4),brass,2.5,true)
			draw_circle(centre+Vector2(12,-4),4.0,brass)
		"radio":
			# Tuning bars and a physical dial; no invented station information.
			for i in range(3):
				var px: float=-11.0+float(i)*10.0
				draw_line(centre+Vector2(px,6),centre+Vector2(px,-11+float(i)*3),brass,2.5,true)
			draw_circle(centre+Vector2(0,15),3.0,brass)
		"ar":
			# Eyewear silhouette.
			draw_arc(centre+Vector2(-9,1),7.0,0.0,TAU,20,brass,2.0,true)
			draw_arc(centre+Vector2(9,1),7.0,0.0,TAU,20,brass,2.0,true)
			draw_line(centre+Vector2(-2,0),centre+Vector2(2,0),brass,2.0,true)
		_:
			# Parallel language plates, not a readable or leaked alien glyph.
			for row in range(3):
				var y: float=-10.0+float(row)*10.0
				draw_line(centre+Vector2(-12,y),centre+Vector2(5,y),brass,2.0,true)
				draw_circle(centre+Vector2(11,y),2.0,brass)
	var screw: Color=Color("978c70")
	draw_circle(Vector2(7,7),1.8,screw)
	draw_circle(Vector2(size.x-7,size.y-7),1.8,screw)
