extends Node2D

@onready var _world: WorldView = $WorldView
@onready var _camera: Camera2D = $Camera2D
@onready var _status: Label = $HUD/InfoPanel/InfoLabel
@onready var _passenger_label: Label = $HUD/PassengerPanel/PassengerBody/PassengerText
@onready var _passenger_panel: PanelContainer = $HUD/PassengerPanel
@onready var _choice_panel: PanelContainer = $HUD/ChoicePanel
@onready var _choice_list: VBoxContainer = $HUD/ChoicePanel/ChoiceList
@onready var _portrait: PassengerPresenter = $HUD/PassengerPanel/PassengerBody/AvatarCanvas
@onready var _frame_toggle: CheckButton = $HUD/PassengerPanel/PassengerBody/FrameToggle
@onready var _ride_state: Label = $HUD/RideBar/RideContent/RideState
@onready var _notice_label: Label = $HUD/RideBar/RideContent/Notice
@onready var _prep_panel: PanelContainer = $HUD/PrepPanel
@onready var _prep_help: Label = $HUD/PrepPanel/PrepContent/PrepHelp
@onready var _prep_detail: Label = $HUD/PrepPanel/PrepContent/PrepDetail
@onready var _hint_label: Label = $HUD/HintPanel/HintLabel
@onready var _pickup_button: Button = $HUD/RideBar/RideContent/Actions/Pickup
@onready var _arrival_button: Button = $HUD/RideBar/RideContent/Actions/Arrived
@onready var _save_button: Button = $HUD/RideBar/RideContent/Actions/Save
@onready var _load_button: Button = $HUD/RideBar/RideContent/Actions/Load

const STORY_PATH: String = "res://stories/p1_probe.ink.json"
const PRESENTATION_PREFS: String = "user://passenger_presentation.cfg"

var _session: GameSession
var _ink: InkBridge
var _notice: String = ""


func _ready() -> void:
	_initialize_presentation()
	$HUD/PrepPanel/PrepContent/PrepChoices/GPS.pressed.connect(_on_select_starter.bind("gps"))
	$HUD/PrepPanel/PrepContent/PrepChoices/Translator.pressed.connect(_on_select_starter.bind("translator"))
	$HUD/PrepPanel/PrepContent/PrepChoices/Radio.pressed.connect(_on_select_starter.bind("radio"))
	_pickup_button.pressed.connect(_on_pickup)
	_arrival_button.pressed.connect(_on_arrived)
	_save_button.pressed.connect(_on_save)
	_load_button.pressed.connect(_on_load)
	_restart()


func _process(delta: float) -> void:
	_session.advance(delta)
	var taxi_world: Vector3 = _session.ride.world_position()
	var heading: Vector2 = _session.ride.screen_heading()
	_world.taxi_world = taxi_world
	_world.taxi_heading = heading
	_world.queue_redraw()
	var destination: Vector2 = IsoProjection.project(taxi_world) + heading * 80.0
	var follow: float = 1.0 - exp(-delta * 2.8)
	_camera.position = _camera.position.lerp(destination, follow)
	var crossing_distance: float = Vector2(taxi_world.x - 2.0, taxi_world.z).length()
	var target_zoom: float = 1.18 if crossing_distance < 5.0 or taxi_world.y > 0.05 else 1.45
	_camera.zoom = _camera.zoom.lerp(Vector2.ONE * target_zoom, follow)
	_refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_restart()


func _restart() -> void:
	_session = GameSession.new()
	_ink = null
	_notice = ""
	_passenger_label.text = "Pick up the visitor to begin."
	_portrait.set_expression("neutral")
	_camera.position = IsoProjection.project(_session.ride.world_position())
	_refresh_ui()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.inkReady='false';document.documentElement.dataset.inkChoice='none'", true)


func _on_select_starter(device_id: String) -> void:
	if not _session.select_starter_device(device_id):
		return
	_notice = "Prepared %s. You can now take the fare." % device_id.to_upper()
	_refresh_ui()


func _starter_information() -> String:
	match _session.starter_device:
		"gps":
			return "GPS: The direct road crosses an inspection arch. No safe detour is marked."
		"translator":
			return "TRANSLATOR: The visitor's token reads NIGHT CLINIC — not an entry permit."
		"radio":
			return "RADIO: Two alien languages share the dial. Neither broadcast is intelligible yet."
	return "Choose one working device. Each reveals different information about the city."


func _on_pickup() -> void:
	if not _session.pickup():
		return
	_notice = "Passenger picked up."
	_start_ink()
	_refresh_ui()


func _start_ink(saved: Dictionary = {}) -> void:
	var story_json: String = FileAccess.get_file_as_string(STORY_PATH)
	if story_json.is_empty():
		_passenger_label.text = "Missing authored Ink story."
		return
	_ink = InkBridge.new()
	if not _ink.open_compiled(story_json, get_tree()):
		_passenger_label.text = "Ink runtime could not load."
		return
	if not saved.is_empty() and _ink.restore_snapshot(saved):
		_show_ink(_ink.current_frame())
	else:
		_show_ink(_ink.advance())
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.inkReady='true'", true)


func _show_ink(frame: Dictionary) -> void:
	_passenger_label.text = str(frame["text"])
	for child in _choice_list.get_children():
		child.queue_free()
	var options: Array = frame["choices"]
	for index in range(options.size()):
		var button: Button = Button.new()
		button.text = str(options[index])
		button.pressed.connect(_on_choice.bind(index))
		_choice_list.add_child(button)
	if options.is_empty() and bool(frame["ended"]):
		_passenger_label.text += "\n[Conversation finished]"


func _on_choice(index: int) -> void:
	if _ink == null or _session.phase == GameSession.RidePhase.COMPLETED:
		return
	var choosing_arrival: bool = _ink.current_frame().get("tags", []).has("arrival:offer")
	var result: Dictionary = _ink.choose(index)
	var event_id: String = "first-ride:arrival-choice" if choosing_arrival else "first-ride:passenger-choice"
	_session.apply_story_tags(event_id, result["tags"])
	_show_ink(result)
	if result["tags"].has("fact:docks-route"):
		_portrait.set_expression("curious")
		_notice = "Learned: northern service road."
	elif result["tags"].has("suspicion:1"):
		_portrait.set_expression("uneasy")
		_notice = "The visitor watches your dashboard closely."
	if choosing_arrival and result["tags"].has("arrival:complete") and _session.drop_off():
		_notice = "Passenger dropped off. Fare settled."
		_on_save()
	_refresh_ui()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.inkChoice='selected'", true)


func _on_arrived() -> void:
	if _session.phase != GameSession.RidePhase.ARRIVED or _ink == null:
		return
	# Player deliberately opens the short authored arrival scene, even if the
	# earlier conversation was left unanswered. This never auto-cuts a line.
	_show_ink(_ink.jump_to("arrival"))
	_notice = "The visitor is ready to disembark."
	_refresh_ui()


func _on_save() -> void:
	var ink_state: Dictionary = _ink.snapshot() if _ink != null else {}
	_notice = "Game saved." if RideSave.save(_session, ink_state) else "Save failed."
	_refresh_ui()


func _on_load() -> void:
	var payload: Dictionary = RideSave.load()
	if payload.is_empty():
		_notice = "No valid v2 save exists."
		_refresh_ui()
		return
	var restored: GameSession = GameSession.new()
	if not restored.restore_snapshot(payload["game"]):
		_notice = "Save contains an invalid ride."
		_refresh_ui()
		return
	if (restored.phase == GameSession.RidePhase.TRAVELING or restored.phase == GameSession.RidePhase.ARRIVED) and payload["ink"].is_empty():
		_notice = "Save is missing its active conversation."
		_refresh_ui()
		return
	_session = restored
	_ink = null
	if _session.phase == GameSession.RidePhase.TRAVELING or _session.phase == GameSession.RidePhase.ARRIVED:
		_start_ink(payload["ink"])
	_notice = "Game loaded."
	_camera.position = IsoProjection.project(_session.ride.world_position())
	_refresh_ui()


func _refresh_ui() -> void:
	_prep_panel.visible = _session.phase == GameSession.RidePhase.WAITING
	var device_chosen: bool = not _session.starter_device.is_empty()
	_prep_help.text = "Equipment locked for this shift." if device_chosen else "One working device. Choose before taking your first passenger."
	_prep_detail.text = _starter_information()
	for button in $HUD/PrepPanel/PrepContent/PrepChoices.get_children():
		(button as Button).disabled = device_chosen
	_pickup_button.visible = _session.phase == GameSession.RidePhase.WAITING
	_pickup_button.disabled = not device_chosen
	var arrival_offered: bool = _ink != null and _ink.current_frame().get("tags", []).has("arrival:offer")
	_arrival_button.visible = _session.phase == GameSession.RidePhase.ARRIVED and not arrival_offered
	_passenger_panel.visible = _session.phase == GameSession.RidePhase.TRAVELING \
			or _session.phase == GameSession.RidePhase.ARRIVED
	_choice_panel.visible = _session.phase == GameSession.RidePhase.TRAVELING \
			or _session.phase == GameSession.RidePhase.ARRIVED
	var status_text: String = ["WAITING", "TRAVELING", "ARRIVED", "COMPLETED"][int(_session.phase)]
	var minute_of_day: int = int(_session.world_minutes) % 1440
	_status.text = "NIGHT SHIFT | %s | %02d:%02d" % [
		status_text, minute_of_day / 60, minute_of_day % 60
	]
	var route_hint: String = "KNOWN" if _session.known_facts.has("docks-route") else "UNKNOWN"
	var passenger_hint: String = "WATCHFUL" if _session.suspicion > 0 else "CALM"
	_ride_state.text = "Clinic fare %d cr  |  Wallet %d cr  |  Route %s  |  Visitor %s" % [
		GameSession.FARE_CREDITS, _session.credits, route_hint, passenger_hint
	]
	_hint_label.text = "DOCKSIDE GARAGE  |  Choose equipment to begin" if not device_chosen else _starter_information()
	_notice_label.text = _notice
	if OS.has_feature("web"):
		var phase_name: String = status_text.to_lower()
		var web_state: String = "Object.assign(document.documentElement.dataset,{starterDevice:'%s',ridePhase:'%s',rideCredits:'%d',rideSuspicion:'%d',rideFacts:'%d',rideClock:'%.3f',passengerVisible:'%s',choiceVisible:'%s',choiceCount:'%d',arrivalOffer:'%s'})" % [
			_session.starter_device, phase_name, _session.credits, _session.suspicion, _session.known_facts.size(),
			_session.world_minutes, str(_passenger_panel.visible).to_lower(),
			str(_choice_panel.visible).to_lower(),
			_ink.current_frame().get("choices", []).size() if _ink != null else 0,
			str(arrival_offered).to_lower()
		]
		JavaScriptBridge.eval(web_state, true)


func _initialize_presentation() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PRESENTATION_PREFS)
	var framed: bool = bool(config.get_value("passenger", "framed", true))
	_frame_toggle.set_pressed_no_signal(framed)
	_portrait.set_framed(framed)
	_frame_toggle.toggled.connect(_on_frame_toggled)
	_publish_frame_mode(framed)


func _on_frame_toggled(framed: bool) -> void:
	_portrait.set_framed(framed)
	var config: ConfigFile = ConfigFile.new()
	config.set_value("passenger", "framed", framed)
	if config.save(PRESENTATION_PREFS) != OK:
		push_warning("Passenger presentation preference could not be saved.")
	_publish_frame_mode(framed)


func _publish_frame_mode(framed: bool) -> void:
	if OS.has_feature("web"):
		var value: String = "framed" if framed else "avatar"
		JavaScriptBridge.eval("document.documentElement.dataset.cabinFrame='%s'" % value, true)
