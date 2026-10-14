extends Node2D

@onready var _world: WorldView = $WorldView
@onready var _camera: Camera2D = $Camera2D
@onready var _status: Label = $HUD/InfoPanel/InfoLabel

var _ride: TaxiRide


func _ready() -> void:
	_restart()


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
