extends ConfirmationDialog

@export var main: Node

@export var path_dialog_popup: FileDialog
@export var path_line_edit: LineEdit
@export var file_line_edit: LineEdit
@export var file_format_options: OptionButton

@export var sprite_export: Sprite2D
@export var sprite_checker: Sprite2D
@export var checker: CheckBox

@export var size_selector: OptionButton
@export var size_x_spinbox: SpinBox
@export var size_y_spinbox: SpinBox

@export var offset_selector: OptionButton
@export var offset_x_spinbox: SpinBox
@export var offset_y_spinbox: SpinBox

var export_image: Image

var export_sizes: Dictionary = {
	"Narrow":Vector2i(24, 40),
	"Square":Vector2i(48, 48)
}
var offset_presets: Dictionary = {
	"Type1/2":Vector2i(-1, 0),
	"Dragon":Vector2i(0, -4),
	"Chocobo":Vector2i(-1, -3),
	"Bomb":Vector2i(1, 2),
	"Flotiball":Vector2i(-3, 2)
}
# var unit_size := Vector2i(24, 40)
# var monster_size := Vector2i(48, 48)
var portrait_size := Vector2i(48, 32)

var export_size: Vector2i = export_sizes["Narrow"]:
	get:
		return Vector2i(size_x_spinbox.value, size_y_spinbox.value)

var offset_base: Vector2i = Vector2i.ZERO
var export_offset: Vector2i = Vector2i.ZERO:
	get:
		return Vector2i(offset_base.x - offset_x_spinbox.value, offset_base.y + offset_y_spinbox.value)

func initialize():
	path_dialog_popup.current_dir = main.api.project.current_project.export_directory_path
	file_format_options.clear()
	file_format_options.add_item("4bpp paletted BMP (*.bmp)")
	file_format_options.select(0)

	offset_selector.clear()
	for key in offset_presets.keys():
		offset_selector.add_item(key)

	if offset_selector.item_count > 0:
		offset_selector.select(0)

	create_checker_overlay()
	creat_export_image()

func create_checker_overlay():
	var checker_image: Image = Image.create(
		export_size.x, export_size.y, false, Image.FORMAT_RGBA8
	)
	var dark_color := Color.DIM_GRAY
	dark_color.a = 0.25

	var lighter_color := Color.DARK_GRAY
	lighter_color.a = 0.25
	
	checker_image.fill(dark_color)

	# create checker pattern
	for x in checker_image.get_size().x:
		for y in checker_image.get_size().y:
			if (x+y) % 2 != 0:
				checker_image.set_pixel(x, y, lighter_color)
	
	sprite_checker.texture = ImageTexture.create_from_image(checker_image)

func creat_export_image(color: Color = Color.BLACK):
	export_image = Image.create(
		export_size.x, export_size.y, false, Image.FORMAT_RGBA8
	)
	export_image.fill(color)

	# # create checker pattern
	# for x in export_image.get_size().x:
	# 	for y in export_image.get_size().y:
	# 		if (x+y) % 2 != 0:
	# 			export_image.set_pixel(x, y, Color.DARK_GRAY)

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
	create_checker_overlay()
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


func _on_export_confirmed() -> void:
	# export file
	var bits_per_pixel:int = 4
	var pixel_count: int = export_image.get_height() * export_image.get_width()
	var palette_num_colors:int = 2**bits_per_pixel # 0x0010 for 16 colors (4bpp), 0x0100 for 256 colors
	
	var header_size: int = 54
	var palette_data_size: int = palette_num_colors * 4 # 256 * 4 for 8bpp
	var file_size: int = header_size + palette_data_size + (pixel_count/2)
	
	var bytes:PackedByteArray = []
	bytes.resize(file_size)
	bytes.fill(0)
	
	# BMP format
	# Header
	bytes.encode_u16(0x0000, 0x4D42) # signature (2 bytes) - BM
	bytes.encode_u32(0x0002, file_size) # FileSize (4 bytes) 0x0002
	#bytes.encode_u32(0x000A, 0x0) # reserved (4 bytes) 0x0006 - always zero?
	bytes.encode_u32(0x000A, 0x76) # DataOffset (4 bytes) 0x000A - 0x76 for 4bpp with 16 colors, 0x436 for 8bpp with 256 colors

	# InfoHeader
	bytes.encode_u32(0x000E, 0x28) # Info Header Size (4 bytes) 0x000E
	bytes.encode_u32(0x0012, export_image.get_size().x) # Width (4 bytes) 0x0012
	bytes.encode_u32(0x0016, export_image.get_size().y) # Height (4 bytes) 0x0016
	bytes.encode_u16(0x001A, 0x01) # Planes (2 bytes) 0x001A
	bytes.encode_u16(0x001C, 0x04) # Bits per Pixel (2 bytes) 0x001C - 0x04 for 4bpp, 0x08 for 8bpp
	#bytes.encode_u32(0x001E, 0) # Compression (4 bytes) 0x001E - 0 for none
	#bytes.encode_u32(0x0022, 0) # ImageSize (4 bytes) 0x0022 - 0 if no compression
	bytes.encode_u32(0x0026, 0x0EC4) # XpixelsPerMeter (4 bytes) 0x0026
	bytes.encode_u32(0x002A, 0x0EC4) # YpixelsPerMeter (4 bytes) 0x002A
	bytes.encode_u32(0x002E, palette_num_colors) # Colors Used (4 bytes) 0x002E
	bytes.encode_u32(0x0032, palette_num_colors) # Important Colors (4 bytes) 0x0032

	# Color Table 0x0036, either 16 (4bpp) colors long or 256 (8 bpp) colors long
	#var palette_data: Dictionary = main.api.current_palette.colors
	var bmp_palette: PackedColorArray = []
	bmp_palette.resize(palette_num_colors)
	bmp_palette.fill(Color.BLACK)
	
	# TODO get colors from pixelorama current_palette
	# will need Dictionary[Color, int] to use color at current pixel to get color index
	
	var color_bytes: PackedByteArray = []
	var i = 0
	for color in bmp_palette:
		color.b8 = i * 10
		bytes.encode_u8(0x0036 + (i*4), color.b8) # blue
		bytes.encode_u8(0x0036 + (i*4) + 1, color.g8) # green
		bytes.encode_u8(0x0036 + (i*4) + 2, color.r8) # red
		bytes.encode_u8(0x0036 + (i*4) + 3, color.a8) # alpha?

		i += 1
	
	
	
	
	# Pixel Data 0x076 or 0x436, left to right, bottom to top
	for x in export_image.get_width():
		for y in export_image.get_height():
			var color:Color = export_image.get_pixel(x, export_image.get_height() - y)
	
	
	var file = FileAccess.open(path_line_edit.text + "/" + file_line_edit.text + ".bmp", FileAccess.WRITE)
	file.store_buffer(bytes)
	hide()


func _on_checker_box_toggled(toggled_on: bool) -> void:
	sprite_checker.visible = toggled_on

func _on_path_button_pressed() -> void:
	path_dialog_popup.popup_centered()

func _on_path_line_edit_text_changed(new_text: String) -> void:
	main.api.project.current_project.export_directory_path = new_text

func _on_path_dialog_dir_selected(dir: String) -> void:
	path_line_edit.text = dir
	main.api.project.current_project.export_directory_path = dir
	# Needed because if native file dialogs are enabled
	# the export dialog closes when the path dialog closes
	if not visible:
		show()

func _on_path_dialog_canceled() -> void:
	# Needed because if native file dialogs are enabled
	# the export dialog closes when the path dialog closes
	if not visible:
		show()
