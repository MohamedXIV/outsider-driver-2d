class_name SandboxPlayerGuidance
extends Control

# Strictly read-only Player Mode affordance; World owns every real event.
signal tab_requested(tab_name: String)
var title_label: Label
var detail_label: Label
var action_button: Button
var _target: String=""

var _panel_style: StyleBoxFlat

func _ready() -> void:
	# This is an anchored *overlay*, not a Container-driven dock. A
	# VBoxContainer inside PanelContainer measured narrow wrapped labels at
	# the old expanded height and yielded a huge ghost panel over the city.
	# Explicit bounds keep the UI visually small in either LTR or RTL.
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(282,172)
	size=custom_minimum_size
	_panel_style=StyleBoxFlat.new()
	_panel_style.bg_color=Color(0.09,0.17,0.19,0.95)
	_panel_style.border_color=Color("718b7c")
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(10)
	title_label=Label.new();title_label.name="ObjectiveTitle"
	title_label.position=Vector2(14,12);title_label.size=Vector2(254,27)
	title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size",19)
	title_label.add_theme_color_override("font_color",Color("f3e5c2"))
	add_child(title_label)
	detail_label=Label.new();detail_label.name="ObjectiveDetail"
	detail_label.position=Vector2(14,43);detail_label.size=Vector2(254,67)
	detail_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size",15)
	detail_label.add_theme_color_override("font_color",Color("c1d6c9"))
	add_child(detail_label)
	action_button=Button.new();action_button.name="OpenContext"
	action_button.position=Vector2(14,116);action_button.size=Vector2(254,44)
	action_button.custom_minimum_size.y=44
	action_button.mouse_filter=Control.MOUSE_FILTER_STOP
	action_button.pressed.connect(func(): tab_requested.emit(_target))
	add_child(action_button)

func _draw() -> void:
	if _panel_style!=null: draw_style_box(_panel_style,Rect2(Vector2.ZERO,size))

func present(info: Dictionary, current_tab: String) -> void:
	if title_label==null: return
	_target=str(info.get("tab","requests"))
	title_label.text=str(info.get("title",""))
	detail_label.text=str(info.get("detail",""))
	action_button.text=str(info.get("action",""))
	action_button.visible=_target!=current_tab
	title_label.text_direction=Control.TEXT_DIRECTION_AUTO
	detail_label.text_direction=Control.TEXT_DIRECTION_AUTO

static func _place(stop: String, locale: String) -> String:
	if locale=="ar": return str(SandboxLanguagePresentation.AR_DISTRICTS.get(
			stop,SandboxRoads.location_name(stop)))
	return SandboxRoads.location_name(stop)

static func describe(world: SandboxWorld, locale: String,
		selected_id: String, in_conversation: bool) -> Dictionary:
	var ar: bool=locale=="ar"
	if world.rider_initiative.get("status","")=="pending":
		return {"title":"الراكب يتحدث" if ar else "Passenger speaking",
			"detail":"الرد من الشارع" if ar
				else "Reply in Street",
			"tab":"requests","action":"افتح الشارع" if ar else "Open Street"}
	if in_conversation:
		return {"title":"حوار مع الراكب" if ar else "Passenger conversation",
			"detail":"تابع الحوار في الشارع، والمدينة مستمرة في الحركة." if ar
				else "Continue the conversation on Street while the city moves.",
			"tab":"requests","action":"تابع الحوار" if ar else "Continue dialogue"}
	if world.is_travelling():
		var fare: Dictionary=world.offer_by_id(world.active_offer_id)
		if not fare.is_empty():
			return {"title":("في الطريق إلى " if ar else "Driving to ")+
					_place(str(fare["destination"]),locale),
				"detail":"راجع الراكب والرحلة من الشارع." if ar
					else "Keep an eye on your passenger; the route continues.",
				"tab":"requests","action":"الراكب" if ar else "Passenger"}
		return {"title":"أنت على الطريق" if ar else "On the road",
			"detail":"افتح الخريطة لمراجعة وجهتك والطريق." if ar
				else "Open Map to inspect your destination and route.",
			"tab":"map","action":"الخريطة" if ar else "Open Map"}
	var selected: Dictionary=world.offer_by_id(selected_id)
	if not selected.is_empty() and selected.get("origin","")==world.player_district:
		return {"title":"راكب محدد" if ar else "Passenger selected",
			"detail":"افتح الشارع وتحدث معه قبل قرار التوصيلة." if ar
				else "Open Street to talk before deciding about this fare.",
			"tab":"requests","action":"تحدث" if ar else "Talk"}
	if world.starter_device.is_empty():
		return {"title":"تجهيزات البداية" if ar else "Starter equipment",
			"detail":"ملاحة، اللغة المحلية أو الراديو" if ar
				else "GPS, Local module or radio",
			"tab":"gear","action":"افتح الأجهزة" if ar else "Choose starter"}
	for offer in world.open_offers():
		if offer.get("origin","")==world.player_district:
			return {"title":"طلبات متاحة" if ar else "Available fares",
				"detail":"اختر طلبًا في الشارع لبدء الحديث." if ar
					else "Choose a Street request to start a conversation.",
				"tab":"requests","action":"افتح الطلبات" if ar else "See requests"}
	return {"title":"لا توجد طلبات هنا" if ar else "No nearby fares",
		"detail":"انتظر قليلًا أو افتح الخريطة للبحث عن موقف آخر." if ar
			else "Wait a little, or use Map to find another taxi stop.",
		"tab":"requests","action":"افتح الشارع" if ar else "Open Street"}
