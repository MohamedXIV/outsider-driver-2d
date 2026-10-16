class_name SandboxPlayerUI
extends CanvasLayer

# Presentation adapter only: all actions are delegated to the existing controller.
var controller: Node
var debug_mode: bool = false
var tab: String = "requests"
var root: Control
var _header: Label
var _hint: Label
var _body: VBoxContainer
var _panel: PanelContainer
var _scroll: ScrollContainer
var _portrait: SandboxPassengerView
var _portrait_title: Label
var _tabs: HBoxContainer
var _mode: Button
var _actions: Dictionary = {}
var _planned_stops: Array[String] = []
var _planned_via: String = ""
var _map_selected: String = "market"
var _last_signature: String = ""
var _action_serial: int = 0
var _arabic_font: Font

func bind(host: Node) -> void:
	controller=host
	_arabic_font=load(controller.ARABIC_FONT).duplicate()
	_arabic_font.fallbacks=[ThemeDB.fallback_font]
	layer=20
	root=Control.new();root.name="Root";root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme: Theme=Theme.new()
	theme.default_font_size=17
	for type in ["Button","OptionButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style: StyleBoxFlat=StyleBoxFlat.new()
			style.bg_color=Color("293f43") if state=="normal" else Color("4f6865") if state=="hover" else Color("1a2d33")
			style.border_color=Color("779185") if state=="focus" else Color("536c65")
			style.set_border_width_all(1);style.set_corner_radius_all(7)
			style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8
			theme.set_stylebox(state,type,style)
		theme.set_color("font_color",type,Color("eee4c9"))
		theme.set_color("font_disabled_color",type,Color("7d8f89"))
	var panel_style: StyleBoxFlat=StyleBoxFlat.new()
	panel_style.bg_color=Color(.065,.12,.14,.96);panel_style.border_color=Color("637d73");panel_style.set_border_width_all(1);panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left=18;panel_style.content_margin_right=18;panel_style.content_margin_top=14;panel_style.content_margin_bottom=14
	theme.set_stylebox("panel","PanelContainer",panel_style)
	theme.set_color("font_color","Label",Color("e4dbc3"))
	root.theme=theme
	_header=Label.new();root.add_child(_header);_header.position=Vector2(24,16);_header.add_theme_font_size_override("font_size",23)
	_hint=Label.new();root.add_child(_hint);_hint.position=Vector2(24,50);_hint.add_theme_color_override("font_color",Color("a9c2b4"))
	_mode=Button.new();_mode.name="Mode";_mode.text="Debug · F3";_mode.custom_minimum_size=Vector2(130,44);root.add_child(_mode);_mode.pressed.connect(toggle_debug)
	_tabs=HBoxContainer.new();root.add_child(_tabs);_tabs.position=Vector2(24,86);_tabs.add_theme_constant_override("separation",6)
	for key in ["requests","map","gear","contacts","settings"]:
		var button: Button=Button.new();button.name=key;button.custom_minimum_size=Vector2(0,44);_tabs.add_child(button);button.pressed.connect(_tab.bind(key))
	_panel=PanelContainer.new();root.add_child(_panel);_panel.position=Vector2(24,140)
	_scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_panel.add_child(_scroll)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): call_deferred("_publish"))
	_body=VBoxContainer.new();_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_body.add_theme_constant_override("separation",10);_scroll.add_child(_body)
	_portrait=SandboxPassengerView.new();root.add_child(_portrait);_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_portrait_title=Label.new();root.add_child(_portrait_title);_portrait_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	get_viewport().size_changed.connect(_layout)
	_layout()

func trp(en: String, ar: String) -> String:
	return ar if controller._ui_locale=="ar" else en

func _layout() -> void:
	var area: Vector2=get_viewport().get_visible_rect().size
	_mode.position=Vector2(area.x-154,18)
	_panel.size=Vector2(minf(380,area.x-48),maxf(160,area.y-166))
	_body.custom_minimum_size.x=_panel.size.x-40
	_portrait.position=Vector2(area.x-230,120);_portrait.size=Vector2(200,190)
	_portrait_title.position=Vector2(area.x-250,315);_portrait_title.size=Vector2(240,35)
	_header.size.x=area.x-200;_hint.size.x=area.x-60
	_header.clip_text=true;_hint.clip_text=true
	call_deferred("_fit_panel");call_deferred("_publish")

func toggle_debug() -> void:
	debug_mode=not debug_mode
	_last_signature=""
	sync()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F3:
		toggle_debug();get_viewport().set_input_as_handled()

func _tab(key: String) -> void:
	tab=key;_last_signature="";sync();_ack()

func _label(text: String, heading: bool=false) -> Label:
	var label: Label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=_body.custom_minimum_size.x
	if heading: label.add_theme_font_size_override("font_size",22)
	_body.add_child(label);return label

func _button(id: String, text: String, action: Callable, disabled: bool=false) -> Button:
	var button: Button=Button.new();button.name=id;button.text=text;button.custom_minimum_size=Vector2(0,44)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.disabled=disabled;button.pressed.connect(func(): action.call();_ack())
	_body.add_child(button);_actions[id]=button;return button

func _call(method: String) -> void:
	controller.call(method);_last_signature="";sync()

func _choose(index: int) -> void:
	controller._on_dialogue_choice(index);_last_signature="";sync()

func _local_select(id: String) -> void:
	controller._selected_id=id;controller._render();_last_signature="";sync()

func _drive(stop: String) -> void:
	if controller._world.reposition(stop,_planned_via,_planned_stops):
		controller._conversation=null;controller._elapsed=0;controller._notice_text=trp("Following city roads to ","على طرق المدينة إلى ")+place(stop)
	controller._render();_last_signature="";sync()

func sync() -> void:
	if controller==null: return
	controller.get_node("HUD").visible=debug_mode
	_panel.visible=not debug_mode;_tabs.visible=not debug_mode;_header.visible=not debug_mode;_hint.visible=not debug_mode
	_mode.text=trp("Player · F3","اللعب · F3") if debug_mode else trp("Debug · F3","التشخيص · F3")
	controller._city.reduced_motion=controller._reduced_motion
	controller._city.ui_rtl=controller._ui_locale=="ar"
	var world: SandboxWorld=controller._world
	var locale: String=controller._ui_locale
	root.layout_direction=Control.LAYOUT_DIRECTION_RTL if locale=="ar" else Control.LAYOUT_DIRECTION_LTR
	var font: Font=_arabic_font if locale=="ar" else ThemeDB.fallback_font
	if root.theme.default_font!=font: root.theme.default_font=font
	for child in _tabs.get_children():
		child.text={"requests":trp("Street","الشارع"),"map":trp("Map","الخريطة"),"gear":trp("Gear","الأجهزة"),"contacts":trp("Contacts","المعارف"),"settings":trp("Options","الخيارات")}[child.name]
	_header.text=trp("OUTSIDER / ","غريب / ")+SandboxCityData.REGIONS[SandboxRoads.district_for(world.player_district)]["ar" if locale=="ar" else "name"]+"   ·   %d cr"%world.credits
	_hint.text="%02d:%02d  ·  %s  ·  %s"%[(world.minute%1440)/60,world.minute%60,place(world.player_district),trp("On the road · %dm remaining","على الطريق · المتبقي %d د")%world.remaining_minutes if world.is_travelling() else trp("Parked · look for a fare","متوقف · ابحث عن راكب")]
	if world.risk>0: _hint.text+=trp(" · Attention %d"," · الانتباه %d")%world.risk
	var conversation: SandboxConversation=controller._conversation
	var speaker: Dictionary={}
	if conversation!=null: speaker=world.resident(str(world.offer_by_id(conversation.offer_id).get("npc_id","")))
	elif not world.active_offer_id.is_empty(): speaker=world.resident(str(world.offer_by_id(world.active_offer_id).get("npc_id","")))
	_portrait.npc=speaker;_portrait.reduced_motion=controller._reduced_motion
	_portrait.visible=not debug_mode and not speaker.is_empty()
	_portrait_title.visible=_portrait.visible
	_portrait_title.text=trp("Passenger · ","الراكب · ")+str(speaker.get("language","")).capitalize()
	var context: Array=[]
	match tab:
		"requests":
			var local: Array=[]
			for offer in world.open_offers():
				if offer["origin"]==world.player_district: local.append(offer)
			context=[local,world.player_district,world.active_offer_id,world.is_travelling(),controller._selected_id,controller._dialogue_text.text,controller._notice_text]
		"map": context=[world.route_nodes,world.pending_route_nodes,world.rider_route_request,world.player_district,world.credits,_map_selected,_planned_via,_planned_stops]
		"gear": context=[world.starter_device,world.modules_owned,world.modules_installed,world.market_stock,world.player_district,world.is_travelling(),SandboxKnowledge.market_open(world.minute),world.credits,world.ar_owned,world.ar_equipped,controller._ar_note]
		"contacts": context=[world.meetings,controller._selected_meeting_id,controller._meeting_text.text,controller._meeting_info.text,controller._meeting_accept.disabled,controller._meeting_decline.disabled,controller._meeting_attend.disabled]
		"settings": context=[controller._notice_text]
	var signature: String=JSON.stringify([tab,debug_mode,locale,controller._reduced_motion,context])
	if signature==_last_signature: return
	_last_signature=signature
	var scroll_position: int=_scroll.scroll_vertical
	for child in _body.get_children(): _body.remove_child(child);child.queue_free()
	_actions.clear()
	if debug_mode:
		call_deferred("_publish")
		return
	if conversation!=null and tab=="requests":
		_label(trp("In the passenger seat","في مقعد الراكب"),true)
		var line: Label=_label(controller._dialogue_text.text)
		if not conversation.understood() or controller._reveal_pending:
			line.add_theme_font_override("font",load(SandboxLanguagePresentation.native_font_path(conversation.spoken_language(world))))
		_label(trp("The city keeps moving while you read.","تستمر المدينة في الحركة أثناء القراءة."))
		var choices: Array=conversation.current_frame().get("choices",[])
		for i in range(choices.size()): _button("choice_%d"%i,SandboxLanguagePresentation.localized_choice(str(choices[i]),locale),_choose.bind(i))
		if conversation.phase=="pickup" and not controller._request_common.disabled: _button("common",trp("Ask for Common","اطلب اللغة المشتركة"),_call.bind("_on_ask_common"))
		if controller._ask_rumor.visible: _button("rumor",trp("Ask about local news","اسأل عن أخبار الحي"),_call.bind("_on_ask_rumor"))
	elif tab=="requests":
		if world.is_travelling():
			_label(trp("A city between destinations","مدينة بين وجهتين"),true)
			_label(trp("Your taxi is following the selected roads. Open the map to inspect your route.","تتبع سيارتك الطرق المختارة. افتح الخريطة لمراجعة المسار."))
			if not world.active_offer_id.is_empty():
				var fare: Dictionary=world.offer_by_id(world.active_offer_id)
				_label("%s  ·  %d cr"%[place(str(fare["destination"])),fare["fare"]])
				_button("talk",trp("Talk to your passenger","تحدث مع الراكب"),_call.bind("_on_talk"))
		else:
			_label(trp("Street requests","طلبات الشارع"),true)
			var count: int=0
			for offer in world.open_offers():
				if offer["origin"]!=world.player_district: continue
				count+=1
				_button("fare_"+str(offer["id"]),"%s · %d cr%s"%[place(str(offer["destination"])),offer["fare"],trp(" · licensed"," · مرخص") if offer["channel"]=="official" else ""],_local_select.bind(str(offer["id"])))
			if count==0: _label(trp("No one is hailing here. Wait a little or use the map to find another rank.","لا أحد يطلب توصيلة هنا. انتظر قليلًا أو اتجه إلى موقف آخر على الخريطة."))
			var chosen: Dictionary=world.offer_by_id(controller._selected_id)
			if not chosen.is_empty() and chosen["origin"]==world.player_district:
				_label(trp("Selected: ","المحدد: ")+place(str(chosen["destination"])))
				_button("talk",trp("Speak to the resident","تحدث مع المقيم"),_call.bind("_on_talk"))
				_button("accept",trp("Take this fare","اقبل التوصيلة"),_call.bind("_on_accept"),chosen["channel"]=="official")
				_button("decline",trp("Decline","ارفض"),_call.bind("_on_decline"))
			_button("wait",trp("Wait 20 minutes","انتظر ٢٠ دقيقة"),_call.bind("_on_wait"))
		_label(controller._notice_text)
	elif tab=="map":
		_label(trp("The charter port","مدينة الميناء"),true)
		var map: SandboxMapView=SandboxMapView.new();map.world=world;map.locale=locale;map.selected=_map_selected;_body.add_child(map);map.stop_selected.connect(_map_pick)
		_label(trp("Bright rings show currently visible requests. Select a stop. Roads connect only at marked junctions.","الحلقات المضيئة تشير إلى الطلبات المتاحة. اختر موقفًا. تتصل الطرق عند التقاطعات المحددة فقط."))
		var picker: OptionButton=OptionButton.new();picker.custom_minimum_size.y=44;_body.add_child(picker);_actions["destination"]=picker;picker.pressed.connect(_ack)
		for stop in SandboxRoads.DISTRICTS:
			picker.add_item(place(stop));picker.set_item_metadata(picker.item_count-1,stop)
			if stop==_map_selected: picker.select(picker.item_count-1)
		picker.item_selected.connect(func(i: int): _map_pick(str(picker.get_item_metadata(i))))
		var via_picker: OptionButton=OptionButton.new();via_picker.custom_minimum_size.y=44;_body.add_child(via_picker);_actions["via"]=via_picker;via_picker.pressed.connect(_ack)
		via_picker.add_item(trp("Fastest connected route","أسرع مسار متصل"));via_picker.set_item_metadata(0,"")
		for node in SandboxRoads.LINKS:
			via_picker.add_item(trp("Via: ","عبر: ")+place(str(node)));via_picker.set_item_metadata(via_picker.item_count-1,node)
			if node==_planned_via: via_picker.select(via_picker.item_count-1)
		via_picker.item_selected.connect(func(i: int): _planned_via=str(via_picker.get_item_metadata(i));_last_signature="";sync())
		_label(trp("Waypoints: ","النقاط: ")+waypoint_names())
		_button("add_waypoint",trp("Add selected waypoint","أضف النقطة المحددة"),_add_waypoint,_planned_via.is_empty() or _planned_stops.has(_planned_via))
		_button("clear_waypoints",trp("Clear waypoints","امسح النقاط"),_clear_waypoints,_planned_stops.is_empty())
		var path: Array[String]=SandboxRoads.path(world.player_district,_map_selected,_planned_via) if _planned_stops.is_empty() else SandboxRoads.path_via(world.player_district,_map_selected,_planned_stops)
		_label("%s · %.1f km · %d min"%[place(_map_selected),SandboxRoads.path_metres(path)/1000,SandboxRoads.path_minutes(path)])
		_button("drive",trp("Drive to this stop","قد إلى الموقف"),_drive.bind(_map_selected),world.is_travelling() or world.player_district==_map_selected or not SandboxRoads.valid_path(path))
		if not world.is_travelling():
			_button("plan_fare",trp("Use waypoint for selected fare","استخدم النقطة للتوصيلة المختارة"),_plan_fare)
		if not world.active_offer_id.is_empty():
			_label(controller._rider_info.text)
			_button("reroute",trp("Route via this stop at next junction","مر بهذا الموقف عند التقاطع التالي"),_reroute)
			_button("honor",trp("Honor passenger request","لبِّ طلب الراكب"),controller._on_rider_answer.bind(true),controller._honor.disabled)
			_button("refuse",trp("Refuse passenger request","ارفض طلب الراكب"),controller._on_rider_answer.bind(false),controller._refuse.disabled)
	elif tab=="gear":
		_label(trp("Your working kit","أدوات عملك"),true)
		if world.starter_device.is_empty():
			_label(trp("Basic Common translator included. Choose one free starter bonus.","مترجم اللغة المشتركة متاح. اختر إضافة مجانية واحدة."))
			for device in ["gps","module:local","radio"]: _button(device,trp({"gps":"GPS · route display","module:local":"Local language module","radio":"Radio · underground dispatch"}[device],{"gps":"نظام الملاحة","module:local":"وحدة اللغة المحلية","radio":"راديو الطلبات السرية"}[device]),controller._on_starter_device.bind(device),world.is_travelling())
		else: _label(controller._gear_info.text)
		_label(trp("Concourse Market · Linguist · 06:00–20:00","سوق الملتقى · اللغوي · ٠٦:٠٠–٢٠:٠٠"))
		_button("market",trp("Drive to the market","قد إلى السوق"),_drive.bind("market"),world.is_travelling() or world.player_district=="market")
		for language in ["local","cant"]:
			_button("buy_"+language,trp("Buy ","اشترِ ")+language+" · "+str(8 if language=="local" else 9)+" cr",controller._on_buy_module.bind(language),controller._buy_local.disabled if language=="local" else controller._buy_cant.disabled)
			_button("install_"+language,trp("Install ","ثبّت ")+language,controller._on_install_module.bind(language),controller._install_local.disabled if language=="local" else controller._install_cant.disabled)
		_button("ar_buy",trp("AR eyewear · 5 cr","نظارة الواقع المعزز · ٥"),_call.bind("_on_buy_ar"),controller._ar_buy.disabled)
		_button("ar_wear",trp("Remove eyewear","اخلع النظارة") if world.ar_equipped else trp("Wear eyewear","ارتدِ النظارة"),_call.bind("_on_wear_ar"),not world.ar_owned)
		if world.ar_equipped and not controller._ar_note.is_empty(): _label(str(controller._ar_note.get("text",""))+"\n"+trp("Source: ","المصدر: ")+str(controller._ar_note.get("source","")))
	elif tab=="contacts":
		_label(trp("People, not quest markers","أناس تعرفهم"),true)
		_label(controller._meeting_info.text)
		for meeting in world.meetings:
			_button("meeting_"+str(meeting["id"]),trp("Resident ","المقيم ")+str(meeting["npc_id"]).trim_prefix("npc:")+" · "+str(meeting["status"]),_select_meeting.bind(str(meeting["id"])))
		_button("meeting_accept",trp("Accept invitation","اقبل الدعوة"),_call.bind("_on_meeting_accept"),controller._meeting_accept.disabled)
		_button("meeting_decline",trp("Decline invitation","ارفض الدعوة"),_call.bind("_on_meeting_decline"),controller._meeting_decline.disabled)
		_button("meeting_attend",trp("Meet here","التقِ هنا"),_call.bind("_on_meeting_attend"),controller._meeting_attend.disabled)
		if controller._meeting_dialogue!=null:
			_label(controller._meeting_text.text)
			var meeting_choices: Array=controller._meeting_dialogue.current_frame().get("choices",[])
			for i in range(meeting_choices.size()):
				_button("meeting_choice_"+str(i),str(meeting_choices[i]),controller._on_meeting_choice.bind(i))
	elif tab=="settings":
		_label(trp("Make yourself at home","خياراتك"),true)
		_button("english","English",controller._on_language_locale.bind("en"))
		_button("arabic","العربية",controller._on_language_locale.bind("ar"))
		_button("motion",trp("Reduced motion: ","تقليل الحركة: ")+str(controller._reduced_motion),controller._on_reduced_motion.bind(not controller._reduced_motion))
		_button("save",trp("Save city and conversation","احفظ المدينة والحوار"),_call.bind("_on_save"))
		_button("load",trp("Load saved city","حمّل المدينة المحفوظة"),_call.bind("_on_load"))
		_label(controller._notice_text)
	_scroll.set_deferred("scroll_vertical",scroll_position)
	call_deferred("_fit_panel")
	call_deferred("_publish")

func _map_pick(stop: String) -> void:
	_map_selected=stop;_last_signature="";sync()
func _reroute() -> void:
	controller._route_waypoint=_map_selected;controller._on_apply_reroute()
func _select_meeting(id: String) -> void:
	controller._selected_meeting_id=id;controller._render()
func _publish() -> void:
	if not OS.has_feature("web"): return
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree(): return
	var bounds: Dictionary={}
	for key in _actions:
		var button: Button=_actions[key]
		bounds[key]={"x":button.get_global_rect().get_center().x,"y":button.get_global_rect().get_center().y,"disabled":button.disabled}
	for button in _tabs.get_children():
		bounds[button.name]={"x":button.get_global_rect().get_center().x,"y":button.get_global_rect().get_center().y,"disabled":false}
	JavaScriptBridge.eval("Object.assign(document.documentElement.dataset,%s)"%JSON.stringify({"playerActionSerial":str(_action_serial),"playerLocale":controller._ui_locale,"playerViewport":JSON.stringify([get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y]),"playerMode":str(not debug_mode).to_lower(),"playerActions":JSON.stringify(bounds),"playerTab":tab,"playerPlace":controller._world.player_district,"playerNotice":controller._notice_text,"playerPlannedVia":_planned_via,"playerRouteMinutes":str(controller._world.remaining_minutes),"playerRouteMetres":str(SandboxRoads.path_metres(controller._world.route_nodes)),"playerTravelling":str(controller._world.is_travelling()).to_lower()}),true)

func _fit_panel() -> void:
	var area: Vector2=get_viewport().get_visible_rect().size
	var height: float=minf(area.y-166,maxf(180,_body.get_combined_minimum_size().y+32))
	_panel.size.y=height
	_panel.position.y=maxf(140,area.y-height-24) if controller._conversation!=null and tab=="requests" else 140

func place(stop: String) -> String:
	if controller._ui_locale=="ar": return str(SandboxLanguagePresentation.AR_DISTRICTS.get(stop,SandboxRoads.location_name(stop)))
	return SandboxRoads.location_name(stop)

func _plan_fare() -> void:
	controller._route_waypoint=_planned_via
	controller._render()
	tab="requests";_last_signature="";sync()

func _add_waypoint() -> void:
	if not _planned_via.is_empty() and not _planned_stops.has(_planned_via): _planned_stops.append(_planned_via)
	_last_signature="";sync()
func _clear_waypoints() -> void:
	_planned_stops.clear();_planned_via="";_last_signature="";sync()

func waypoint_names() -> String:
	var names: PackedStringArray=[]
	for stop in _planned_stops: names.append(place(stop))
	return " → ".join(names)

func _ack() -> void:
	_action_serial+=1
	call_deferred("_publish")
