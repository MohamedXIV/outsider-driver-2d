class_name SandboxPlayerGuidance
extends PanelContainer

# Strictly read-only Player Mode affordance; World owns every real event.
signal tab_requested(tab_name: String)
var title_label: Label
var detail_label: Label
var action_button: Button
var _target: String=""

func _ready() -> void:
	# Never steal canvas wheel/mouse hover when the card covers part of the
	# scenery; only its explicit 44px action owns pointer input.
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var panel: StyleBoxFlat=StyleBoxFlat.new()
	panel.bg_color=Color(0.09,0.17,0.19,0.95)
	panel.border_color=Color("718b7c")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(10)
	panel.content_margin_left=14;panel.content_margin_right=14
	panel.content_margin_top=12;panel.content_margin_bottom=12
	add_theme_stylebox_override("panel",panel)
	var content: VBoxContainer=VBoxContainer.new()
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation",8)
	add_child(content)
	title_label=Label.new();title_label.name="ObjectiveTitle"
	title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size",19)
	title_label.add_theme_color_override("font_color",Color("f3e5c2"))
	content.add_child(title_label)
	detail_label=Label.new();detail_label.name="ObjectiveDetail"
	detail_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size",15)
	detail_label.add_theme_color_override("font_color",Color("c1d6c9"))
	content.add_child(detail_label)
	action_button=Button.new();action_button.name="OpenContext"
	action_button.mouse_filter=Control.MOUSE_FILTER_STOP
	action_button.custom_minimum_size.y=44
	action_button.pressed.connect(func(): tab_requested.emit(_target))
	content.add_child(action_button)

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
			"detail":"لدى الراكب سؤال. افتح الشارع لتقرر هل ترد." if ar
				else "Your passenger has a question. Open Street to choose a response.",
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
		return {"title":"بداية ورديتك" if ar else "Your first shift",
			"detail":"اختر إضافة البداية المجانية من الأجهزة، أو ابحث عن راكب." if ar
				else "Choose your free starter in Gear, or find a passenger on Street.",
			"tab":"gear","action":"افتح الأجهزة" if ar else "Choose starter"}
	for offer in world.open_offers():
		if offer.get("origin","")==world.player_district:
			return {"title":"ركاب قريبون" if ar else "Passengers nearby",
				"detail":"اختر طلبًا في الشارع لبدء الحديث." if ar
					else "Choose a Street request to start a conversation.",
				"tab":"requests","action":"افتح الطلبات" if ar else "See requests"}
	return {"title":"الشارع هادئ" if ar else "A quiet street",
		"detail":"انتظر قليلًا أو افتح الخريطة للبحث عن موقف آخر." if ar
			else "Wait a little, or use Map to find another taxi stop.",
		"tab":"requests","action":"افتح الشارع" if ar else "Open Street"}
