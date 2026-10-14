extends Node2D

@onready var _world: WorldView = $WorldView
@onready var _camera: Camera2D = $Camera2D
@onready var _status: Label = $HUD/InfoPanel/InfoLabel
@onready var _passenger_label: Label = $HUD/PassengerPanel/PassengerBody/PassengerText
@onready var _choice_list: VBoxContainer = $HUD/ChoicePanel/ChoiceList
@onready var _portrait: PassengerPresenter = $HUD/PassengerPanel/PassengerBody/AvatarCanvas
@onready var _frame_toggle: CheckButton = $HUD/PassengerPanel/PassengerBody/FrameToggle

const PRESENTATION_PREFS: String = "user://passenger_presentation.cfg"

const INK_PROBE_PATH: String = "res://stories/p1_probe.ink.json"
var _ink: InkBridge

var _ride: TaxiRide


func _ready() -> void:
	_initialize_presentation()
	_restart()
	# Godot is still registering children inside _ready. Ink's singleton is
	# created only after the scene tree completes this initialization pass.
	call_deferred("_start_ink")


func _process(delta: float) -> void:
	_ride.advance(delta)
	var taxi_position: Vector3 = _ride.world_position()
	var heading: Vector2 = _ride.screen_heading()
	_world.taxi_world = taxi_position
	_world.taxi_heading = heading
	_world.queue_redraw()

	# Camera look-ahead follows movement, but shows more context around the crossing.
	var destination: Vector2 = IsoProjection.project(taxi_position) + heading * 80.0
	var follow: float = 1.0 - exp(-delta * 2.8)
	_camera.position = _camera.position.lerp(destination, follow)
	var crossing_distance: float = Vector2(taxi_position.x - 2.0, taxi_position.z).length()
	var target_zoom: float = 1.18 if crossing_distance < 5.0 or taxi_position.y > 0.05 else 1.45
	_camera.zoom = _camera.zoom.lerp(Vector2.ONE * target_zoom, follow)

	var height_label: String = "elevated" if taxi_position.y > 0.5 else "ground"
	var state: String = "ARRIVED" if _ride.is_finished() else "MOVING"
	_status.text = "OUTSIDER DRIVER 2D  |  %s  |  %s  |  R to restart" % [state, height_label]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_restart()
		_start_ink()


func _start_ink() -> void:
	var story_json: String = FileAccess.get_file_as_string(INK_PROBE_PATH)
	if story_json.is_empty():
		_passenger_label.text = "Compiled Ink is missing. Compile stories/p1_probe.ink first."
		return
	_ink = InkBridge.new()
	if not _ink.open_compiled(story_json, get_tree()):
		_passenger_label.text = "Could not load the Ink story."
		return
	_portrait.set_expression("neutral")
	_show_ink(_ink.advance())
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.inkReady='true'", true)


func _show_ink(line: Dictionary) -> void:
	_passenger_label.text = str(line["text"])
	for child in _choice_list.get_children():
		child.queue_free()
	var options: Array = line["choices"]
	for i in range(options.size()):
		var button: Button = Button.new()
		button.text = str(options[i])
		button.pressed.connect(_on_choice.bind(i))
		_choice_list.add_child(button)
	if options.is_empty() and bool(line["ended"]):
		_passenger_label.text += "\n[Conversation ended]"


func _on_choice(index: int) -> void:
	var consequence: Dictionary = _ink.choose(index)
	_show_ink(consequence)
	var tags: Array = consequence["tags"]
	if tags.has("fact:docks-route"):
		_portrait.set_expression("curious")
	elif tags.has("suspicion:1"):
		_portrait.set_expression("uneasy")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.documentElement.dataset.inkChoice='selected'", true)


func _initialize_presentation() -> void:
	var settings: ConfigFile = ConfigFile.new()
	settings.load(PRESENTATION_PREFS)
	var framed: bool = bool(settings.get_value("passenger", "framed", true))
	_frame_toggle.set_pressed_no_signal(framed)
	_portrait.set_framed(framed)
	_frame_toggle.toggled.connect(_on_frame_toggled)
	_publish_frame_mode(framed)


func _on_frame_toggled(framed: bool) -> void:
	_portrait.set_framed(framed)
	var settings: ConfigFile = ConfigFile.new()
	settings.set_value("passenger", "framed", framed)
	var result: Error = settings.save(PRESENTATION_PREFS)
	if result != OK:
		push_warning("Passenger presentation preferences could not be saved.")
	_publish_frame_mode(framed)


func _publish_frame_mode(framed: bool) -> void:
	if OS.has_feature("web"):
		var value: String = "framed" if framed else "avatar"
		JavaScriptBridge.eval("document.documentElement.dataset.cabinFrame='%s'" % value, true)


func _restart() -> void:
	var points: Array[Vector3] = [
		Vector3(-10, 0, 0),
		Vector3(-2, 0, 0),
		Vector3(3, 0, 0),  # Cross under elevated road at x=2.
		Vector3(10, 0, 0),
		Vector3(10, 0, 6),
		Vector3(7, 0, 9),
		Vector3(3, 0, 9),
		Vector3(2, 1, 6),  # Authored ramp from level 0 to level 1.
		Vector3(2, 1, -6), # Cross above the same ground road.
	]
	_ride = TaxiRide.new(points)
	_world.taxi_world = _ride.world_position()
	_world.taxi_heading = _ride.screen_heading()
	_world.queue_redraw()
	_camera.position = IsoProjection.project(_ride.world_position())
