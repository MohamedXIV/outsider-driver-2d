class_name SandboxTrafficVehicle
extends CharacterBody2D

# Local physical kinematic speed; never a world-owned second scheduler.
var current_speed: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	queue_redraw()

func _physics_process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-14,-9),Vector2(28,18)),Color("d4aa70"))
	draw_rect(Rect2(Vector2(-4,-7),Vector2(10,14)),Color("3d6269"))
	draw_rect(Rect2(Vector2(11,-6),Vector2(3,4)),Color("eee0b0"))
	draw_rect(Rect2(Vector2(11,2),Vector2(3,4)),Color("eee0b0"))
