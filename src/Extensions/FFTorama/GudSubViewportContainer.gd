extends SubViewportContainer

@export var camera_control: Node2D
@export var sprite_primary: Sprite2D
@export var sprite_weapon: Sprite2D
@export var sprite_effect: Sprite2D
@export var sprite_text: Sprite2D
@export var sprite_background: Sprite2D
@export var sprite_item: Sprite2D

func _on_mouse_entered():
	camera_control.set_process_input(true)


func _on_mouse_exited():
	camera_control.set_process_input(false)
