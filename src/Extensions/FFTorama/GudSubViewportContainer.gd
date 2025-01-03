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

func flip_h():
	sprite_primary.flip_h = not sprite_primary.flip_h
	sprite_weapon.flip_h = not sprite_weapon.flip_h
	sprite_effect.flip_h = not sprite_effect.flip_h
	sprite_item.flip_h = not sprite_item.flip_h
