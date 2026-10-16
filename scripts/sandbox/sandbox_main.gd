extends Node2D

@onready var _city: SandboxCityView = $CityView
@onready var _status: Label = $HUD/DockPanel/Content/Status
@onready var _offers: ItemList = $HUD/DockPanel/Content/Offers
@onready var _details: Label = $HUD/DockPanel/Content/Details
@onready var _notice: Label = $HUD/DockPanel/Content/Notice
@onready var _accept: Button = $HUD/DockPanel/Content/Actions/Accept
@onready var _decline: Button = $HUD/DockPanel/Content/Actions/Decline
@onready var _districts: OptionButton = $HUD/DockPanel/Content/Navigation/District
@onready var _reposition: Button = $HUD/DockPanel/Content/Navigation/Reposition
@onready var _clock: Label = $HUD/DockPanel/Content/Clock
@onready var _world_info: Label = $HUD/WorldPanel/Content/WorldInfo
@onready var _observe: Button = $HUD/WorldPanel/Content/Observe
@onready var _route_panel: PanelContainer = $HUD/RoutePanel
@onready var _via: OptionButton = $HUD/RoutePanel/Content/Via
@onready var _route_preview: Label = $HUD/RoutePanel/Content/Preview
@onready var _rider_info: Label = $HUD/RoutePanel/Content/RiderInfo
@onready var _apply_route: Button = $HUD/RoutePanel/Content/RouteActions/Apply
@onready var _honor: Button = $HUD/RoutePanel/Content/RouteActions/Honor
@onready var _refuse: Button = $HUD/RoutePanel/Content/RouteActions/Refuse
@onready var _talk: Button = $HUD/DockPanel/Content/Actions/Talk
@onready var _dialogue_panel: PanelContainer = $HUD/DialoguePanel
@onready var _dialogue_title: Label = $HUD/DialoguePanel/Content/Title
@onready var _dialogue_text: Label = $HUD/DialoguePanel/Content/Line
@onready var _dialogue_choices: VBoxContainer = $HUD/DialoguePanel/Content/Choices
@onready var _locale_en: Button = $HUD/DialoguePanel/Content/LanguageSettings/English
@onready var _locale_ar: Button = $HUD/DialoguePanel/Content/LanguageSettings/Arabic
@onready var _reduce_motion: CheckButton = $HUD/DialoguePanel/Content/LanguageSettings/ReducedMotion
@onready var _skip_translation: Button = $HUD/DialoguePanel/Content/SkipTranslation
@onready var _gear_panel: PanelContainer = $HUD/GearPanel
@onready var _gear_info: Label = $HUD/GearPanel/Content/Info
@onready var _gps: Button = $HUD/GearPanel/Content/Devices/GPS
@onready var _translator: Button = $HUD/GearPanel/Content/Devices/Translator
@onready var _radio: Button = $HUD/GearPanel/Content/Devices/Radio
@onready var _drive_market: Button = $HUD/GearPanel/Content/MarketHeading/DriveMarket
@onready var _buy_local: Button = $HUD/GearPanel/Content/MarketBuy/BuyLocal
@onready var _buy_cant: Button = $HUD/GearPanel/Content/MarketBuy/BuyCant
@onready var _install_local: Button = $HUD/GearPanel/Content/MarketInstall/InstallLocal
@onready var _install_cant: Button = $HUD/GearPanel/Content/MarketInstall/InstallCant
@onready var _request_common: Button = $HUD/DialoguePanel/Content/RequestCommon
@onready var _ask_rumor: Button = $HUD/DialoguePanel/Content/AskRumor
@onready var _ar_buy: Button = $HUD/WorldPanel/Content/ARActions/BuyAR
@onready var _ar_wear: Button = $HUD/WorldPanel/Content/ARActions/WearAR
@onready var _ar_context: Button = $HUD/ARContext
@onready var _ar_panel: PanelContainer = $HUD/ARHintPanel
@onready var _ar_title: Label = $HUD/ARHintPanel/Content/Title
@onready var _ar_text: Label = $HUD/ARHintPanel/Content/Body
@onready var _ar_close: Button = $HUD/ARHintPanel/Content/Close
@onready var _meeting_selector: OptionButton = $HUD/WorldPanel/Content/MeetingSelect
@onready var _meeting_info: Label = $HUD/WorldPanel/Content/MeetingInfo
@onready var _meeting_accept: Button = $HUD/WorldPanel/Content/MeetingActions/AcceptMeeting
@onready var _meeting_decline: Button = $HUD/WorldPanel/Content/MeetingActions/DeclineMeeting
@onready var _meeting_attend: Button = $HUD/WorldPanel/Content/MeetingActions/AttendMeeting
@onready var _meeting_panel: PanelContainer = $HUD/MeetingPanel
@onready var _meeting_stage: SandboxMeetingStage = $HUD/MeetingPanel/Content/Stage
@onready var _meeting_title: Label = $HUD/MeetingPanel/Content/Title
@onready var _meeting_text: Label = $HUD/MeetingPanel/Content/Line
@onready var _meeting_choices: VBoxContainer = $HUD/MeetingPanel/Content/Choices

const REAL_SECONDS_PER_STEP: float = 1.0

var _street_pilot: SandboxStreetPilot
var _street_restore_state: Dictionary = {}
var _player_ui: SandboxPlayerUI
var _world: SandboxWorld = SandboxWorld.new(8)
var _selected_id: String = ""
var _notice_text: String = "Patchworks Garage, Outer Margin. Your shift begins at home."
var _elapsed: float = 0.0
var _conversation: SandboxConversation
var _last_intent: String = ""
var _last_outcome: String = ""
var _route_waypoint: String = ""
var _route_for_offer: String = ""
var _selected_meeting_id: String = ""
var _meeting_dialogue: SandboxMeetingDialogue
var _ar_note: Dictionary = {}
var _ui_locale: String = "en"
var _reduced_motion: bool = false
var _speech_identity: String = ""
var _source_text: String = ""
var _translated_text: String = ""
var _reveal_pending: bool = false
var _reveal_elapsed: float = 0.0
const REVEAL_SECONDS: float = 0.7
const ARABIC_FONT: String = "res://assets/fonts/NotoNaskhArabicUI[wght].ttf"


func _ready() -> void:
	_city.world = _world
	for district in SandboxRoads.DISTRICTS:
		_districts.add_item(district.capitalize())
	_districts.select(0)
	_offers.item_selected.connect(_on_selected)
	_via.item_selected.connect(_on_waypoint_selected)
	_apply_route.pressed.connect(_on_apply_reroute)
	_honor.pressed.connect(_on_rider_answer.bind(true))
	_refuse.pressed.connect(_on_rider_answer.bind(false))
	_city.waypoint_clicked.connect(_on_map_waypoint)
	_gps.pressed.connect(_on_starter_device.bind("gps"))
	_translator.pressed.connect(_on_starter_device.bind("module:local"))
	_drive_market.pressed.connect(_on_drive_market)
	_buy_local.pressed.connect(_on_buy_module.bind("local"))
	_buy_cant.pressed.connect(_on_buy_module.bind("cant"))
	_install_local.pressed.connect(_on_install_module.bind("local"))
	_install_cant.pressed.connect(_on_install_module.bind("cant"))
	_request_common.pressed.connect(_on_ask_common)
	_ask_rumor.pressed.connect(_on_ask_rumor)
	_ar_buy.pressed.connect(_on_buy_ar)
	_ar_wear.pressed.connect(_on_wear_ar)
	_ar_context.pressed.connect(_show_ar_hint)
	_ar_context.mouse_entered.connect(_show_ar_hint)
	_ar_context.focus_entered.connect(_show_ar_hint)
	_ar_close.pressed.connect(_close_ar_hint)
	_locale_en.pressed.connect(_on_language_locale.bind("en"))
	_locale_ar.pressed.connect(_on_language_locale.bind("ar"))
	_reduce_motion.toggled.connect(_on_reduced_motion)
	_skip_translation.pressed.connect(_finish_language_reveal)
	if OS.has_feature("web"):
		_reduced_motion = bool(JavaScriptBridge.eval(
				"window.matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	_reduce_motion.set_pressed_no_signal(_reduced_motion)
	_radio.pressed.connect(_on_starter_device.bind("radio"))
	_meeting_selector.item_selected.connect(_on_meeting_selected)
	_meeting_accept.pressed.connect(_on_meeting_accept)
	_meeting_decline.pressed.connect(_on_meeting_decline)
	_meeting_attend.pressed.connect(_on_meeting_attend)
	_talk.pressed.connect(_on_talk)
	_accept.pressed.connect(_on_accept)
	_decline.pressed.connect(_on_decline)
	_reposition.pressed.connect(_on_reposition)
	$HUD/DockPanel/Content/TimeActions/Wait.pressed.connect(_on_wait)
	_observe.pressed.connect(_on_observe)
	$HUD/DockPanel/Content/TimeActions/NewSeed.pressed.connect(_on_new_seed)
	$HUD/DockPanel/Content/Persistence/Save.pressed.connect(_on_save)
	$HUD/DockPanel/Content/Persistence/Load.pressed.connect(_on_load)
	_player_ui=SandboxPlayerUI.new()
	add_child(_player_ui)
	_player_ui.bind(self)
	_render()


func _process(delta: float) -> void:
	if _reveal_pending and _conversation != null:
		_reveal_elapsed += maxf(delta, 0.0)
		if _reveal_elapsed >= REVEAL_SECONDS:
			_finish_language_reveal()
	if _world.meeting_in_progress():
		_elapsed = 0.0 # Freeze automatic ticks while the player is choosing at the meeting.
		_city.visual_fraction = 0.0
		_city.queue_redraw()
		return
	# Reconcile real scene proximity before advancing the next world tick.
	# A local pedestrian can hold the actual player taxi at a grounded zebra;
	# never stop the city clock, other NPCs or money settlement elsewhere.
	_sync_local_pedestrian()
	_elapsed += maxf(delta, 0.0)
	while _elapsed >= REAL_SECONDS_PER_STEP:
		_elapsed -= REAL_SECONDS_PER_STEP
		_update_player_crossing_yield()
		_world.advance(1)
		_render()
	# Nearby NPCs keep walking when the player's taxi is parked. The visual
	# fraction belongs to presentation time, NOT the player's travel state.
	_city.visual_fraction = 0.0 if not _world.route_hold_id.is_empty() else \
			clampf(_elapsed / REAL_SECONDS_PER_STEP, 0.0, 1.0)
	_city.queue_redraw()
	_sync_local_pedestrian()


func _on_meeting_selected(index: int) -> void:
	_selected_meeting_id = str(_meeting_selector.get_item_metadata(index))
	_render()


func _on_meeting_accept() -> void:
	_notice_text = "Appointment accepted; travel to the stated district before the deadline." if \
			_world.accept_meeting(_selected_meeting_id) else "Cannot confirm: the contact has other plans or the window passed."
	_render()


func _on_meeting_decline() -> void:
	_notice_text = "Invitation declined; no meeting was simulated." if \
			_world.decline_meeting(_selected_meeting_id) else "No pending invitation to decline."
	_render()


func _on_meeting_attend() -> void:
	if FileAccess.get_file_as_string(SandboxMeetingDialogue.STORY_PATH).is_empty() \
			or not _world.start_meeting(_selected_meeting_id):
		_notice_text = "Meet here at the actual time, while the contact is present and free."
		_render()
		return
	_conversation = null
	_meeting_dialogue = SandboxMeetingDialogue.new()
	if not _meeting_dialogue.open(_world, _selected_meeting_id, get_tree()):
		_meeting_dialogue = null
		_notice_text = "The meeting dialogue is unavailable."
	_render()
	_refresh_web_hitboxes_after_layout()


func _on_meeting_choice(index: int) -> void:
	if _meeting_dialogue == null or not _meeting_dialogue.choose(index, _world):
		_notice_text = "Meeting action invalid."
	else:
		var meeting: Dictionary = _world.meeting_by_id(_selected_meeting_id)
		_notice_text = "Off-duty meeting: %s. World time and trust were updated." % meeting["status"]
		_meeting_dialogue = null
	_render()


func _on_selected(index: int) -> void:
	_selected_id = str(_offers.get_item_metadata(index))
	_route_waypoint = ""
	_route_for_offer = _selected_id
	_render()


func _on_waypoint_selected(index: int) -> void:
	if index >= 0 and index < _via.item_count:
		_route_waypoint = str(_via.get_item_metadata(index))
		_render()


func _on_map_waypoint(district: String) -> void:
	var offer: Dictionary = _world.offer_by_id(
		_world.active_offer_id if not _world.active_offer_id.is_empty() else _selected_id)
	if offer.is_empty():
		return
	var start: String = str(offer["origin"])
	if not _world.active_offer_id.is_empty():
		start = _world.route_nodes[_world.route_segment + 1]
	var proposed: Array[String] = SandboxRoads.path(start, str(offer["destination"]), district)
	if SandboxRoads.valid_path(proposed):
		_route_waypoint = district
		_render()



func _on_apply_reroute() -> void:
	if _world.queue_reroute(_route_waypoint):
		_notice_text = "New remaining path queued: taxi will turn at the next junction."
	else:
		_notice_text = "No different legal route from the next junction, or insufficient funds."
	_render()


func _on_rider_answer(agree: bool) -> void:
	if _world.respond_rider_route(agree):
		_notice_text = "Passenger route request %s; relationship updated." % (
			"accepted" if agree else "declined")
	else:
		_notice_text = "Passenger request is unavailable or route cannot be funded."
	_render()


func _on_starter_device(device: String) -> void:
	if _world.select_starter_device(device):
		_notice_text = "Equipped %s. This only reveals its own kind of evidence." % device.to_upper()
		_conversation = null # Re-read live context on the next conversation.
	else:
		_notice_text = "Only one starter device per world; equipment already selected."
	_render()


func _on_drive_market() -> void:
	if _world.reposition("market"):
		_conversation = null
		_notice_text = "Drove along the city roads to the physical language stall."
	else:
		_notice_text = "Cannot travel to Market while busy, already there or without road funds."
	_render()


func _on_buy_module(language: String) -> void:
	_notice_text = "Bought %s module from the Market Linguist; install it from inventory." % language if \
			_world.buy_language_module(language) else "Go to the open market stall, check stock and credits."
	_render()


func _on_install_module(language: String) -> void:
	_notice_text = "Installed %s: whole-language access is now active." % language if \
			_world.install_language_module(language) else "Module not in inventory, already installed or currently busy."
	_conversation = null # The next NPC encounter uses the newly installed language access.
	_render()


func _on_language_locale(locale: String) -> void:
	if locale != "en" and locale != "ar":
		return
	_ui_locale = locale
	_render()


func _on_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if enabled and _reveal_pending:
		_finish_language_reveal()
	_render()


func _finish_language_reveal() -> void:
	if not _reveal_pending:
		return
	_reveal_pending = false
	_reveal_elapsed = 0.0
	_dialogue_text.text = _translated_text
	_dialogue_text.text_direction = Control.TEXT_DIRECTION_RTL if _ui_locale == "ar" else Control.TEXT_DIRECTION_LTR
	_dialogue_text.remove_theme_font_override("font")
	if _ui_locale == "ar":
		_dialogue_text.add_theme_font_override("font", load(ARABIC_FONT))
	_skip_translation.visible = false
	_publish_reveal_web()
	if _player_ui!=null: _player_ui.sync()
	# Hiding Skip collapses its VBox slot and moves every Ink choice.
	# Republish *after* Godot lays out the frame so Web clicks cannot hit
	# an obsolete pre-reveal position.
	if OS.has_feature("web"):
		call_deferred("_publish_language_web")


func _publish_reveal_web() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
				"Object.assign(document.documentElement.dataset,%s)" % JSON.stringify({
					"sandboxDialogueText": _dialogue_text.text,
					"sandboxRevealPending": str(_reveal_pending).to_lower()
				}), true)



func _on_buy_ar() -> void:
	_notice_text = "Bought optics at Market; wear them to inspect learned facts." if \
			_world.buy_ar() else "AR eyewear requires 5 cr, Market hours and no active ride."
	_render()


func _on_wear_ar() -> void:
	var equip: bool = not _world.ar_equipped
	_notice_text = ("AR eyewear equipped." if equip else "AR eyewear removed.") if \
			_world.set_ar_equipped(equip) else "No eyewear available to change."
	_render()


func _on_ask_rumor() -> void:
	if _conversation == null or not _conversation.understood() \
			or not _world.hear_rumor(_conversation.offer_id):
		_notice_text = "No comprehensible, source-backed local news from this speaker."
	else:
		_notice_text = "Heard a second-hand claim from this resident. It remains unverified."
	_render()


func _show_ar_hint() -> void:
	if not _world.ar_equipped or _ar_note.is_empty() or not _ar_context.visible:
		return
	_ar_title.text = "AR / UNVERIFIED RUMOR" if _ar_note["certainty"] == "unverified" else "AR / VERIFIED NOTE"
	_ar_text.text = "%s\nSource: %s" % [str(_ar_note["text"]), str(_ar_note["source"])]
	_ar_panel.visible = true
	_publish_ar_web()
	# This popup is normally hidden; its Close button has no final geometry
	# until Godot lays out a visible frame. Publish post-layout Web hitboxes.
	if OS.has_feature("web"):
		call_deferred("_publish_language_web")


func _close_ar_hint() -> void:
	_ar_panel.visible = false
	_publish_ar_web()


func _unhandled_key_input(event: InputEvent) -> void:
	if _ar_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_ar_hint()
		get_viewport().set_input_as_handled()


func _publish_ar_web() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("Object.assign(document.documentElement.dataset,%s)" % JSON.stringify({
		"sandboxAROwned": str(_world.ar_owned).to_lower(),
		"sandboxAREquipped": str(_world.ar_equipped).to_lower(),
		"sandboxARHint": str(_ar_context.visible).to_lower(),
		"sandboxAROverlay": str(_ar_panel.visible).to_lower(),
		"sandboxARHintText": _ar_text.text if _ar_panel.visible else "",
		"sandboxARHintCertainty": str(_ar_note.get("certainty", "")),
		"sandboxARHintSource": str(_ar_note.get("source", "")),
		"sandboxRumorAvailable": str(_ask_rumor.visible).to_lower()
	}), true)


func _on_ask_common() -> void:
	if _conversation == null or not _conversation.request_common(_world, get_tree()):
		_notice_text = "Cannot request Common from this speaker right now."
	else:
		_notice_text = "Speaker switched to Common." if _conversation.understood() else \
				"The speaker could not or would not switch to Common."
	_render()


func _on_talk() -> void:
	var conversation: SandboxConversation = SandboxConversation.new()
	if not conversation.open(_world, _world.active_offer_id if not _world.active_offer_id.is_empty() else _selected_id, get_tree()):
		_notice_text = "Speak locally to an available resident; no valid offer here."
		_render()
		return
	_conversation = conversation
	_last_intent = "request_trip"
	_last_outcome = ""
	_notice_text = "The resident is speaking."
	_render()


func _on_dialogue_choice(index: int) -> void:
	if _conversation == null or not _conversation.choose(index, _world, _route_waypoint):
		_notice_text = "That request is no longer valid."
		_conversation = null
		_last_outcome = "invalid"
		_render()
		return
	var frame: Dictionary = _conversation.current_frame()
	for tag in frame.get("tags", []):
		if str(tag).begins_with("intent:"):
			_last_intent = str(tag).trim_prefix("intent:")
	if _conversation.is_finished():
		_last_outcome = _conversation.outcome()
		_notice_text = {"accepted":"Passenger aboard. Following your selected route.","declined":"You pass on this fare.","quiet":"You give the passenger a quiet ride.","blocked":"You cannot take this fare right now."}.get(_last_outcome,"Conversation ended.")
		_conversation = null
	_render()


func _on_accept() -> void:
	if _world.accept(_selected_id, _route_waypoint):
		_conversation = null
		_last_outcome = "accepted"
		_notice_text = "Passenger aboard. Following your selected route."
	else:
		_notice_text = "Not accessible: travel to origin or avoid licensed dispatch."
	_render()


func _on_decline() -> void:
	if _world.decline(_selected_id):
		_conversation = null
		_last_outcome = "declined"
		_notice_text = "You pass on this fare."
	_render()


func _on_reposition() -> void:
	var destination: String = SandboxRoads.DISTRICTS[_districts.get_selected_id()]
	if _world.reposition(destination):
		_conversation = null
		_notice_text = "On the way. The city carries on around you."
	else:
		_notice_text = "Cannot move: already here, busy or insufficient credits."
	_render()


func _on_wait() -> void:
	_world.advance(20)
	_notice_text = "20 minutes passed. NPC needs and dispatch changed."
	_render()


func _on_observe() -> void:
	_world.advance(360)
	_notice_text = "Six simulated hours passed; independent residents continued their lives."
	_render()


# Local native Godot navigation runs only for a genuine resident in the garage
# vicinity. It is one shared world, not an alternate passenger simulator.
func _update_player_crossing_yield() -> void:
	if not _world.route_hold_id.is_empty():
		if _street_pilot==null or _street_pilot.world_reported_arrival \
				or _street_pilot.pedestrian.crossing_completed:
			_world.release_crossing_yield()
		return
	if _street_pilot!=null and _street_pilot.pedestrian.crossing_reserved \
			and not _street_pilot.pedestrian.crossing_completed \
			and SandboxStreetRouteBinding.approaching(_world):
		_world.begin_crossing_yield()


func _sync_local_pedestrian() -> void:
	var visible_neighborhood: bool=SandboxStreetRouteBinding.in_neighborhood(_world)
	if not visible_neighborhood:
		if _street_pilot != null:
			if not _street_pilot.world_reported_arrival:
				var phase: float=SandboxStreetModule.progress_of(_street_pilot.pedestrian.position)
				if SandboxLocalPedestrianTrip.handoff(_world,_street_pilot.walking_npc_id,phase):
					_street_restore_state.clear()
			_street_pilot.queue_free()
			_street_pilot=null
			_city.local_active_npc_id=""
		return
	if _street_pilot != null:
		return
	var npc_id: String=SandboxLocalPedestrianTrip.candidate(_world)
	if npc_id.is_empty():
		return
	var trip: Dictionary=_world.resident(npc_id).get("local_pedestrian_trip",{})
	if trip.get("status","")=="offscreen":
		var phase: float=SandboxLocalPedestrianTrip.resume(_world,npc_id)
		if phase<0.0:
			return
		_street_restore_state={
			"npc_id":npc_id,
			"pedestrian_x":SandboxStreetModule.position_at(phase).x,
			"pedestrian_y":SandboxStreetModule.position_at(phase).y,
			"car_x":SandboxStreetModule.VEHICLE_START.x,
			"car_y":SandboxStreetModule.VEHICLE_START.y,
			"crossing_reserved":SandboxStreetModule.crossing_started(phase),
			"crossing_completed":SandboxStreetModule.crossing_finished(phase),
			"did_arrive":false}
	var local: SandboxStreetPilot=SandboxStreetPilot.new()
	local.name="PatchworksStreetTraffic"
	local.embedded=true
	local.world=_world
	local.walking_npc_id=npc_id
	local.resume_state=_street_restore_state.duplicate(true)
	# Author the crossing on the actual route-graph edge and in the actual
	# ground plane; no unrelated screen-space fake crossing.
	local.transform=SandboxStreetRouteBinding.street_transform()
	local.z_index=5
	_street_pilot=local
	_city.local_active_npc_id=npc_id
	add_child(local)
	_street_restore_state.clear()

func _reset_local_pedestrian() -> void:
	if _street_pilot != null:
		_street_pilot.queue_free()
		_street_pilot = null
	_street_restore_state.clear()
	_city.local_active_npc_id=""


func _on_new_seed() -> void:
	_reset_local_pedestrian()
	_world = SandboxWorld.new(_world.seed + 1)
	_conversation = null
	_last_intent = ""
	_last_outcome = ""
	_city.world = _world
	_selected_id = ""
	_route_waypoint = ""
	_route_for_offer = ""
	_selected_meeting_id = ""
	_meeting_dialogue = null
	_elapsed = 0.0
	_notice_text = "Fresh independent simulated city seed."
	_render()


func _on_save() -> void:
	var dialogue_snapshot: Dictionary = _conversation.snapshot() if _conversation != null else {}
	_notice_text = "Sandbox saved." if SandboxSave.save_world(_world, SandboxSave.PATH, dialogue_snapshot, {"clock_fraction":_elapsed,"locale":_ui_locale,"reduced_motion":_reduced_motion,
			"street_state": _street_pilot.visual_snapshot() if _street_pilot != null else {}}) else "Save failed."
	_render()


func _on_load() -> void:
	var bundle: Dictionary = SandboxSave.load_bundle()
	if bundle.is_empty():
		_notice_text = "No valid sandbox save."
		_render()
		return
	var saved: SandboxWorld = bundle["world"] as SandboxWorld
	var restored: SandboxConversation = null
	var dialogue_state: Dictionary = bundle["dialogue"]
	if not dialogue_state.is_empty():
		restored = SandboxConversation.new()
		if not restored.restore(saved, dialogue_state, get_tree()):
			_notice_text = "Save has an invalid or expired conversation."
			_render()
			return
	_reset_local_pedestrian()
	_world = saved
	_city.world = saved
	_street_restore_state = bundle.get("presentation",{}).get("street_state",{}).duplicate(true)
	_conversation = restored
	_selected_id = restored.offer_id if restored != null else ""
	_route_for_offer = _selected_id
	_selected_meeting_id = ""
	_meeting_dialogue = null
	_route_waypoint = ""
	_elapsed = float(bundle.get("presentation",{}).get("clock_fraction",0.0))
	_city.visual_fraction=_elapsed
	_ui_locale=str(bundle.get("presentation",{}).get("locale",_ui_locale))
	_reduced_motion=bool(bundle.get("presentation",{}).get("reduced_motion",_reduced_motion))
	_last_intent = "restored" if restored != null else ""
	_last_outcome = ""
	_notice_text = "World, NPC and live dialogue restored."
	_render()
	_sync_local_pedestrian()
	_refresh_web_hitboxes_after_layout()


func _render() -> void:
	_render_debug()
	if _player_ui != null: _player_ui.sync()


func _render_debug() -> void:
	if _conversation != null and not _conversation.still_valid(_world):
		_conversation = null
		_last_outcome = "expired"
		_notice_text = "That NPC request has expired or the speaker left."
	_city.queue_redraw()
	var clock_hour: int = (int(_world.minute) % 1440) / 60
	var clock_minute: int = int(_world.minute) % 60
	_status.text = "DISTRICT %s  |  WALLET %d cr  |  EXPOSURE %d" % [
		_world.player_district.to_upper(), _world.credits, _world.risk
	]
	_clock.text = "DAY %d  %02d:%02d  |  SEED %d  |  %d NPCs" % [
		int(_world.minute / 1440) + 1, clock_hour, clock_minute,
		_world.seed, _world.residents.size()
	]
	_offers.clear()
	var available: Array[Dictionary] = _world.open_offers()
	for offer in available:
		var locked: String = "[LICENSE]" if offer["channel"] == "official" else "[%s]" % str(offer["channel"]).to_upper()
		var line: String = "%s  %s > %s  %d cr  (%s)" % [
			locked, offer["origin"], offer["destination"], offer["fare"], offer["npc_id"]
		]
		_offers.add_item(line)
		_offers.set_item_metadata(_offers.item_count - 1, str(offer["id"]))
	if available.size() > 0:
		if _selected_id.is_empty() or _world.offer_by_id(_selected_id).get("status") != "open" \
				or _world.offer_by_id(_selected_id).get("origin") != _world.player_district:
			# On arrival, focus a *real accessible local request* if one exists.
			_selected_id = str(available[0]["id"])
			for offer in available:
				if offer["origin"] == _world.player_district and offer["channel"] != "official":
					_selected_id = str(offer["id"])
					break
		for i in range(_offers.item_count):
			if _offers.get_item_metadata(i) == _selected_id:
				_offers.select(i)
				break
	else:
		_selected_id = ""
	if _route_for_offer != _selected_id:
		_route_for_offer = _selected_id
		_route_waypoint = ""
	var chosen: Dictionary = _world.offer_by_id(_selected_id)
	var npc: Dictionary = _world.resident(str(chosen.get("npc_id", "")))
	var eligible: bool = not chosen.is_empty() and chosen["origin"] == _world.player_district \
			and chosen["channel"] != "official" and not _world.is_travelling()
	_accept.disabled = not eligible
	_talk.disabled = chosen.is_empty() or chosen["origin"] != _world.player_district \
			or not _world.active_offer_id.is_empty()
	_decline.disabled = chosen.is_empty()
	_reposition.disabled = not _world.active_offer_id.is_empty()
	if chosen.is_empty():
		_details.text = "No active offers. Time advances independently; Wait +20m to observe change."
	else:
		_details.text = "PURPOSE %s | NEED %d | CASH %d | LANGUAGE %s | EXPIRES IN %dm" % [
			chosen["purpose"], npc["need"], npc["cash"], npc["language"],
			maxi(0, int(chosen["expires_at"]) - _world.minute)
		]
	if not npc.is_empty() and SandboxDriverMemory.recognizes(npc):
		_details.text += " | RETURNING CAB"
	_notice.text = _notice_text
	_render_route_picker(chosen)
	_gear_panel.visible = true
	_ar_buy.disabled = _world.ar_owned or _world.player_district != "market" \
			or not SandboxKnowledge.market_open(_world.minute) or _world.credits < SandboxWorld.AR_PRICE \
			or _world.is_travelling() or _world.meeting_in_progress()
	_ar_wear.disabled = not _world.ar_owned
	_ar_wear.text = "Remove AR" if _world.ar_equipped else "Wear AR"
	var gear_selected: bool = not _world.starter_device.is_empty()
	_gps.disabled = gear_selected
	_translator.disabled = gear_selected
	_radio.disabled = gear_selected
	var stall: bool = _world.player_district == "market" and SandboxKnowledge.market_open(_world.minute) \
			and not _world.is_travelling() and not _world.meeting_in_progress()
	_drive_market.disabled = _world.player_district == "market" or \
			not _world.active_offer_id.is_empty() or _world.meeting_in_progress() \
			or _world.credits < SandboxRoads.hops(_world.player_district, "market")
	_buy_local.disabled = not stall or _world.modules_owned.has("local") \
			or int(_world.market_stock["local"]) == 0 or _world.credits < 8
	_buy_cant.disabled = not stall or _world.modules_owned.has("cant") \
			or int(_world.market_stock["cant"]) == 0 or _world.credits < 9
	_install_local.disabled = _world.is_travelling() or not _world.modules_owned.has("local") or _world.modules_installed.has("local")
	_install_cant.disabled = _world.is_travelling() or not _world.modules_owned.has("cant") or _world.modules_installed.has("cant")
	match _world.starter_device:
		"gps":
			_gear_info.text = "GPS active: district graph known. To %s: %d road hops." % [
				str(chosen.get("destination", _world.player_district)),
				SandboxRoads.hops(_world.player_district, str(chosen.get("destination", _world.player_district)))
			]
		"module:local":
			_gear_info.text = "Bonus: Local language module installed. Common and Local understood."
		"radio":
			_gear_info.text = "Alien radio: 'Sha-ruu ... vekk nai ...' (no translation; local signal pattern recognized)."
		_:
			_gear_info.text = "Choose GPS, Local module or Radio. Common is preinstalled."
	_gear_info.text += " | Owned %s | Installed %s" % [
		", ".join(_world.modules_owned), ", ".join(_world.modules_installed)
	]
	if not stall:
		_gear_info.text += " | Travel to Market 06:00–20:00 to buy."
	_render_meetings()
	_dialogue_panel.visible = _conversation != null and not _meeting_panel.visible
	# The equipment stall requires more vertical space; an active Ink or
	# off-duty scene must never be occluded by the route controls.
	_route_panel.visible = not _dialogue_panel.visible and not _meeting_panel.visible
	for button in _dialogue_choices.get_children():
		button.queue_free()
	if _conversation != null:
		var speaker_offer: Dictionary = _world.offer_by_id(_conversation.offer_id)
		var speaker: Dictionary = _world.resident(str(speaker_offer.get("npc_id", "")))
		var language: String = _conversation.spoken_language(_world)
		_dialogue_title.text = ("%s | %s | %s" % [
			str(speaker["id"]), language.to_upper(),
			"مترجم" if _conversation.understood() else "غير مترجم"
		]) if _ui_locale == "ar" else ("SPEAKING | %s | %s | %s" % [
			str(speaker["id"]), language.to_upper(),
			"translated" if _conversation.understood() else "untranslated"
		])
		var frame: Dictionary = _conversation.current_frame()
		_request_common.visible = not _conversation.understood() \
				and not _world.common_requests.has(_conversation.offer_id) \
				and frame.get("tags", []).has("intent:request_trip")
		_ask_rumor.visible = _conversation.understood() \
				and not _world.rumor_candidate(_conversation.offer_id).is_empty()
		_ask_rumor.text = "اسأل عن أخبار الحي" if _ui_locale == "ar" else "Ask about local gossip"
		if _ui_locale == "ar":
			_ask_rumor.add_theme_font_override("font", load(ARABIC_FONT))
		else:
			_ask_rumor.remove_theme_font_override("font")
		_ar_note = SandboxARHints.contextual(_world, frame, speaker_offer, _conversation.understood())
		_ar_context.visible = not _ar_note.is_empty()
		_ar_context.text = "AR: %s" % str(_ar_note.get("term", ""))
		_ar_context.tooltip_text = "%s\n%s" % [
			str(_ar_note.get("text", "")), str(_ar_note.get("source", ""))]
		if not _ar_context.visible:
			_ar_panel.visible = false
		_update_dialogue_presentation(frame, speaker_offer, speaker, language)
		var choices: Array = frame.get("choices", [])
		for i in range(choices.size()):
			var button: Button = Button.new()
			button.text = SandboxLanguagePresentation.localized_choice(str(choices[i]), _ui_locale)
			button.custom_minimum_size = Vector2(0, 32)
			if _ui_locale == "ar":
				button.add_theme_font_override("font", load(ARABIC_FONT))
				button.text_direction = Control.TEXT_DIRECTION_RTL
			button.pressed.connect(_on_dialogue_choice.bind(i))
			_dialogue_choices.add_child(button)
	if _conversation == null:
		_ar_note = {}
		_ar_panel.visible = false
		_ar_context.visible = false
		_ask_rumor.visible = false
		_speech_identity = ""
		_reveal_pending = false
		_request_common.visible = false
		_skip_translation.visible = false
	var phase: String = "enroute" if not _world.active_offer_id.is_empty() else "seeking"
	var departed: int = _count_events("npc_alternative_departed")
	var arrived: int = _count_events("npc_alternative_arrived")
	var peer_count: int = _count_events("npc_peer_contact")
	var peer_facts: int = 0
	var recent_contact: String = "No witnessed peer contact yet"
	for resident in _world.residents:
		peer_facts += resident["peer_knowledge"].size()
	for j in range(_world.events.size() - 1, -1, -1):
		var peer_event: Dictionary = _world.events[j]
		if peer_event["kind"] == "npc_peer_contact":
			recent_contact = "%s met %s at %s" % [
				peer_event["subject"], peer_event["detail"]["recipient"],
				peer_event["detail"]["district"]
			]
			break
	var known_drivers: int = 0
	for resident in _world.residents:
		if SandboxDriverMemory.recognizes(resident):
			known_drivers += 1
	var returning_index: int = -1
	for i in range(available.size()):
		var offer: Dictionary = available[i]
		if offer["origin"] == _world.player_district and offer["channel"] != "official" \
				and SandboxDriverMemory.recognizes(_world.resident(str(offer["npc_id"]))):
			returning_index = i
			break
	var working: int = _count_activity("working")
	var resting: int = _count_activity("resting")
	var moving: int = _count_activity("travelling")
	var recent: String = "No independent trips yet"
	for j in range(_world.events.size() - 1, -1, -1):
		var event: Dictionary = _world.events[j]
		if str(event["kind"]).begins_with("npc_alternative_"):
			recent = "%s %s" % [str(event["subject"]), str(event["kind"]).trim_prefix("npc_alternative_")]
			break
	_world_info.text = "LIVING CITY\nOFFERS %d / %d\nNPCs %d | KNOWN CABS %d\nWORKING %d  RESTING %d\nTRAVELLING %d\nALT DEPARTURES %d\nALT ARRIVALS %d\nPEER CONTACTS %d | PEER FACTS %d\nEVENTS %d\n%s\n%s\nSTATUS %s" % [
		available.size(), _world.offers.size(), _world.residents.size(), known_drivers,
		working, resting, moving, departed, arrived, peer_count, peer_facts,
		_world.events.size(), recent_contact, recent, phase.to_upper()
	]
	if not _world.active_offer_id.is_empty():
		var route: Dictionary = _world.offer_by_id(_world.active_offer_id)
		_notice.text = "ON ROUTE  %s -> %s  |  %dm remaining  |  edge %d/%d" % [
			route["origin"], route["destination"], _world.remaining_minutes,
			_world.route_segment + 1, _world.route_nodes.size() - 1
		]
	if OS.has_feature("web"):
		var web_state: String = "Object.assign(document.documentElement.dataset,{sandboxReady:'true',sandboxSeed:'%d',sandboxOffers:'%d',sandboxResidents:'%d',sandboxEvents:'%d',sandboxCredits:'%d',sandboxRisk:'%d',sandboxPhase:'%s',sandboxDistrict:'%s',sandboxSelected:'%s',sandboxAccepted:'%s',sandboxSettlements:'%d',sandboxDialogue:'%s',sandboxDialogueChoices:'%d',sandboxDialogueUnderstood:'%s',sandboxDialogueOffer:'%s',sandboxDialogueIntent:'%s',sandboxDialogueOutcome:'%s',sandboxDialogueText:%s,sandboxDevice:'%s',sandboxKnowledge:'%d',sandboxSelectedLanguage:%s,sandboxOwned:%s,sandboxInstalled:%s,sandboxMarketStock:%s,sandboxCommonRequested:'%s',sandboxMarketOpen:'%s',sandboxGearInfo:%s,sandboxAltDepartures:'%d',sandboxAltArrivals:'%d',sandboxWorkers:'%d',sandboxResting:'%d',sandboxNpcMoving:'%d',sandboxRouteNodes:%s,sandboxRouteSegment:'%d',sandboxRouteElapsed:'%d',sandboxRouteWaypoint:'%s',sandboxRoutePreview:%s,sandboxPendingRoute:%s,sandboxRiderStatus:'%s',sandboxRiderVia:'%s',sandboxRiderTrust:'%d',sandboxReplanEnabled:'%s',sandboxRiderInfo:%s,sandboxPeerContacts:'%d',sandboxPeerFacts:'%d',sandboxPeerLast:%s,sandboxKnownCabs:'%d',sandboxReturningIndex:'%d',sandboxSelectedRecognizes:'%s',sandboxSelectedMemories:'%d',sandboxDialogueRecognizes:'%s'})" % [
			_world.seed, available.size(), _world.residents.size(), _world.events.size(),
			_world.credits, _world.risk, phase, _world.player_district,
			_selected_id, str(not _accept.disabled).to_lower(), _settled_count(),
			str(_conversation != null).to_lower(),
			_conversation.current_frame().get("choices", []).size() if _conversation != null else 0,
			str(_conversation.understood()).to_lower() if _conversation != null else "false",
			_conversation.offer_id if _conversation != null else "",
			_last_intent, _last_outcome, JSON.stringify(_dialogue_text.text if _conversation != null else ""),
			_world.starter_device, _world.knowledge.size(), JSON.stringify(str(npc.get("language", ""))),
			JSON.stringify(JSON.stringify(_world.modules_owned)), JSON.stringify(JSON.stringify(_world.modules_installed)),
			JSON.stringify(JSON.stringify(_world.market_stock)),
			str(_world.common_requests.has(_conversation.offer_id)).to_lower() if _conversation != null else "false",
			str(stall).to_lower(), JSON.stringify(_gear_info.text), departed, arrived, working, resting, moving,
			JSON.stringify(_world.route_nodes), _world.route_segment, _world.route_edge_elapsed,
			_route_waypoint, JSON.stringify(_route_preview.text),
			JSON.stringify(_world.pending_route_nodes),
			str(_world.rider_route_request.get("status", "")),
			str(_world.rider_route_request.get("via", "")),
			int(_world.resident(str(_world.offer_by_id(_world.active_offer_id).get("npc_id", ""))).get("trust", 0)),
			str(not _apply_route.disabled).to_lower(), JSON.stringify(_rider_info.text),
			peer_count, peer_facts, JSON.stringify(recent_contact),
			known_drivers, returning_index,
			str(not npc.is_empty() and SandboxDriverMemory.recognizes(npc)).to_lower(),
			npc.get("driver_memories", []).size(),
			str(_conversation.recognizes_driver()).to_lower() if _conversation != null else "false"
		]
		JavaScriptBridge.eval(web_state, true)
		_publish_ar_web()
		JavaScriptBridge.eval("Object.assign(document.documentElement.dataset,%s)" % JSON.stringify({
			"sandboxUILocale": _ui_locale,
			"sandboxRevealPending": str(_reveal_pending).to_lower(),
			"sandboxGlyphText": _source_text if _conversation != null else "",
			"sandboxChoiceLabels": JSON.stringify(
				_dialogue_choices.get_children().map(func(c: Node) -> String: return str(c.text)))
		}), true)
		_expose_meeting_web()
		call_deferred("_publish_language_web")



func _update_dialogue_presentation(frame: Dictionary, offer: Dictionary, speaker: Dictionary,
		language: String) -> void:
	var rtl: bool = _ui_locale == "ar"
	_dialogue_panel.layout_direction = Control.LAYOUT_DIRECTION_RTL if rtl else Control.LAYOUT_DIRECTION_LTR
	_dialogue_text.text_direction = Control.TEXT_DIRECTION_RTL if rtl else Control.TEXT_DIRECTION_LTR
	_dialogue_title.text_direction = Control.TEXT_DIRECTION_RTL if rtl else Control.TEXT_DIRECTION_LTR
	_locale_en.disabled = not rtl
	_locale_ar.disabled = rtl
	_reduce_motion.text = "تقليل الحركة" if rtl else "Reduced motion"
	_request_common.text = "اطلب التحدث باللغة المشتركة" if rtl else "Ask to speak Common"
	_skip_translation.text = "اعرض الترجمة الآن" if rtl else "Show translation now"
	var arabic_font: Font = load(ARABIC_FONT) as Font
	for control in [_dialogue_title, _request_common, _reduce_motion, _skip_translation]:
		if rtl:
			control.add_theme_font_override("font", arabic_font)
		else:
			control.remove_theme_font_override("font")
	var stamp: String = "%d|%s|%s|%s|%s" % [
		_conversation.get_instance_id(), _conversation.offer_id, JSON.stringify(frame),
		_ui_locale, str(_conversation.understood())
	]
	if stamp != _speech_identity:
		_speech_identity = stamp
		_source_text = SandboxLanguagePresentation.source_line(language,
				SandboxLanguagePresentation.speech_key(frame, speaker))
		_translated_text = SandboxLanguagePresentation.localized_line(frame, speaker, offer, _ui_locale) \
				if _conversation.understood() else ""
		_reveal_elapsed = 0.0
		_reveal_pending = _conversation.understood() and not _source_text.is_empty() \
				and not _reduced_motion
	_dialogue_text.text = _source_text if _reveal_pending else (
			_translated_text if _conversation.understood() else str(frame.get("text", "")))
	# Alien scripts retain their native left-to-right reading order even when
	# the player's surrounding interface is Arabic RTL.
	_dialogue_text.text_direction = Control.TEXT_DIRECTION_LTR if (
			_reveal_pending or not _conversation.understood()) else (
			Control.TEXT_DIRECTION_RTL if rtl else Control.TEXT_DIRECTION_LTR)
	_skip_translation.visible = _reveal_pending
	_dialogue_text.remove_theme_font_override("font")
	var glyph_font: String = SandboxLanguagePresentation.native_font_path(language)
	if _reveal_pending or (not _conversation.understood() and not glyph_font.is_empty()):
		_dialogue_text.add_theme_font_override("font", load(glyph_font))
	elif rtl:
		_dialogue_text.add_theme_font_override("font", arabic_font)


func _publish_language_web() -> void:
	if not OS.has_feature("web"):
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var ink_accept: Vector2 = Vector2.ZERO
	if _dialogue_panel.visible and _dialogue_choices.get_child_count() >= 2:
		var ink_button: Button = _dialogue_choices.get_child(1) as Button
		if ink_button != null and not ink_button.is_queued_for_deletion():
			ink_accept = ink_button.get_global_rect().get_center()
	var values: Dictionary = {
		"sandboxInkAcceptPoint": ink_accept,
		"sandboxBuyLocalPoint": _buy_local.get_global_rect().get_center(),
		"sandboxBuyCantPoint": _buy_cant.get_global_rect().get_center(),
		"sandboxInstallLocalPoint": _install_local.get_global_rect().get_center(),
		"sandboxInstallCantPoint": _install_cant.get_global_rect().get_center(),
		"sandboxCommonPoint": _request_common.get_global_rect().get_center(),
		"sandboxMarketTravelPoint": _drive_market.get_global_rect().get_center(),
		"sandboxHonorRiderPoint": _honor.get_global_rect().get_center(),
		"sandboxRefuseRiderPoint": _refuse.get_global_rect().get_center(),
		"sandboxDistrictPoint": _districts.get_global_rect().get_center(),
		"sandboxRepositionPoint": _reposition.get_global_rect().get_center(),
		"sandboxOfferTalkPoint": _talk.get_global_rect().get_center(),
		"sandboxARBuyPoint": _ar_buy.get_global_rect().get_center(),
		"sandboxARWearPoint": _ar_wear.get_global_rect().get_center(),
		"sandboxARContextPoint": _ar_context.get_global_rect().get_center(),
		"sandboxStarterGPSPoint": _gps.get_global_rect().get_center(),
		"sandboxInkAskPoint": _dialogue_choices.get_child(0).get_global_rect().get_center() \
				if _dialogue_panel.visible and _dialogue_choices.get_child_count() > 0 \
				else Vector2.ZERO,
		"sandboxARClosePoint": _ar_close.get_global_rect().get_center(),
		"sandboxAskRumorPoint": _ask_rumor.get_global_rect().get_center(),
		"sandboxLocaleEnglishPoint": _locale_en.get_global_rect().get_center(),
		"sandboxLocaleArabicPoint": _locale_ar.get_global_rect().get_center(),
		"sandboxReducedMotionPoint": _reduce_motion.get_global_rect().get_center(),
		"sandboxSkipRevealPoint": _skip_translation.get_global_rect().get_center()
	}
	var payload: Dictionary = {}
	for key in values:
		var pos: Vector2 = values[key]
		payload[key] = JSON.stringify([roundi(pos.x), roundi(pos.y)])
	JavaScriptBridge.eval("Object.assign(document.documentElement.dataset,%s)" % JSON.stringify(payload), true)
	# Save/Load are laid out inside DockPanel after _render, just like Ink
	# choices. Refresh their coordinates and persisted-save availability here.
	_expose_meeting_web()


func _render_meetings() -> void:
	_meeting_selector.clear()
	var idx: int = 0
	var selected: int = -1
	for meeting in _world.meetings:
		_meeting_selector.add_item("%s / %s" % [meeting["npc_id"], meeting["status"]])
		_meeting_selector.set_item_metadata(idx, str(meeting["id"]))
		if meeting["id"] == _selected_meeting_id:
			selected = idx
		idx += 1
	if selected < 0 and idx > 0:
		selected = 0
		_selected_meeting_id = str(_meeting_selector.get_item_metadata(0))
	if selected >= 0:
		_meeting_selector.select(selected)
	var meeting: Dictionary = _world.meeting_by_id(_selected_meeting_id)
	if meeting.is_empty():
		_meeting_info.text = "Repeat genuine rides can lead to an invitation. No contacts yet."
		_meeting_accept.disabled = true
		_meeting_decline.disabled = true
		_meeting_attend.disabled = true
		_meeting_panel.visible = false
		return
	var npc: Dictionary = _world.resident(str(meeting["npc_id"]))
	var slot: int = int(meeting["slot"])
	_meeting_info.text = "%s | %s\n%s  Day %d %02d:%02d\nWindow +%dm | %s" % [
		meeting["npc_id"], meeting["status"], str(meeting["location"]).capitalize(),
		int(slot / 1440) + 1, (slot % 1440) / 60, slot % 60,
		SandboxMeetings.WINDOW_MINUTES,
		"Present" if npc.get("location") == meeting["location"] else "Elsewhere"
	]
	var invited: bool = meeting["status"] == "invited"
	_meeting_accept.disabled = not invited or _world.minute >= slot \
			or not _world.active_offer_id.is_empty()
	_meeting_decline.disabled = not invited
	_meeting_attend.disabled = meeting["status"] != "accepted" \
			or _world.player_district != meeting["location"] \
			or _world.minute < slot or _world.minute > int(meeting["deadline"]) \
			or not _world.active_offer_id.is_empty() \
			or npc.get("location") != meeting["location"] or npc.get("activity") != "available"
	_meeting_panel.visible = meeting["status"] == "in_progress"
	if not _meeting_panel.visible:
		_meeting_dialogue = null
		return
	if _meeting_dialogue == null or _meeting_dialogue.meeting_id != _selected_meeting_id:
		_meeting_dialogue = SandboxMeetingDialogue.new()
		if not _meeting_dialogue.open(_world, _selected_meeting_id, get_tree()):
			_meeting_dialogue = null
			_meeting_text.text = "Cannot load off-duty Ink dialogue."
			return
	_meeting_stage.venue = str(meeting["location"])
	_meeting_stage.companion = str(meeting["npc_id"])
	_meeting_stage.queue_redraw()
	_meeting_title.text = "OFF DUTY  |  %s  |  %s" % [
		str(meeting["location"]).to_upper(), str(meeting["npc_id"])]
	_meeting_text.text = str(_meeting_dialogue.current_frame().get("text", ""))
	for child in _meeting_choices.get_children():
		child.queue_free()
	var choices: Array = _meeting_dialogue.current_frame().get("choices", [])
	for i in range(choices.size()):
		var button: Button = Button.new()
		button.text = str(choices[i])
		button.pressed.connect(_on_meeting_choice.bind(i))
		_meeting_choices.add_child(button)


func _refresh_web_hitboxes_after_layout() -> void:
	# Godot Control geometry is finalized in a later frame. Prevent publishing
	# zero-sized/stale interaction targets immediately after scene restoration.
	if not OS.has_feature("web"):
		return
	await get_tree().process_frame
	if is_inside_tree() and _meeting_panel.visible:
		_expose_meeting_web()


func _expose_meeting_web() -> void:
	if OS.has_feature("web"):
		var active_meeting: Dictionary = _world.meeting_by_id(_selected_meeting_id)
		var accept_center: Vector2 = _meeting_accept.get_global_rect().get_center()
		var attend_center: Vector2 = _meeting_attend.get_global_rect().get_center()
		var save_center: Vector2 = ($HUD/DockPanel/Content/Persistence/Save as Button).get_global_rect().get_center()
		var load_center: Vector2 = ($HUD/DockPanel/Content/Persistence/Load as Button).get_global_rect().get_center()
		var choice_center: Vector2 = Vector2.ZERO
		if _meeting_choices.get_child_count() > 0:
			choice_center = (_meeting_choices.get_child(0) as Button).get_global_rect().get_center()
		var state: String = "Object.assign(document.documentElement.dataset,{sandboxMinute:'%d',sandboxMeetingCount:'%d',sandboxMeetingId:%s,sandboxMeetingStatus:%s,sandboxMeetingLocation:%s,sandboxMeetingSlot:'%d',sandboxMeetingDeadline:'%d',sandboxMeetingAtVenue:'%s',sandboxMeetingChoices:'%d',sandboxMeetingText:%s,sandboxMeetingAcceptPoint:%s,sandboxMeetingAttendPoint:%s,sandboxMeetingChoicePoint:%s,sandboxSavePoint:%s,sandboxLoadPoint:%s,sandboxSaveExists:'%s',sandboxSaveBytes:'%d',sandboxNotice:%s})" % [
			_world.minute, _world.meetings.size(), JSON.stringify(_selected_meeting_id),
			JSON.stringify(str(active_meeting.get("status", ""))),
			JSON.stringify(str(active_meeting.get("location", ""))),
			int(active_meeting.get("slot", 0)), int(active_meeting.get("deadline", 0)),
			str(not _meeting_attend.disabled).to_lower(),
			_meeting_dialogue.current_frame().get("choices", []).size() if _meeting_dialogue != null else 0,
			JSON.stringify(_meeting_text.text if _meeting_panel.visible else ""),
			JSON.stringify(JSON.stringify([roundi(accept_center.x), roundi(accept_center.y)])),
			JSON.stringify(JSON.stringify([roundi(attend_center.x), roundi(attend_center.y)])),
			JSON.stringify(JSON.stringify([roundi(choice_center.x), roundi(choice_center.y)])),
			JSON.stringify(JSON.stringify([roundi(save_center.x), roundi(save_center.y)])),
			JSON.stringify(JSON.stringify([roundi(load_center.x), roundi(load_center.y)])),
			str(FileAccess.file_exists(SandboxSave.PATH)).to_lower(),
			FileAccess.get_file_as_string(SandboxSave.PATH).length() if FileAccess.file_exists(SandboxSave.PATH) else 0,
			JSON.stringify(_notice.text)
		]
		JavaScriptBridge.eval(state, true)


func _settled_count() -> int:
	var total: int = 0
	for event in _world.events:
		if event["kind"] == "fare_settled":
			total += 1
	return total

func _count_activity(activity: String) -> int:
	var total: int = 0
	for npc in _world.residents:
		if str(npc.get("activity", "")) == activity:
			total += 1
	return total


func _count_events(kind: String) -> int:
	var total: int = 0
	for event in _world.events:
		if event["kind"] == kind:
			total += 1
	return total


func _render_route_picker(offer: Dictionary) -> void:
	var active: bool = not _world.active_offer_id.is_empty()
	if active:
		offer = _world.offer_by_id(_world.active_offer_id)
	_via.clear()
	_via.add_item("Stay on current route" if active else "Default map-pin route")
	_via.set_item_metadata(0, "")
	_apply_route.visible = active
	var request: Dictionary = _world.rider_route_request
	var pending_question: bool = active and request.get("status", "") == "pending"
	_honor.visible = pending_question
	_refuse.visible = pending_question
	_rider_info.visible = active
	_via.disabled = offer.is_empty() or (active and _world.route_nodes[_world.route_segment + 1] == str(offer["destination"]))
	_apply_route.disabled = _via.disabled
	if offer.is_empty():
		_city.preview_nodes = []
		_route_preview.text = "Select a request to preview connected roads."
		return
	var start: String = str(offer["origin"])
	var dest: String = str(offer["destination"])
	if active:
		start = _world.route_nodes[_world.route_segment + 1]
		if pending_question:
			var speaker: Dictionary = _world.resident(str(offer["npc_id"]))
			var legible: bool = SandboxKnowledge.understands(str(speaker["language"]), _world.modules_installed) \
					or bool(_world.common_requests.get(_world.active_offer_id, false))
			_rider_info.text = "Rider requests %s corridor (%s)." % [
				str(request["via"]).capitalize(), str(request["reason"]).replace("_", " ")
			] if legible else "Rider gestures toward %s on the map; motive unclear." % str(request["via"]).capitalize()
		else:
			_rider_info.text = "Rider route request: %s" % str(request.get("status", "none"))
	if _via.disabled:
		_city.preview_nodes = _world.route_nodes.duplicate() if active else []
		_route_preview.text = "Final edge: next junction is the destination." if active else "No connected path."
		return
	var selected: int = 0
	for district in SandboxRoads.LINKS:
		if district == start or district == dest:
			continue
		var path: Array[String] = SandboxRoads.path(start, dest, district)
		if not SandboxRoads.valid_path(path):
			continue
		_via.add_item("Via %s" % district.capitalize())
		var index: int = _via.item_count - 1
		_via.set_item_metadata(index, district)
		if district == _route_waypoint:
			selected = index
	_via.select(selected)
	_route_waypoint = str(_via.get_item_metadata(selected))
	var preview: Array[String] = SandboxRoads.path(start, dest, _route_waypoint)
	_city.preview_nodes = preview.duplicate()
	if active:
		_route_preview.text = "Current: %s (%dm left). %s" % [
			" > ".join(_world.route_nodes), _world.remaining_minutes,
			"Queued: %s" % " > ".join(_world.pending_route_nodes) if not _world.pending_route_nodes.is_empty() else
			"Choose a waypoint, then apply at the next junction."
		]
		return
	var exposure: String = " · checkpoint info unavailable"
	if _world.knows("map:district-graph"):
		exposure = " · known checkpoint exposure %d" % SandboxRoads.path_exposure(preview)
	_route_preview.text = "%s · %d min · %d cr road cost%s" % [
		" > ".join(preview), SandboxRoads.path_minutes(preview),
		SandboxRoads.path_expense(preview), exposure
	]
