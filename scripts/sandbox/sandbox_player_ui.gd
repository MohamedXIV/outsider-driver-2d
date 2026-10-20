class_name SandboxPlayerUI
extends CanvasLayer

# Presentation adapter only: all actions are delegated to the existing controller.
var controller: Node
var debug_mode: bool = false
var tab: String = "requests"
var root: Control
var _header: Label
var _hint: Label
var _wallet: Label
var _body: VBoxContainer
var _panel: PanelContainer
var _scroll: ScrollContainer
var _portrait: SandboxPassengerView
var _portrait_title: Label
var _speech: SandboxPassengerSpeech
var _off_duty_stage: SandboxMeetingStage
var _button_group: VBoxContainer
var _guide: SandboxPlayerGuidance
var _tabs: GridContainer
var _mode: Button
var _actions: Dictionary = {}
var _planned_stops: Array[String] = []
var _planned_via: String = ""
var _map_selected: String = "market"
var _last_signature: String = ""
var _action_serial: int = 0
var _sync_pending: bool = false
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
	_wallet=Label.new();_wallet.name="Wallet";root.add_child(_wallet)
	_wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_wallet.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_wallet.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_wallet.add_theme_font_size_override("font_size",18)
	_wallet.add_theme_color_override("font_color",Color("eed6a6"))
	var wallet_finish: StyleBoxFlat=StyleBoxFlat.new()
	wallet_finish.bg_color=Color("253b3b")
	wallet_finish.border_color=Color("a29474")
	wallet_finish.set_border_width_all(1)
	wallet_finish.set_corner_radius_all(6)
	_wallet.add_theme_stylebox_override("normal",wallet_finish)
	# World place labels must not compete with the status text behind the HUD.
	var status_style: StyleBoxFlat=StyleBoxFlat.new();status_style.bg_color=panel_style.bg_color
	status_style.set_corner_radius_all(4)
	_header.add_theme_stylebox_override("normal",status_style);_hint.add_theme_stylebox_override("normal",status_style)
	_mode=Button.new();_mode.name="Mode";_mode.text="Debug · F3";_mode.custom_minimum_size=Vector2(130,44);root.add_child(_mode);_mode.pressed.connect(toggle_debug)
	_tabs=GridContainer.new();_tabs.mouse_filter=Control.MOUSE_FILTER_IGNORE;_tabs.columns=5;root.add_child(_tabs);_tabs.position=Vector2(24,86);_tabs.add_theme_constant_override("h_separation",6);_tabs.add_theme_constant_override("v_separation",6)
	for key in ["requests","map","gear","contacts","settings"]:
		var button: Button=Button.new();button.name=key;button.custom_minimum_size=Vector2(0,44);_tabs.add_child(button);button.pressed.connect(_tab.bind(key))
	_panel=PanelContainer.new();root.add_child(_panel);_panel.position=Vector2(24,140)
	_scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_panel.add_child(_scroll)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): call_deferred("_publish"))
	_body=VBoxContainer.new();_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_body.add_theme_constant_override("separation",10);_scroll.add_child(_body)
	_portrait=SandboxPassengerView.new();root.add_child(_portrait);_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_portrait_title=Label.new();root.add_child(_portrait_title);_portrait_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_speech=SandboxPassengerSpeech.new();_speech.name="PassengerSpeech";root.add_child(_speech)
	# Reuse the exact scene's presentation renderer; show only if World
	# proves an actual off-duty encounter in progress.
	_off_duty_stage=SandboxMeetingStage.new()
	_off_duty_stage.name="OffDutyStage"
	_off_duty_stage.show_labels=false # Avoid English debug IDs in RTL art.
	_off_duty_stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(_off_duty_stage)
	_off_duty_stage.visible=false
	_guide=SandboxPlayerGuidance.new();_guide.name="PlayerGuidance";root.add_child(_guide)
	_guide.tab_requested.connect(_tab)
	get_viewport().size_changed.connect(_layout)
	_layout()

func trp(en: String, ar: String) -> String:
	return ar if controller._ui_locale=="ar" else en

func _layout() -> void:
	var area: Vector2=get_viewport().get_visible_rect().size
	_tabs.columns=3 if area.x<600 else 5
	_tabs.size=Vector2.ZERO
	var panel_top: float=194.0 if area.x<600 else 140.0
	# The unused third cell of the second compact tab row keeps the mode
	# toggle accessible without covering the status line in either locale.
	_mode.position=Vector2(area.x-154,136 if area.x<600 else 18)
	# Cab instrument grouping: district/location and trip telemetry are
	# distinct from the money counter and the explicit developer toggle.
	_wallet.position=Vector2(area.x-132 if area.x<600 else area.x-274,17)
	_wallet.size=Vector2(108,40)
	_body.custom_minimum_size.x=minf(380,area.x-48)-40
	for child in _body.get_children():
		if child is Label: child.custom_minimum_size.x=_body.custom_minimum_size.x
	_panel.position.y=panel_top
	_panel.size=Vector2(minf(380,area.x-48),maxf(80,area.y-panel_top-24))
	_body.custom_minimum_size.x=_panel.size.x-40
	_portrait.position=Vector2(area.x-230,120);_portrait.size=Vector2(200,190)
	_portrait_title.position=Vector2(area.x-250,315);_portrait_title.size=Vector2(240,35)
	_speech.position=Vector2(area.x-542,120)
	_speech.size=Vector2(512,184)
	_speech.visible=false
	_off_duty_stage.position=Vector2(area.x-462.0,140.0)
	_off_duty_stage.size=Vector2(438.0,110.0)
	_off_duty_stage.visible=false
	_guide.position=Vector2(24 if controller._ui_locale=="ar" else area.x-306,
			365 if _portrait.visible else 120)
	_guide.size=Vector2(282,_guide.get_combined_minimum_size().y)
	_guide.visible=false # sync() decides if cross-tab guidance is actionable
	_header.add_theme_font_size_override("font_size",20 if area.x<600 else 23)
	_header.size.x=area.x-173 if area.x<600 else area.x-335
	_hint.size.x=area.x-48 if area.x<600 else area.x-200
	_header.clip_text=true;_hint.clip_text=true
	_last_signature=""
	call_deferred("sync");call_deferred("_fit_panel");call_deferred("_publish")

func toggle_debug() -> void:
	debug_mode=not debug_mode
	_last_signature=""
	sync()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F3:
		toggle_debug();get_viewport().set_input_as_handled()

func _tab(key: String) -> void:
	# Explicit navigation (even reselecting the active tab) returns to the
	# heading. Passive model refresh/purchases still preserve scroll.
	tab=key
	_scroll.scroll_vertical=0
	_last_signature=""
	sync()
	_scroll.set_deferred("scroll_vertical",0)
	_ack()

func _label(text: String, heading: bool=false) -> Label:
	var label: Label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=_body.custom_minimum_size.x
	if heading: label.add_theme_font_size_override("font_size",22)
	_body.add_child(label);return label

func _begin_button_group(label: String, section_name: String) -> void:
	var section: PanelContainer=PanelContainer.new()
	section.name=section_name
	section.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	# Source-accurate speech replies read as a warmer inset; actions stay
	# neutral. This is a visual distinction, NOT semantic/moral choice coding.
	var group_style: StyleBoxFlat=StyleBoxFlat.new()
	var is_reply: bool=section_name=="RepliesSection"
	var is_selected: bool=section_name=="SelectedFareSection"
	group_style.bg_color=Color("1c3232") if is_reply else (
		Color("1c3031") if is_selected else Color("142629"))
	group_style.border_color=Color("988c70") if is_reply else (
		Color("a09170") if is_selected else Color("607a73"))
	group_style.set_border_width_all(1)
	group_style.border_width_top=2 if is_reply else 1
	group_style.set_corner_radius_all(9)
	group_style.content_margin_left=12
	group_style.content_margin_right=12
	group_style.content_margin_top=10
	group_style.content_margin_bottom=12
	section.add_theme_stylebox_override("panel",group_style)
	_body.add_child(section)
	var contents: VBoxContainer=VBoxContainer.new()
	contents.name="Items"
	contents.add_theme_constant_override("separation",8)
	section.add_child(contents)
	var heading: Label=Label.new()
	heading.text=label
	heading.add_theme_font_size_override("font_size",18)
	contents.add_child(heading)
	_button_group=contents

func _end_button_group() -> void:
	_button_group=null

func _group_note(words: String) -> void:
	var note: Label=Label.new()
	note.text=words
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT if controller._ui_locale=="ar" else HORIZONTAL_ALIGNMENT_LEFT
	(_button_group if _button_group!=null else _body).add_child(note)

func _inline_passenger(speaker: Dictionary, words: String, locale: String,
		font_path: String) -> void:
	var speech: SandboxPassengerSpeech=SandboxPassengerSpeech.new()
	speech.name="PassengerSpeechInline"
	speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speech.custom_minimum_size.y=150.0
	_body.add_child(speech)
	speech.present(speaker,words,locale,font_path,controller._reduced_motion)

func _gear_readout(kind: String, title: String, detail: String) -> void:
	# The actual World-owned equipment state is given to this read-only
	# cab instrument. It never unlocks a module or infers language knowledge.
	var device: SandboxCabGearPlate=SandboxCabGearPlate.new()
	device.name="Device_"+kind
	device.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	device.custom_minimum_size.y=74.0
	(_button_group if _button_group!=null else _body).add_child(device)
	device.present(kind,title,detail,controller._ui_locale=="ar")

func _button(id: String, text: String, action: Callable, disabled: bool=false) -> Button:
	var button: Button=Button.new();button.name=id;button.text=text;button.custom_minimum_size=Vector2(0,44)
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.disabled=disabled;button.pressed.connect(func(): action.call();_ack())
	(_button_group if _button_group!=null else _body).add_child(button);_actions[id]=button;return button

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
	_panel.visible=not debug_mode;_tabs.visible=not debug_mode;_header.visible=not debug_mode;_hint.visible=not debug_mode;_wallet.visible=not debug_mode
	_mode.text=trp("Player · F3","اللعب · F3") if debug_mode else trp("Debug · F3","التشخيص · F3")
	controller._city.reduced_motion=controller._reduced_motion
	controller._city.ui_rtl=controller._ui_locale=="ar"
	var world: SandboxWorld=controller._world
	var locale: String=controller._ui_locale
	root.layout_direction=Control.LAYOUT_DIRECTION_RTL if locale=="ar" else Control.LAYOUT_DIRECTION_LTR
	var font: Font=_arabic_font if locale=="ar" else ThemeDB.fallback_font
	if root.theme.default_font!=font: root.theme.default_font=font
	for child in _tabs.get_children():
		child.toggle_mode=true
		child.button_pressed=child.name==tab
		child.text={"requests":trp("Street","الشارع"),"map":trp("Map","الخريطة"),"gear":trp("Gear","الأجهزة"),"contacts":trp("Contacts","المعارف"),"settings":trp("Options","الخيارات")}[child.name]
		if child.name=="requests" and world.rider_initiative.get("status","")=="pending":
			child.text+=" •"
	var region_name: String=str(SandboxCityData.REGIONS[
		SandboxRoads.district_for(world.player_district)]["ar" if locale=="ar" else "name"])
	_header.text=place(world.player_district)
	_wallet.text="%d cr"%world.credits # Technical unit only; fiction currency still undecided.
	var travel_state: String=trp("En route · %dm","في الطريق · %d د")%world.remaining_minutes if world.is_travelling() else trp("Parked","متوقف")
	_hint.text="%02d:%02d  ·  %s  ·  %s"%[(world.minute%1440)/60,world.minute%60,region_name,travel_state]
	if world.risk>0: _hint.text+=trp(" · Attention %d"," · الانتباه %d")%world.risk
	var conversation: SandboxConversation=controller._conversation
	var speaker: Dictionary={}
	if conversation!=null: speaker=world.resident(str(world.offer_by_id(conversation.offer_id).get("npc_id","")))
	elif not world.active_offer_id.is_empty(): speaker=world.resident(str(world.offer_by_id(world.active_offer_id).get("npc_id","")))
	var area: Vector2=get_viewport().get_visible_rect().size
	# The authored Ink meeting's visual stage is an observation, not a
	# second simulation or a speech bubble attributed to the resident.
	var active_meeting: Dictionary=world.meeting_by_id(controller._selected_meeting_id)
	_off_duty_stage.visible=not debug_mode and tab=="contacts" and (
		str(active_meeting.get("status",""))=="in_progress") and area.x>=980.0
	if _off_duty_stage.visible:
		_off_duty_stage.venue=str(active_meeting["location"])
		_off_duty_stage.companion=str(active_meeting["npc_id"])
		_off_duty_stage.companion_species=str(world.resident(str(active_meeting["npc_id"])).get("species",""))
		_off_duty_stage.position=Vector2(area.x-462.0,140.0)
		_off_duty_stage.queue_redraw()
	var utterance: String=""
	var script_font: String=""
	if conversation!=null:
		utterance=controller._dialogue_text.text
		if not conversation.understood() or controller._reveal_pending:
			script_font=SandboxLanguagePresentation.native_font_path(conversation.spoken_language(world))
	elif world.is_travelling() and world.rider_initiative.get("status","")=="pending":
		var request: Dictionary=world.rider_initiative
		speaker=world.resident(str(request.get("npc_id","")))
		utterance=SandboxRiderInitiative.question(world,locale)
		if not SandboxRiderInitiative.understood(world):
			script_font=SandboxLanguagePresentation.native_font_path(str(speaker.get("language","")))
	var speaking: bool=not utterance.is_empty() and not speaker.is_empty()
	var wide_speech: bool=area.x>=980.0
	_portrait.npc=speaker;_portrait.reduced_motion=controller._reduced_motion
	_portrait.visible=not debug_mode and not speaker.is_empty() and not speaking and area.x>=600
	_portrait_title.visible=_portrait.visible
	_portrait_title.text=trp("Passenger","الراكب")
	_speech.visible=not debug_mode and tab=="requests" and speaking and wide_speech
	_speech.position=Vector2(24.0 if locale=="ar" else area.x-542.0,120.0)
	_speech.size=Vector2(512.0,184.0)
	if _speech.visible:
		_speech.present(speaker,utterance,locale,script_font,controller._reduced_motion)
	var objective: Dictionary=SandboxPlayerGuidance.describe(world,locale,controller._selected_id,conversation!=null)
	_guide.present(objective,tab)
	# Only show guidance when it offers real navigation to a different tab.
	# RTL moves the actual Settings/Street panels to the right, so our card
	# must be on the opposite side rather than covering their hit targets.
	var relevant_tab: String=str(objective.get("tab","requests"))
	# When browsing equipment, nonurgent "no fares" guidance competes with
	# the city for no useful reason. Passenger conversation / initiative can
	# still signal that attention is needed back on Street.
	var passenger_needs_attention: bool=conversation!=null or (
		world.rider_initiative.get("status","")=="pending")
	# Equipment onboarding and ordinary fare tips must not distract from
	# an off-duty appointment either. Genuine passenger interruption still
	# has permission to call attention to Street.
	var private_context: bool=tab=="gear" or tab=="contacts"
	_guide.visible=not debug_mode and area.x>=820 and area.y>=570 and (
		relevant_tab!=tab) and not _speech.visible and (
		not private_context or passenger_needs_attention)
	_guide.position=Vector2(24 if locale=="ar" else area.x-306,
			365 if _portrait.visible else 120)
	_guide.size=Vector2(282,_guide.get_combined_minimum_size().y)
	var context: Array=[]
	match tab:
		"requests":
			var local: Array=[]
			for offer in world.open_offers():
				if offer["origin"]==world.player_district: local.append(offer)
			context=[local,world.player_district,world.active_offer_id,world.is_travelling(),
					world.rider_initiative,controller._selected_id,controller._dialogue_text.text,controller._notice_text]
		"map": context=[world.route_nodes,world.pending_route_nodes,world.rider_route_request,world.player_district,world.credits,_map_selected,_planned_via,_planned_stops]
		"gear": context=[world.starter_device,world.modules_owned,world.modules_installed,world.market_stock,world.player_district,world.is_travelling(),SandboxKnowledge.market_open(world.minute),world.credits,world.ar_owned,world.ar_equipped,controller._ar_note]
		"contacts": context=[world.meetings,controller._selected_meeting_id,controller._meeting_text.text,controller._meeting_info.text,controller._meeting_accept.disabled,controller._meeting_decline.disabled,controller._meeting_attend.disabled]
		"settings": context=[controller._notice_text,controller._city.zoom_preference]
	var signature: String=JSON.stringify([tab,debug_mode,locale,controller._reduced_motion,context])
	if signature==_last_signature: return
	# Preserve the actual pressed Control until pointer-up. A stable target
	# position alone does not preserve Godot's pointer capture when the old
	# button is freed between the browser's down/up input deliveries.
	if _controls_pressed():
		_sync_after_release()
		return
	_last_signature=signature
	var scroll_position: int=_scroll.scroll_vertical
	for child in _body.get_children(): _body.remove_child(child);child.queue_free()
	_actions.clear()
	_button_group=null
	if debug_mode:
		call_deferred("_publish")
		return
	if conversation!=null and tab=="requests":
		if not wide_speech:
			_inline_passenger(speaker,utterance,locale,script_font)
		var choices: Array=conversation.current_frame().get("choices",[])
		if not choices.is_empty():
			_begin_button_group(trp("Replies","الردود"),"RepliesSection")
			for i in range(choices.size()):
				_button("choice_%d"%i,SandboxLanguagePresentation.localized_choice(str(choices[i]),locale),_choose.bind(i))
			_end_button_group()
		if (conversation.phase=="pickup" and not controller._request_common.disabled) or controller._ask_rumor.visible:
			_begin_button_group(trp("Actions","إجراءات"),"ActionsSection")
			if conversation.phase=="pickup" and not controller._request_common.disabled:
				_button("common",trp("Ask for Common","اطلب اللغة المشتركة"),_call.bind("_on_ask_common"))
			if controller._ask_rumor.visible:
				_button("rumor",trp("Ask about local news","اسأل عن أخبار الحي"),_call.bind("_on_ask_rumor"))
			_end_button_group()
	elif tab=="requests":
		if world.is_travelling():
			if not world.active_offer_id.is_empty():
				var fare: Dictionary=world.offer_by_id(world.active_offer_id)
				_label("%s  ·  %d cr"%[place(str(fare["destination"])),fare["fare"]])
				var prompt: Dictionary=world.rider_initiative
				if prompt.get("status","")=="pending":
					if not wide_speech:
						_inline_passenger(speaker,utterance,locale,script_font)
					_begin_button_group(trp("Replies","الردود"),"RepliesSection")
					if SandboxRiderInitiative.understood(world):
						_button("reply_brief",trp("Answer briefly","أجب باختصار"),
								controller._on_rider_initiative_answer.bind("brief"))
						_button("reply_deflect",trp("Deflect the question","تهرّب من السؤال"),
								controller._on_rider_initiative_answer.bind("deflect"))
					_button("reply_silent",trp("Stay quiet","التزم الصمت"),
							controller._on_rider_initiative_answer.bind("silent"))
					_end_button_group()
				_begin_button_group(trp("Actions","إجراءات"),"ActionsSection")
				_button("talk",trp("Talk","تحدث"),_call.bind("_on_talk"))
				_end_button_group()
		else:
			_label(trp("Street fares","توصيلات الشارع"),true)
			# Keep Wait immediately below this stable heading. Demand changes
			# must never relocate its live pointer target mid-click.
			_button("wait",trp("Wait 20 minutes","انتظر ٢٠ دقيقة"),_call.bind("_on_wait"))
			var chosen: Dictionary=world.offer_by_id(controller._selected_id)
			if not chosen.is_empty() and chosen["origin"]==world.player_district:
				_begin_button_group(trp("Selected fare","التوصيلة المحددة")+" · "+
					place(str(chosen["destination"])),"SelectedFareSection")
				_button("talk",trp("Speak to the resident","تحدث مع المقيم"),_call.bind("_on_talk"))
				_button("accept",trp("Take this fare","اقبل التوصيلة"),_call.bind("_on_accept"),chosen["channel"]=="official")
				_button("decline",trp("Decline","ارفض"),_call.bind("_on_decline"))
				_end_button_group()
			var local_offers: Array=[]
			for offer in world.open_offers():
				if offer["origin"]==world.player_district: local_offers.append(offer)
			if not local_offers.is_empty():
				_begin_button_group(trp("Available fares","التوصيلات المتاحة"),"FaresSection")
				for offer in local_offers:
					_button("fare_"+str(offer["id"]),
						"%s · %d cr%s"%[place(str(offer["destination"])),offer["fare"],
						trp(" · licensed"," · مرخص") if offer["channel"]=="official" else ""],
						_local_select.bind(str(offer["id"])))
				_end_button_group()
			else:
				_label(trp("No fares at this stop","لا توجد توصيلات في هذا الموقف"))
		_label(controller._notice_text)
	elif tab=="map":
		_label(trp("The charter port","مدينة الميناء"),true)
		var map: SandboxMapView=SandboxMapView.new();map.world=world;map.locale=locale;map.selected=_map_selected;_body.add_child(map);map.stop_selected.connect(_map_pick)
		_label(trp("Rings: available fares · Lines: connected roads","الحلقات: التوصيلات المتاحة · الخطوط: الطرق المتصلة"))
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
		map.preview_nodes=path;map.preview_active=true;map.queue_redraw()
		if SandboxRoads.valid_path(path): _label(trp("Road tolls: %d cr · Empty-trip fuel: %d cr","رسوم الطريق: %d · وقود الرحلة الفارغة: %d")%[SandboxRoads.path_expense(path),maxi(1,ceili(SandboxRoads.path_metres(path)/5000))])
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
		_label(trp("Cab equipment","تجهيزات التاكسي"),true)
		var installed: PackedStringArray=[]
		var en_languages: Dictionary={"trade":"Common","local":"Local","cant":"Cant"}
		var ar_languages: Dictionary={"trade":"المشتركة","local":"المحلية","cant":"الكانت"}
		for language in world.modules_installed:
			installed.append(trp(str(en_languages.get(language,language)),
				str(ar_languages.get(language,language))))
		_begin_button_group(trp("Cab instruments","أجهزة المقصورة"),"CabInstrumentsSection")
		if world.starter_device.is_empty():
			_gear_readout("translator",trp("Translator","المترجم"),
				trp("Common installed","اللغة المشتركة مثبتة"))
		else:
			var starter_names: Dictionary={"gps":trp("GPS","الملاحة"),
				"module:local":trp("Local translator","مترجم اللغة المحلية"),
				"radio":trp("Radio","الراديو")}
			var starter_kind: String="translator_starter" if world.starter_device=="module:local" else world.starter_device
			_gear_readout(starter_kind,str(starter_names.get(world.starter_device,world.starter_device)),
				trp("Starter device","جهاز البداية"))
		_gear_readout("translator",trp("Language cartridges","وحدات اللغة"),
			trp("Installed: ","المثبتة: ")+" / ".join(installed))
		if world.ar_owned:
			_gear_readout("ar",trp("AR eyewear","نظارة الواقع المعزز"),
				trp("Worn","مرتداة") if world.ar_equipped else trp("Stored","محفوظة"))
		_end_button_group()
		if world.starter_device.is_empty():
			_begin_button_group(trp("Choose one free starter","اختر جهاز بداية مجانيًا"),
				"StarterGearSection")
			_button("gps",trp("GPS · navigation","الملاحة · GPS"),
				controller._on_starter_device.bind("gps"),world.is_travelling())
			_button("module:local",trp("Local translator module","وحدة ترجمة اللغة المحلية"),
				controller._on_starter_device.bind("module:local"),world.is_travelling())
			_button("radio",trp("Radio receiver","جهاز الراديو"),
				controller._on_starter_device.bind("radio"),world.is_travelling())
			_end_button_group()
		_begin_button_group(trp("Fitting & controls","التركيب والتحكم"),"FittingGearSection")
		for language in ["local","cant"]:
			var install_name: String=trp("Local","المحلية") if language=="local" else trp("Cant","الكانت")
			_button("install_"+language,trp("Install ","ثبّت ")+install_name,
				controller._on_install_module.bind(language),
				controller._install_local.disabled if language=="local" else controller._install_cant.disabled)
		_button("ar_wear",trp("Remove eyewear","اخلع النظارة") if world.ar_equipped else
			trp("Wear eyewear","ارتدِ النظارة"),_call.bind("_on_wear_ar"),not world.ar_owned)
		if world.ar_equipped and not controller._ar_note.is_empty():
			var source: String=str(controller._ar_note.get("source",""))
			var note: Label=Label.new()
			note.text="%s\n%s%s"%[str(controller._ar_note.get("text","")),
				trp("Source: ","المصدر: "),source]
			note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			_button_group.add_child(note)
		_end_button_group()
		_begin_button_group(trp("Linguist counter · 06:00–20:00","مكتب اللغوي · ٠٦:٠٠–٢٠:٠٠"),
			"MarketGearSection")
		_button("market",trp("Concourse Market · directions","سوق الملتقى · الطريق"),
			_drive.bind("market"),world.is_travelling() or world.player_district=="market")
		for language in ["local","cant"]:
			var name: String=trp("Local","المحلية") if language=="local" else trp("Cant","الكانت")
			var price: int=8 if language=="local" else 9
			_button("buy_"+language,trp("Buy ","اشترِ ")+name+" · %d cr"%price,
				controller._on_buy_module.bind(language),
				controller._buy_local.disabled if language=="local" else controller._buy_cant.disabled)
		_button("ar_buy",trp("AR eyewear · 5 cr","نظارة الواقع المعزز · ٥ cr"),
			_call.bind("_on_buy_ar"),controller._ar_buy.disabled)
		_end_button_group()
	elif tab=="contacts":
		# During an authentic off-duty scene, dialogue takes visual priority.
		# On a small screen the previous invite-first order pushed the
		# actual Ink line entirely below the first visible scroll page.
		if controller._meeting_dialogue!=null:
			_label(trp("Off-duty encounter","لقاء خارج العمل"),true)
		if controller._meeting_dialogue!=null:
			# A real Ink frame may contain stage directions, not speech; avoid
			# giving them an invented speaker or an unauthorized translation.
			_begin_button_group(trp("At the meeting","أثناء اللقاء"),"ContactSceneSection")
			_group_note(controller._meeting_text.text)
			_end_button_group()
			var meeting_choices: Array=controller._meeting_dialogue.current_frame().get("choices",[])
			if not meeting_choices.is_empty():
				_begin_button_group(trp("Replies","الردود"),"ContactRepliesSection")
				for i in range(meeting_choices.size()):
					_button("meeting_choice_"+str(i),str(meeting_choices[i]),
						controller._on_meeting_choice.bind(i))
				_end_button_group()
		else:
			_label(trp("People & appointments","المعارف والمواعيد"),true)
		var status_text: Dictionary={
			"invited":trp("Invited","دعوة"),
			"accepted":trp("Confirmed","مؤكد"),
			"in_progress":trp("In progress","جارٍ"),
			"completed":trp("Completed","مكتمل"),
			"left":trp("Left","انتهى بالمغادرة"),
			"missed":trp("Missed","فات الموعد"),
			"declined":trp("Declined","مرفوض"),
			"expired":trp("Expired","منتهٍ"),
			"cancelled":trp("Cancelled","ملغى")}
		if world.meetings.is_empty():
			_label(trp("No invitations","لا توجد دعوات"))
		else:
			_begin_button_group(trp("Invitations & meetings","الدعوات والمواعيد"),"ContactsListSection")
			for meeting in world.meetings:
				var meeting_id: String=str(meeting["id"])
				var meeting_state: String=str(meeting["status"])
				var caption: String=trp("Resident ","المقيم ")+str(meeting["npc_id"]).trim_prefix("npc:")+" · "+str(status_text.get(meeting_state,meeting_state))
				_button("meeting_"+meeting_id,caption,_select_meeting.bind(meeting_id))
			_end_button_group()
		var selected_meeting: Dictionary=world.meeting_by_id(controller._selected_meeting_id)
		if not selected_meeting.is_empty():
			var slot: int=int(selected_meeting["slot"])
			var resident: Dictionary=world.resident(str(selected_meeting["npc_id"]))
			var actual_presence: String=trp("Here","هنا") if str(resident.get("location",""))==str(selected_meeting["location"]) else trp("Elsewhere","في مكان آخر")
			_begin_button_group(trp("Appointment","الموعد"),"ContactDetailsSection")
			_group_note("%s · %s"%[place(str(selected_meeting["location"])),
				str(status_text.get(str(selected_meeting["status"]),str(selected_meeting["status"])))])
			_group_note("%s%d · %02d:%02d · %s"%[
				trp("Day ","اليوم "),int(slot/1440)+1,int((slot%1440)/60),slot%60,
				trp("Contact: ","الشخص: ")+actual_presence])
			_end_button_group()
			# Offer only state-valid appointment actions. In particular,
			# completed or missed encounters are history, not disabled forms.
			if controller._meeting_dialogue==null:
				var state: String=str(selected_meeting["status"])
				if state=="invited" or state=="accepted":
					_begin_button_group(trp("Meeting actions","إجراءات الموعد"),"ContactActionsSection")
					if state=="invited":
						_button("meeting_accept",trp("Accept invitation","اقبل الدعوة"),
							_call.bind("_on_meeting_accept"),controller._meeting_accept.disabled)
						_button("meeting_decline",trp("Decline invitation","ارفض الدعوة"),
							_call.bind("_on_meeting_decline"),controller._meeting_decline.disabled)
					elif state=="accepted":
						_button("meeting_attend",trp("Meet here","التقِ هنا"),
							_call.bind("_on_meeting_attend"),controller._meeting_attend.disabled)
					_end_button_group()

	elif tab=="settings":
		_label(trp("Options","الخيارات"),true)
		_button("english","English",controller._on_language_locale.bind("en"))
		_button("arabic","العربية",controller._on_language_locale.bind("ar")).add_theme_font_override("font",_arabic_font)
		_button("motion",trp("Reduced motion: ","تقليل الحركة: ")+(trp("On","مفعّل") if controller._reduced_motion else trp("Off","متوقف")),controller._on_reduced_motion.bind(not controller._reduced_motion))
		_label(trp("Camera · wheel or +/- · %.2fx", "الكاميرا · عجلة الفأرة أو +/- · %.2fx") % controller._city.zoom_preference)
		_button("zoom_in",trp("Zoom in +","تقريب +"),controller._change_zoom.bind(0.2),controller._city.zoom_preference >= SandboxCityView.MAX_ZOOM)
		_button("zoom_out",trp("Zoom out −","إبعاد −"),controller._change_zoom.bind(-0.2),controller._city.zoom_preference <= SandboxCityView.MIN_ZOOM)
		_button("zoom_reset",trp("Reset camera","إعادة ضبط الكاميرا"),_reset_zoom)
		_button("save",trp("Save city and conversation","احفظ المدينة والحوار"),_call.bind("_on_save"))
		_button("load",trp("Load saved city","حمّل المدينة المحفوظة"),_call.bind("_on_load"))
		_label(controller._notice_text)
	_scroll.set_deferred("scroll_vertical",scroll_position)
	call_deferred("_fit_panel")
	call_deferred("_publish")

func _controls_pressed() -> bool:
	for action in _actions.values():
		if not is_instance_valid(action): continue
		# OptionButton may release the trigger while its native PopupMenu
		# still owns the keyboard. A World/offer refresh must not free the
		# actual open destination/via selector before the player's Enter.
		if action is OptionButton and action.get_popup().visible: return true
		if action.is_pressed(): return true
	return false

func _sync_after_release() -> void:
	if _sync_pending: return
	_sync_pending=true
	while is_inside_tree() and _controls_pressed(): await get_tree().process_frame
	_sync_pending=false
	if is_inside_tree(): sync()

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
	var mode_rect: Rect2=_mode.get_global_rect()
	# Browser evidence is read from the actual rendered Player UI, never a
	# second synthetic meeting model or fabricated labels. Stage directions
	# remain unattributed until an authored speaker exists.
	var contact_sections: Dictionary={}
	var contact_scene_text: String=""
	var contact_scene_top_visible: bool=false
	if not debug_mode and tab=="contacts":
		for section_name in ["ContactsListSection","ContactDetailsSection",
				"ContactActionsSection","ContactSceneSection","ContactRepliesSection"]:
			contact_sections[section_name]=_body.has_node(section_name)
		if _body.has_node("ContactSceneSection/Items"):
			var scene_items: Node=_body.get_node("ContactSceneSection/Items")
			if scene_items.get_child_count()>1 and scene_items.get_child(1) is Label:
				var line: Label=scene_items.get_child(1) as Label
				contact_scene_text=line.text
				var top: float=line.get_global_rect().position.y
				var scroll_rect: Rect2=_scroll.get_global_rect()
				contact_scene_top_visible=top>=scroll_rect.position.y and top<scroll_rect.end.y-8.0
	for key in _actions:
		var button: Button=_actions[key]
		bounds[key]={"x":button.get_global_rect().get_center().x,"y":button.get_global_rect().get_center().y,"disabled":button.disabled,
			"clipTop":_scroll.get_global_rect().position.y,"clipBottom":_scroll.get_global_rect().end.y}
	for button in _tabs.get_children():
		bounds[button.name]={"x":button.get_global_rect().get_center().x,"y":button.get_global_rect().get_center().y,"disabled":false}
	JavaScriptBridge.eval("Object.assign(document.documentElement.dataset,%s)"%JSON.stringify({"playerModeBounds":JSON.stringify([mode_rect.position.x,mode_rect.position.y,mode_rect.size.x,mode_rect.size.y]),"playerZoom":str(controller._city.zoom_preference),"playerActionSerial":str(_action_serial),"playerLocale":controller._ui_locale,"playerViewport":JSON.stringify([get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y]),"playerMode":str(not debug_mode).to_lower(),"playerActions":JSON.stringify(bounds),"playerTab":tab,"playerPlace":controller._world.player_district,"playerNotice":controller._notice_text,"playerPlannedVia":_planned_via,"playerRouteMinutes":str(controller._world.remaining_minutes),"playerRouteMetres":str(SandboxRoads.path_metres(controller._world.route_nodes)),"playerTravelling":str(controller._world.is_travelling()).to_lower(),
			"playerRiderStatus":str(controller._world.rider_initiative.get("status","")),
			"playerRiderQuestion":SandboxRiderInitiative.question(controller._world,controller._ui_locale),
			"playerContactSections":JSON.stringify(contact_sections),
			"playerContactSceneText":contact_scene_text,
			"playerContactSceneTopVisible":str(contact_scene_top_visible).to_lower(),
			"playerContactStage":str(_off_duty_stage.visible).to_lower()}),true)

func _fit_panel() -> void:
	var area: Vector2=get_viewport().get_visible_rect().size
	var panel_top: float=194.0 if area.x<600 else 140.0
	var available: float=maxf(80.0,area.y-panel_top-24)
	if area.x<600:
		# Fixed-height compact bottom sheet leaves the living city readable.
		# Do not resize/reposition Wait as autonomous offers change height.
		var height: float=minf(available,maxf(180.0,area.y*0.46))
		_panel.size.y=height
		_panel.position.y=maxf(panel_top,area.y-height-24)
		return
	var height: float=minf(available,maxf(180,_body.get_combined_minimum_size().y+32))
	_panel.size.y=height
	_panel.position.y=maxf(panel_top,area.y-height-24) if controller._conversation!=null and tab=="requests" else panel_top

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

func _reset_zoom() -> void:
	controller._city.set_manual_zoom(SandboxCityView.DEFAULT_ZOOM)
	sync()
