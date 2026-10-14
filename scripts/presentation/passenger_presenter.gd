class_name PassengerPresenter
extends Control

# Replaces static portrait rendering without exposing it to Ink or GameSession.
# The four frames in this starter sheet are deliberately simple placeholders.
const FRAME_SIZE: Vector2 = Vector2(96, 96)
const SHEET: Texture2D = preload("res://assets/passengers/docks_visitor.svg")
const EXPRESSIONS: Dictionary = {
	"neutral": 0,
	"curious": 1,
	"uneasy": 2,
	"speaking": 3
}

@onready var _avatar: TextureRect = $AvatarTexture
@onready var _seat: TextureRect = $SeatFrame

var _atlas: AtlasTexture
var _expression: String = "neutral"
var _framed: bool = true


func _ready() -> void:
	_atlas = AtlasTexture.new()
	_atlas.atlas = SHEET
	_avatar.texture = _atlas
	_update_display()


func set_expression(value: String) -> void:
	_expression = value if EXPRESSIONS.has(value) else "neutral"
	if is_node_ready():
		_update_display()


func set_framed(value: bool) -> void:
	_framed = value
	if is_node_ready():
		_update_display()


func is_framed() -> bool:
	return _framed


func get_expression() -> String:
	return _expression


func _update_display() -> void:
	_atlas.region = Rect2(Vector2(float(EXPRESSIONS[_expression]) * FRAME_SIZE.x, 0), FRAME_SIZE)
	_seat.visible = _framed
