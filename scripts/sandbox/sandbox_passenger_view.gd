class_name SandboxPassengerView
extends Control
var npc: Dictionary = {}
var reduced_motion: bool = false
var _time: float = 0
func _process(delta: float) -> void:
	_time+=delta
	queue_redraw()
func _draw() -> void:
	if npc.is_empty(): return
	var center: Vector2=size*Vector2(.5,.53)
	var breath: float=0 if reduced_motion else sin(_time*1.4)*1.2
	center.y+=breath
	draw_style_box(_seat(),Rect2(Vector2(8,12),size-Vector2(16,12)))
	var species: String=str(npc.get("species","kind:a"))
	var skin: Color={"kind:a":Color("bba177"),"kind:b":Color("99bbaa"),"kind:c":Color("b29eb0"),"kind:d":Color("b5b779")}.get(species,Color("99bbaa"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(-58,70),center+Vector2(-45,24),center+Vector2(-23,15),center+Vector2(22,15),center+Vector2(45,24),center+Vector2(58,70)]),Color("5e7e7b"))
	draw_circle(center-Vector2(0,12),32,skin)
	if species=="kind:c" or species=="kind:d":
		draw_line(center+Vector2(-20,-34),center+Vector2(-35,-58),skin,8,true)
		draw_line(center+Vector2(20,-34),center+Vector2(35,-58),skin,8,true)
	else:
		draw_circle(center+Vector2(-30,-15),9,skin.darkened(.1))
		draw_circle(center+Vector2(30,-15),9,skin.darkened(.1))
	var blink: bool=not reduced_motion and fmod(_time,5.2)>.0 and fmod(_time,5.2)<.16
	for x in [-13,13]:
		if blink: draw_line(center+Vector2(x-5,-17),center+Vector2(x+5,-17),Color("273c40"),2)
		else:
			draw_circle(center+Vector2(x,-17),6,Color("263d41"))
			draw_circle(center+Vector2(x+1,-19),2,Color("dfdca5"))
	draw_arc(center+Vector2(0,-8),12,.3,PI-.3,12,skin.darkened(.4),2,true)
	draw_line(center+Vector2(-8,22),center+Vector2(-8,60),Color("d5b17b"),3)
	draw_circle(center+Vector2(14,35),5,Color("c7a272"))
func _seat() -> StyleBoxFlat:
	var s: StyleBoxFlat=StyleBoxFlat.new(); s.bg_color=Color("263b40"); s.set_corner_radius_all(24)
	s.border_color=Color("526c68");s.set_border_width_all(2)
	return s
