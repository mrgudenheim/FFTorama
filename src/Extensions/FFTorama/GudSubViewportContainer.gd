extends SubViewportContainer

@export var camera_control: Node2D
@export var sprite: Sprite2D

func _on_mouse_entered():
	camera_control.set_process_input(true)


func _on_mouse_exited():
	camera_control.set_process_input(false)
