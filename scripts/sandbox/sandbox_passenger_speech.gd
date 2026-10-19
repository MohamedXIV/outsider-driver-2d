class_name SandboxPassengerSpeech
extends Control

# Presentation-only. The caller supplies the World-resolved passenger and
# the exact current Ink or rider-initiative line (never an invented translation).
var portrait: SandboxPassengerView
var speaker_label: Label
var speech_label: Label
var _backdrop: StyleBoxFlat
var _rtl: bool=false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_backdrop=StyleBoxFlat.new()
	_backdrop.bg_color=Color("182d31")
	_backdrop.border_color=Color("7c8e7e")
	_backdrop.set_border_width_all(1)
	_backdrop.set_corner_radius_all(10)
	portrait=SandboxPassengerView.new()
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	speaker_label=Label.new()
	speaker_label.name="Speaker"
	speaker_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	speaker_label.add_theme_font_size_override("font_size",16)
	speaker_label.add_theme_color_override("font_color",Color("e9d3a8"))
	add_child(speaker_label)
	speech_label=Label.new()
	speech_label.name="Speech"
	speech_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	speech_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	speech_label.add_theme_font_size_override("font_size",18)
	add_child(speech_label)
	resized.connect(_arrange)
	_arrange()

func _draw() -> void:
	if _backdrop!=null: draw_style_box(_backdrop,Rect2(Vector2.ZERO,size))

func _arrange() -> void:
	if portrait==null: return
	var compact: bool=size.x<380.0
	var avatar_width: float=124.0 if compact else 166.0
	var margin: float=10.0 if compact else 14.0
	var text_x: float=avatar_width+margin*2.0 if _rtl else margin
	var text_width: float=maxf(84.0,size.x-avatar_width-margin*3.0)
	portrait.position=Vector2(margin if _rtl else size.x-avatar_width-margin,8.0)
	portrait.size=Vector2(avatar_width,maxf(114.0,size.y-16.0))
	speaker_label.position=Vector2(text_x,10.0)
	speaker_label.size=Vector2(text_width,25.0)
	speech_label.position=Vector2(text_x,38.0)
	speech_label.size=Vector2(text_width,maxf(68.0,size.y-45.0))
	queue_redraw()

func present(npc: Dictionary, line: String, locale: String,
		native_font_path: String, reduced_motion: bool) -> void:
	if portrait==null: return
	_rtl=locale=="ar"
	portrait.npc=npc
	portrait.reduced_motion=reduced_motion
	speaker_label.text="الراكب" if _rtl else "Passenger"
	speech_label.text=line
	speech_label.text_direction=Control.TEXT_DIRECTION_LTR if not native_font_path.is_empty() else (
		Control.TEXT_DIRECTION_RTL if _rtl else Control.TEXT_DIRECTION_AUTO)
	if native_font_path.is_empty(): speech_label.remove_theme_font_override("font")
	else: speech_label.add_theme_font_override("font",load(native_font_path))
	_arrange()
