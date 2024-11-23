extends ConfirmationDialog

@export var main: Node

@export var path_dialog_popup: FileDialog
@export var path_line_edit: LineEdit
@export var file_line_edit: LineEdit
@export var file_format_options: OptionButton
@export var tab_bar: TabBar
var current_tab = ImportTab.PORTRAIT
@export var rotate_hbox: HBoxContainer
@export var rotate_check: CheckBox
@export var spacer: Control

@export var fft_palette_options:OptionButton
@export var swap_palette_options:OptionButton
@export var palette_overwrite_options:OptionButton

@export var sprite_preview: Sprite2D
@export var sprite_checker: Sprite2D
@export var checker: CheckBox
@export var preview_camera: Node2D

@export var size_selector: OptionButton
@export var size_x_spinbox: SpinBox
@export var size_y_spinbox: SpinBox

@export var offset_selector: OptionButton
@export var offset_x_spinbox: SpinBox
@export var offset_y_spinbox: SpinBox

var bmp:Bmp = Bmp.new()
var original_palette:Array[Color]
var original_indices:Array[int]

enum ImportTab { PORTRAIT }

var bits_per_pixel_lookup:Dictionary = {
	ImportTab.PORTRAIT:4
}

const palette_labels:Dictionary = {
	SPRITE1 = "Sprite 1",
	SPRITE2 = "Sprite 2",
	SPRITE3 = "Sprite 3",
	SPRITE4 = "Sprite 4",
	SPRITE5 = "Sprite 5",
	SPRITE6 = "Sprite 6",
	SPRITE7 = "Sprite 7",
	SPRITE8 = "Sprite 8",
	PORTRAIT1 = "Portrait 1",
	PORTRAIT2 = "Portrait 2",
	PORTRAIT3 = "Portrait 3",
	PORTRAIT4 = "Portrait 4",
	PORTRAIT5 = "Portrait 5",
	PORTRAIT6 = "Portrait 6",
	PORTRAIT7 = "Portrait 7",
	PORTRAIT8 = "Portrait 8"
}

var preview_image: Image = Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
var import_image: Image = Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)

var import_sizes:Dictionary = {}
var portrait_import_sizes: Dictionary = {
	"Horizontal":Vector2i(48, 32),
	"Vertical":Vector2i(32, 48)
}

var offset_presets: Dictionary = {}
var portrait_offset_presets: Dictionary = {
	"Horizontal":Vector2i(80, 456),
	"Vertical (Zero)":Vector2i(0, 0)
}

var import_size: Vector2i = Vector2i(8, 8):
	get:
		return Vector2i(size_x_spinbox.value, size_y_spinbox.value)

var offset_base: Vector2i = Vector2i.ZERO
var import_offset: Vector2i = Vector2i.ZERO:
	get:
		return Vector2i(offset_base.x + offset_x_spinbox.value, offset_base.y + offset_y_spinbox.value)

var default_zoom:Dictionary = {
	ImportTab.PORTRAIT: Vector2(0.6,0.6)
}


func initialize():
	path_dialog_popup.current_dir = main.api.project.current_project.export_directory_path
	path_line_edit.text = main.api.project.current_project.export_directory_path
	
	fft_palette_options.clear()
	for i in Palettes.current_palette.colors.size()/16:
		var label:String = "Sprite "
		if i >= 8:
			label = "Portrait "
		fft_palette_options.add_item(label + str((i % 8) + 1))
	
	swap_palette_options.clear()
	swap_palette_options.add_item("Don't Swap")
	palette_overwrite_options.clear()
	palette_overwrite_options.add_item("Don't Import")
	var i:int = 1
	for key in palette_labels:
		if i > Palettes.current_palette.colors.size()/16:
			break
		swap_palette_options.add_item(palette_labels[key])
		palette_overwrite_options.add_item("Overwrite Palette: " + palette_labels[key])
		i += 1
	#spritesheet_import_sizes["Full"] = main.api.project.current_project.size
	
	palette_overwrite_options.select(0) # default selection is to overwrite Portrait 1 palette
	
	import_sizes[ImportTab.PORTRAIT] = portrait_import_sizes
	
	offset_presets[ImportTab.PORTRAIT] = portrait_offset_presets
	
	if tab_bar.current_tab == -1:
		tab_bar.select_next_available()
	_on_tab_bar_tab_clicked(tab_bar.current_tab)
	
	sprite_preview.material.set_shader_parameter("palette", main.palette_texture)

func create_checker_overlay():
	var checker_image: Image = Image.create(
		main.api.project.current_project.size.x, main.api.project.current_project.size.y, false, Image.FORMAT_RGBA8
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


func get_bmp_data(path:String) -> void:
	var bmp_file:PackedByteArray = FileAccess.get_file_as_bytes(path)
	bmp = Bmp.new(bmp_file)
	original_palette = bmp.color_palette.duplicate()
	original_indices = bmp.color_indices.duplicate()
	create_import_image()

func create_import_image() -> Image:
	#import_image = Image.load_from_file(path)
	#import_image.convert(Image.FORMAT_RGBA8)
	if bmp.num_pixels == 0:
		return
	
	if swap_palette_options.selected == 0: # don't swap
		bmp.color_palette = original_palette.duplicate()
		bmp.color_indices = original_indices.duplicate()
		bmp.set_colors_by_indices()
	elif swap_palette_options.selected > 0:
		var new_palette: Array[Color] = []
		#new_palette.resize(Palettes.current_palette.colors.size())
		#new_palette.fill(Color.BLACK)
		#for palette_color in Palettes.current_palette.colors.values():
			#new_palette[palette_color.index] = palette_color.color
		
		var palette_offset:int = (swap_palette_options.selected - 1) * 16
		new_palette.resize(bmp.color_palette.size())
		new_palette.fill(Color.BLACK)
		for i in bmp.color_palette.size():
			new_palette[i] = Palettes.current_palette.colors[i + palette_offset].color
		
		bmp.color_palette = new_palette
	
		#if swap_palette_options.selected >= 1 and swap_palette_options.selected <= 16:
			#var index_offset = (swap_palette_options.selected - 1) * 16
			#if bmp.color_palette.size() >= 16 + index_offset:
				#for i in bmp.color_indices.size():
					#bmp.color_indices[i] = original_indices[i] + index_offset
			#else:
				#print_debug("Palette does not have enough colors. Needs " + str(16 + index_offset) + ", but only has " + str(bmp.color_palette.size()))
				#bmp.color_palette = original_palette.duplicate()
				#bmp.color_indices = original_indices.duplicate()
		bmp.set_colors_by_indices()
	
	import_image = bmp.get_rgba8_image()
	
	if rotate_check.button_pressed:
		import_image.rotate_90(CLOCKWISE)
		
	create_preview_image()
	return import_image

func create_preview_image(background_color: Color = Color.BLACK):
	preview_image.copy_from(main.display_cel_selector.cel.get_content())
	
	offset_base = Vector2i.ZERO
	var destination_pos = import_offset
	
	var import_size:Vector2i = import_image.get_size()
	var source_rect: Rect2i = Rect2i(0, 0, import_size.x, import_size.y)
	preview_image.blit_rect(import_image, source_rect, destination_pos)
	
	sprite_preview.texture = ImageTexture.create_from_image(preview_image)


func _on_offset_value_changed(value: float) -> void:
	create_preview_image()


func _on_size_value_changed(value: float) -> void:
	create_checker_overlay()
	create_preview_image()


func _on_size_options_item_selected(index: int) -> void:
	var text: String = size_selector.get_item_text(index)
	if import_sizes[current_tab].has(text):
		size_x_spinbox.editable = false
		size_y_spinbox.editable = false
		
		size_x_spinbox.value = import_sizes[current_tab][text].x
		size_y_spinbox.value = import_sizes[current_tab][text].y
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


func _on_import_confirmed() -> void:
	if palette_overwrite_options.selected > 0:
		var palette_offset:int = (palette_overwrite_options.selected - 1) * 16
		for i in original_palette.size():
			Palettes.current_palette.colors[i + palette_offset].color = original_palette[i]
			#Palettes.current_palette.set_color(i + palette_offset, bmp.color_palette[i])
		Palettes.select_palette(Palettes.current_palette.name)
	
	main.api.project.set_pixelcel_image(preview_image, main.display_cel_selector.cel_frame, main.display_cel_selector.cel_layer)
	
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
	for key in import_sizes[current_tab].keys():
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
	
	rotate_hbox.visible = current_tab == ImportTab.PORTRAIT
	spacer.visible = current_tab == ImportTab.PORTRAIT
	
	preview_camera.offset = Vector2.ZERO
	preview_camera.zoom = default_zoom[current_tab]
	
	create_checker_overlay()
	create_preview_image()


func _on_rotated_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		import_image.rotate_90(CLOCKWISE)
	else:
		import_image.rotate_90(COUNTERCLOCKWISE)
	_on_size_value_changed(0)


func _on_path_dialog_file_selected(path: String) -> void:
	get_bmp_data(path)


func _on_swap_palette_options_item_selected(index: int) -> void:
	#sprite_preview.material.set_shader_parameter("palette_offset", swap_palette_options.selected + 1)
	create_import_image()
