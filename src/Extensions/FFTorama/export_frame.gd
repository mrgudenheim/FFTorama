extends Button


@export var main:Node
# @export var data_loader:Node
# @export var data_loader:Node
# @export var data_loader:Node

@export	var file_dialog: FileDialog
@export	var export_dialog: ConfirmationDialog


func export_frame(path):
	var frame_primary_image:Image = main.assembled_animation_viewport.sprite_primary.texture.get_image()
	#var file_name:String = main.global_frame_id.to_string()
	#var frame_weapon_image:Image = main.assembled_animation_viewport.sprite_weapon.texture.get_image()
	#var frame_effect_image:Image = main.assembled_animation_viewport.sprite_effect.texture.get_image()
	frame_primary_image.save_png(path)


func _on_pressed():
	# print_debug("load file button pressed")
	# file_dialog.visible = true
	export_dialog.visible = true
	export_dialog.initialize()


func _on_file_dialog_file_selected(path: String) -> void:
	#print(path)
	export_frame(path)
	
