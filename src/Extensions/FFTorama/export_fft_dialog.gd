extends ConfirmationDialog

@export var main: Node

@export var path_dialog_popup: FileDialog
@export var path_line_edit: LineEdit
@export var file_line_edit: LineEdit
@export var file_format_options: OptionButton
@export var tab_bar: TabBar
var current_tab = ExportTab.SPRITESHEET
@export var rotate_hbox: HBoxContainer
@export var rotate_check: CheckBox
@export var spacer: Control

@export var fft_palette_options:OptionButton

@export var sprite_export: Sprite2D
@export var sprite_checker: Sprite2D
@export var checker: CheckBox

@export var size_selector: OptionButton
@export var size_x_spinbox: SpinBox
@export var size_y_spinbox: SpinBox

@export var offset_selector: OptionButton
@export var offset_x_spinbox: SpinBox
@export var offset_y_spinbox: SpinBox

enum ExportTab { SPRITESHEET, FORMATION, PORTRAIT }

var bits_per_pixel_lookup:Dictionary = {
	ExportTab.SPRITESHEET:8,
	ExportTab.FORMATION:4,
	ExportTab.PORTRAIT:4
}

var export_image: Image

var export_sizes:Dictionary = {}
var spritesheet_export_sizes: Dictionary = {
	"Full":Vector2i(8, 8),
	"Standard":Vector2i(256, 488),
	"Standard + Sp2":Vector2i(256, 744),
	"256x256 (Sp2+)":Vector2i(256, 256),
	"2nd Half":Vector2i(256, 232)
}
var formation_export_sizes: Dictionary = {
	"Narrow":Vector2i(24, 40),
	"Square":Vector2i(48, 48)
}
var portrait_export_sizes: Dictionary = {
	"Horizontal":Vector2i(48, 32),
	"Vertical":Vector2i(32, 48)
}

var offset_presets: Dictionary = {}
var spritesheet_offset_presets: Dictionary = {
	"Zero":Vector2i(0, 0),
	"Sp2":Vector2i(0, 488),
	"2nd Half":Vector2i(0, 256),
	"Sp3":Vector2i(0, 744)
}
var formation_offset_presets: Dictionary = {
	"Type1/2":Vector2i(-1, 0),
	"Dragon":Vector2i(0, -4),
	"Chocobo":Vector2i(-1, -3),
	"Bomb":Vector2i(1, 2),
	"Flotiball":Vector2i(-3, 2)
}
var portrait_offset_presets: Dictionary = {
	"Horizontal":Vector2i(-80, 456),
	"Vertical (Zero)":Vector2i(0, 0)
}

var export_size: Vector2i = Vector2i(8, 8):
	get:
		return Vector2i(size_x_spinbox.value, size_y_spinbox.value)

var offset_base: Vector2i = Vector2i.ZERO
var export_offset: Vector2i = Vector2i.ZERO:
	get:
		return Vector2i(offset_base.x - offset_x_spinbox.value, offset_base.y + offset_y_spinbox.value)

func initialize():
	path_dialog_popup.current_dir = main.api.project.current_project.export_directory_path
	path_line_edit.text = main.api.project.current_project.export_directory_path
	
	fft_palette_options.clear()
	for i in Palettes.current_palette.colors.size()/16:
		var label:String = "Sprite: "
		if i >= 8:
			label = "Portrait: "
		fft_palette_options.add_item(label + str((i % 8) + 1))
	
	spritesheet_export_sizes["Full"] = main.api.project.current_project.size
	
	export_sizes[ExportTab.SPRITESHEET] = spritesheet_export_sizes
	export_sizes[ExportTab.FORMATION] = formation_export_sizes
	export_sizes[ExportTab.PORTRAIT] = portrait_export_sizes
	
	offset_presets[ExportTab.SPRITESHEET] = spritesheet_offset_presets
	offset_presets[ExportTab.FORMATION] = formation_offset_presets
	offset_presets[ExportTab.PORTRAIT] = portrait_offset_presets
	
	if tab_bar.current_tab == -1:
		tab_bar.select_next_available()
	_on_tab_bar_tab_clicked(tab_bar.current_tab)

func create_checker_overlay():
	var checker_image: Image = Image.create(
		export_size.x, export_size.y, false, Image.FORMAT_RGBA8
	)
	var dark_color := Color.DIM_GRAY
	dark_color.a = 0.25

	var lighter_color := Color.DARK_GRAY
	lighter_color.a = 0.25
	
	checker_image.fill(dark_color)
	
	if current_tab == ExportTab.PORTRAIT and rotate_check.button_pressed:
		checker_image.rotate_90(COUNTERCLOCKWISE)

	# create checker pattern
	for x in checker_image.get_size().x:
		for y in checker_image.get_size().y:
			if (x+y) % 2 != 0:
				checker_image.set_pixel(x, y, lighter_color)
	
	sprite_checker.texture = ImageTexture.create_from_image(checker_image)

func creat_export_image(background_color: Color = Color.BLACK):
	export_image = Image.create(
		export_size.x, export_size.y, false, Image.FORMAT_RGBA8
	)
	export_image.fill(background_color)

	var source_image: Image
	if current_tab == ExportTab.FORMATION:
		source_image = main.assembled_frame_node.texture.get_image()
	else:
		source_image = main.display_cel_selector.cel.get_content()
	
	var source_size:Vector2i = source_image.get_size()
	if current_tab == ExportTab.FORMATION:
		offset_base = Vector2i((source_size.x/2) - (export_size.x/2), -35 + source_size.y - 40) # -35 from type1 frame id 2, -40 from hard coded distination position offset in FFTorama "main"
	else:
		offset_base = Vector2i.ZERO
	
	var destination_pos = Vector2i.ZERO
	var source_rect: Rect2i = Rect2i(export_offset.x, export_offset.y, export_size.x, export_size.y)
	export_image.blend_rect(source_image, source_rect, destination_pos)
	
	if current_tab == ExportTab.PORTRAIT and rotate_check.button_pressed:
		export_image.rotate_90(COUNTERCLOCKWISE)
	
	# TODO allow exporting formation and portraits with palettes other than the first 16 colors
	#var new_color_index = color_index + (16*fft_palette_options.selected)

	sprite_export.texture = ImageTexture.create_from_image(export_image)


func _on_offset_value_changed(value: float) -> void:
	creat_export_image()


func _on_size_value_changed(value: float) -> void:
	create_checker_overlay()
	creat_export_image()


func _on_size_options_item_selected(index: int) -> void:
	var text: String = size_selector.get_item_text(index)
	if export_sizes[current_tab].has(text):
		size_x_spinbox.editable = false
		size_y_spinbox.editable = false
		
		size_x_spinbox.value = export_sizes[current_tab][text].x
		size_y_spinbox.value = export_sizes[current_tab][text].y
	else:
		size_x_spinbox.editable = true
		size_y_spinbox.editable = true

func _on_offset_options_item_selected(index: int) -> void:
	var text: String = offset_selector.get_item_text(index)
	if offset_presets[current_tab].has(text):
		offset_x_spinbox.editable = false
		offset_y_spinbox.editable = false
		
		offset_x_spinbox.value = offset_presets[current_tab][text].x
		offset_y_spinbox.value = offset_presets[current_tab][text].y
	else:
		offset_x_spinbox.editable = true
		offset_y_spinbox.editable = true

func create_bmp(image:Image, bits_per_pixel: int = 8) -> PackedByteArray:
	# export file
	var pixel_count: int = image.get_height() * image.get_width()
	var palette_num_colors:int = 2**bits_per_pixel # 0x0010 for 16 colors (4bpp), 0x0100 for 256 colors
	var offset: int = 0x076 # if bits_per_pixel == 4
	if bits_per_pixel == 8:
		offset = 0x436
	
	var header_size: int = 54
	var palette_data_size: int = palette_num_colors * 4 # 256 * 4 for 8bpp
	var file_size: int = header_size + palette_data_size + (pixel_count * (bits_per_pixel/8))
	
	var bytes:PackedByteArray = []
	bytes.resize(file_size)
	bytes.fill(0)
	
	# BMP format
	# Header
	bytes.encode_u16(0x0000, 0x4D42) # signature (2 bytes) - BM
	bytes.encode_u32(0x0002, file_size) # FileSize (4 bytes) 0x0002
	#bytes.encode_u32(0x000A, 0x0) # reserved (4 bytes) 0x0006 - always zero?
	bytes.encode_u32(0x000A, offset) # DataOffset (4 bytes) 0x000A - 0x76 for 4bpp with 16 colors, 0x436 for 8bpp with 256 colors

	# InfoHeader
	bytes.encode_u32(0x000E, 0x28) # Info Header Size (4 bytes) 0x000E
	bytes.encode_u32(0x0012, image.get_size().x) # Width (4 bytes) 0x0012
	bytes.encode_u32(0x0016, image.get_size().y) # Height (4 bytes) 0x0016
	bytes.encode_u16(0x001A, 0x01) # Planes (2 bytes) 0x001A
	bytes.encode_u16(0x001C, bits_per_pixel) # Bits per Pixel (2 bytes) 0x001C - 0x04 for 4bpp, 0x08 for 8bpp
	#bytes.encode_u32(0x001E, 0) # Compression (4 bytes) 0x001E - 0 for none
	#bytes.encode_u32(0x0022, 0) # ImageSize (4 bytes) 0x0022 - 0 if no compression
	bytes.encode_u32(0x0026, 0x0EC4) # XpixelsPerMeter (4 bytes) 0x0026
	bytes.encode_u32(0x002A, 0x0EC4) # YpixelsPerMeter (4 bytes) 0x002A
	bytes.encode_u32(0x002E, palette_num_colors) # Colors Used (4 bytes) 0x002E
	bytes.encode_u32(0x0032, palette_num_colors) # Important Colors (4 bytes) 0x0032

	# Color Table 0x0036, either 16 (4bpp) colors long or 256 (8 bpp) colors long	
	var color_index: Dictionary = {} # Dictionary[string, int] to determine index based on pixel color
	for palette_color in Palettes.current_palette.colors.values():
		var palette_color_string: String = str(palette_color.color) # use string to allow for correct dictionary lookup
		if palette_color.index < palette_num_colors:
			if color_index.has(palette_color_string): # keep lowest index for color
				if palette_color.index < color_index[palette_color_string]:
					color_index[palette_color_string] = palette_color.index
			else:
				color_index[palette_color_string] = palette_color.index
			
			bytes.encode_u8(0x0036 + (palette_color.index*4), palette_color.color.b8) # blue
			bytes.encode_u8(0x0036 + (palette_color.index*4) + 1, palette_color.color.g8) # green
			bytes.encode_u8(0x0036 + (palette_color.index*4) + 2, palette_color.color.r8) # red
			bytes.encode_u8(0x0036 + (palette_color.index*4) + 3, palette_color.color.a8) # alpha
	
	# Pixel Data 0x076 or 0x436, left to right, bottom to top	
	var index: int = 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel_index: int = x + (image.get_width() * y)
			var color:Color = image.get_pixel(x, image.get_height() - y - 1)
			var color_string:String = str(color)
			
			if color_index.has(color_string):
				index = color_index[color_string]
			else:
				print_debug("color not in palette: " + color_string)
				index = 0
			if bits_per_pixel == 8:
				bytes.encode_u8(offset + pixel_index, index)
			elif bits_per_pixel == 4:
				var index_4bits: int = index # right half of byte
				if pixel_index % 2 == 0:
					index_4bits = index_4bits << 4 # left half of byte
				
				index_4bits = index_4bits | bytes.decode_u8(offset + floor(pixel_index/2)) # keep both left and right half of byte
				bytes.encode_u8(offset + floor(pixel_index/2), index_4bits)
	
	return bytes
	
func _on_export_confirmed() -> void:
	var bmp: PackedByteArray = create_bmp(export_image, bits_per_pixel_lookup[current_tab])
	
	var file = FileAccess.open(path_line_edit.text + "/" + file_line_edit.text + ".bmp", FileAccess.WRITE)
	file.store_buffer(bmp)
	file.close()
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


func _on_tab_bar_tab_clicked(tab_idx: int) -> void:
	current_tab = tab_idx
	var format_description = "Unknown?"
	
	if bits_per_pixel_lookup[current_tab] == 4:
		format_description = "4bpp paletted BMP (*.bmp)"
	elif bits_per_pixel_lookup[current_tab] == 8:
		format_description = "8bpp paletted BMP (*.bmp)"
	
	file_format_options.clear()
	file_format_options.add_item(format_description)
	file_format_options.select(0)
	
	size_selector.clear()
	for key in export_sizes[current_tab].keys():
		size_selector.add_item(key)
	size_selector.add_item("Custom")

	offset_selector.clear()
	for key in offset_presets[current_tab].keys():
		offset_selector.add_item(key)
	offset_selector.add_item("Custom")
	
	if size_selector.item_count > 0:
		size_selector.select(0)
		size_selector.item_selected.emit(0)
	
	if offset_selector.item_count > 0:
		offset_selector.select(0)
		offset_selector.item_selected.emit(0)
	
	rotate_hbox.visible = current_tab == ExportTab.PORTRAIT
	spacer.visible = current_tab == ExportTab.PORTRAIT
	
	if fft_palette_options.item_count > 0:
		var fft_palette:int = 0
		if current_tab == ExportTab.PORTRAIT and Palettes.current_palette.colors_max >= 144:
			fft_palette = 9
		fft_palette_options.select(fft_palette)
		fft_palette_options.item_selected.emit(fft_palette)
	
	
	create_checker_overlay()
	creat_export_image()


func _on_rotated_check_toggled(toggled_on: bool) -> void:
	_on_size_value_changed(0)
