extends ConfirmationDialog

@export var main: Node

@export var sprite_export: Sprite2D
@export var sprite_transparency: Sprite2D

@export var size_selector: OptionButton
@export var size_x_spinbox: SpinBox
@export var size_y_spinbox: SpinBox

@export var offset_selector: OptionButton
@export var offset_x_spinbox: SpinBox
@export var offset_y_spinbox: SpinBox

var export_sizes: Dictionary = {
	"Type1/2":Vector2i(24, 40),
	"Monster":Vector2i(48, 48)
}
var offset_presets: Dictionary = {
	"Type1/2":Vector2i(1, 0),
	"Monster":Vector2i(0, 0)
}
# var unit_size := Vector2i(24, 40)
# var monster_size := Vector2i(48, 48)
var portrait_size := Vector2i(48, 32)

var export_size: Vector2i = export_sizes["Type1/2"]:
	get:
		return Vector2i(size_x_spinbox.value, size_y_spinbox.value)

var offset_base: Vector2i = Vector2i.ZERO
var export_offset: Vector2i = Vector2i.ZERO:
	get:
		return Vector2i(offset_base.x + offset_x_spinbox.value, offset_base.y + offset_y_spinbox.value)

func initialize():
	creat_export_image()

func creat_export_image():
	var export_image: Image = Image.create(
		export_size.x, export_size.y, false, Image.FORMAT_RGBA8
	)
	export_image.fill(Color.BLACK)

	var source_image: Image = main.assembled_frame_node.texture.get_image()
	var source_size:Vector2i = source_image.get_size()
	offset_base = Vector2i((source_size.x/2) - (export_size.x/2), -35 + source_size.y - 40) # -35 from type1 frame id 2, -40 from hard coded distination position offset in FFTorama "main"

	var destination_pos = Vector2i.ZERO
	var source_rect: Rect2i = Rect2i(export_offset.x, export_offset.y, export_size.x, export_size.y)
	export_image.blend_rect(source_image, source_rect, destination_pos)

	sprite_export.texture = ImageTexture.create_from_image(export_image)


func _on_offset_value_changed(value: float) -> void:
	creat_export_image()


func _on_size_value_changed(value: float) -> void:
	creat_export_image()


func _on_size_options_item_selected(index: int) -> void:
	var text: String = size_selector.get_item_text(index)
	if export_sizes.has(text):
		size_x_spinbox.editable = false
		size_y_spinbox.editable = false
		
		size_x_spinbox.value = export_sizes[text].x
		size_y_spinbox.value = export_sizes[text].y
	else:
		size_x_spinbox.editable = true
		size_y_spinbox.editable = true

func _on_offset_options_item_selected(index: int) -> void:
	var text: String = offset_selector.get_item_text(index)
	if offset_presets.has(text):
		offset_x_spinbox.editable = false
		offset_y_spinbox.editable = false
		
		offset_x_spinbox.value = offset_presets[text].x
		offset_y_spinbox.value = offset_presets[text].y
	else:
		offset_x_spinbox.editable = true
		offset_y_spinbox.editable = true