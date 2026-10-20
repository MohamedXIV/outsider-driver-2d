class_name SandboxMeetingStage
extends Control

# Deliberately bounded 2D off-duty spot. Not another world simulation.
# The two figures are visible ONLY after the world verifies co-presence.
var venue: String = ""
var companion: String = ""
# Player mode uses the existing kiosk vignette without debug ID labels.
# Companion skin comes from the actual World resident's species.
var companion_species: String = ""
var show_labels: bool = true


func _draw() -> void:
	var w: float = size.x
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, 110)), Color("172c37"))
	draw_rect(Rect2(Vector2(0, 73), Vector2(w, 37)), Color("334b4c"))
	draw_line(Vector2(0, 73), Vector2(w, 73), Color("d0ac70"), 2)
	# A tangible neighborhood kiosk, bench and overhead lantern.
	draw_rect(Rect2(Vector2(32, 28), Vector2(130, 48)), Color("48616a"))
	draw_rect(Rect2(Vector2(20, 17), Vector2(154, 12)), Color("b88859"))
	draw_rect(Rect2(Vector2(28, 78), Vector2(158, 7)), Color("94765b"))
	draw_circle(Vector2(101, 20), 8, Color("edc57b"))
	draw_rect(Rect2(Vector2(w * 0.58, 63), Vector2(86, 12)), Color("ac9367"))
	draw_rect(Rect2(Vector2(w * 0.59, 75), Vector2(8, 27)), Color("657880"))
	draw_rect(Rect2(Vector2(w * 0.75, 75), Vector2(8, 27)), Color("657880"))
	# Player and actual NPC occupy the spot together, not a toast notification.
	draw_circle(Vector2(w * 0.63, 40), 12, Color("e9bd7f"))
	draw_rect(Rect2(Vector2(w * 0.63 - 13, 51), Vector2(26, 33)), Color("80a5a2"))
	var companion_skin: Color={
		"kind:a":Color("bba177"),"kind:b":Color("99bbaa"),
		"kind:c":Color("b29eb0"),"kind:d":Color("b5b779")
	}.get(companion_species,Color("a9c6b2"))
	draw_circle(Vector2(w * 0.81, 40), 12, companion_skin)
	if companion_species in ["kind:c","kind:d"]:
		draw_line(Vector2(w*0.81-7,30),Vector2(w*0.81-15,17),companion_skin,3,true)
		draw_line(Vector2(w*0.81+7,30),Vector2(w*0.81+15,17),companion_skin,3,true)
	draw_rect(Rect2(Vector2(w * 0.81 - 13, 51), Vector2(26, 33)), Color("b7a0c5"))
	if show_labels:
		draw_string(ThemeDB.fallback_font, Vector2(196, 17), venue.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f6e4c9"))
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.56, 103), "YOU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1ce"))
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.78, 103), companion,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1ce"))
