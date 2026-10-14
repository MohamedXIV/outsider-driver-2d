class_name TaxiRide
extends RefCounted

# Authoritative *demo* route progress. This does not belong to the renderer.
# Eventually authored route IDs and events feed this small travel state.
const CRUISE_SPEED: float = 2.7

var _points: Array[Vector3] = []
var _next_index: int = 1
var _position: Vector3 = Vector3.ZERO


func _init(points: Array[Vector3]) -> void:
	assert(points.size() >= 2, "A ride needs at least two waypoints.")
	_points = points.duplicate()
	_position = _points[0]


func advance(delta: float) -> void:
	var remaining: float = maxf(0.0, delta) * CRUISE_SPEED
	while remaining > 0.0001 and not is_finished():
		var target: Vector3 = _points[_next_index]
		var distance: float = _position.distance_to(target)
		if distance < 0.0001:
			_next_index += 1
			continue
		if remaining >= distance:
			_position = target
			_next_index += 1
			remaining -= distance
		else:
			_position = _position.move_toward(target, remaining)
			remaining = 0.0


func world_position() -> Vector3:
	return _position


func is_finished() -> bool:
	return _next_index >= _points.size()


func screen_heading() -> Vector2:
	var target: Vector3 = _points[_points.size() - 1] if is_finished() else _points[_next_index]
	if is_finished():
		target = _points[_points.size() - 1] + (
			_points[_points.size() - 1] - _points[_points.size() - 2]
		)
	var from_screen: Vector2 = IsoProjection.project(_position)
	var to_screen: Vector2 = IsoProjection.project(target)
	return (to_screen - from_screen).normalized()
