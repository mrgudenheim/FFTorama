extends ConfirmationDialog

@export var main: Node

@export var tab_container: TabContainer
@export var path_dialog_popup: FileDialog

# import portrait
@export var portrait_file_name_line: LineEdit
@export var rotate_hbox: HBoxContainer
@export var rotate_check: CheckBox
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

# import palette
@export var palette_file_name_line: LineEdit
@export var palette_preview_grid:GridContainer
@export var full_palette:CheckBox
@export var split_palette:CheckBox
@export var split_size:SpinBox


var bmp:Bmp = Bmp.new()
var original_palette:Array[Color]
var original_indices:Array[int]

enum ImportTab { PORTRAIT, PALETTE }

#const palettes:Dictionary = {
	#SPRITE1,
	#SPRITE2,
	#SPRITE3,
	#SPRITE4,
	#SPRITE5,
	#SPRITE6,
	#SPRITE7,
	#SPRITE8,
	#PORTRAIT1,
	#PORTRAIT2,
	#PORTRAIT3,
	#PORTRAIT4,
	#PORTRAIT5,
	#PORTRAIT6,
	#PORTRAIT7,
	#PORTRAIT8
#}

#const palette_labels:Dictionary = {
	#SPRITE1 = "Sprite 1",
	#SPRITE2 = "Sprite 2",
	#SPRITE3 = "Sprite 3",
	#SPRITE4 = "Sprite 4",
	#SPRITE5 = "Sprite 5",
	#SPRITE6 = "Sprite 6",
	#SPRITE7 = "Sprite 7",
	#SPRITE8 = "Sprite 8",
	#PORTRAIT1 = "Portrait 1",
	#PORTRAIT2 = "Portrait 2",
	#PORTRAIT3 = "Portrait 3",
	#PORTRAIT4 = "Portrait 4",
	#PORTRAIT5 = "Portrait 5",
	#PORTRAIT6 = "Portrait 6",
	#PORTRAIT7 = "Portrait 7",
	#PORTRAIT8 = "Portrait 8"
#}

const palette_labels:Dictionary = {
	0: "Sprite 1",
	1: "Sprite 2",
	2: "Sprite 3",
	3: "Sprite 4",
	4: "Sprite 5",
	5: "Sprite 6",
	6: "Sprite 7",
	7: "Sprite 8",
	8: "Portrait 1",
	9: "Portrait 2",
	10: "Portrait 3",
	11: "Portrait 4",
	12: "Portrait 5",
	13: "Portrait 6",
	14: "Portrait 7",
	15: "Portrait 8"
}

var preview_image: Image = Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
var import_image: Image = Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)

var import_sizes:Dictionary = {}
var portrait_import_sizes: Dictionary = {
	"Horizontal":Vector2i(48, 32),
	"Vertical":Vector2i(32, 48)
}
var palette_import_sizes: Dictionary = {
	"4bpp":Vector2i(16, 1),
	"8bpp":Vector2i(16, 16)
}

var offset_presets: Dictionary = {}
var portrait_offset_presets: Dictionary = {
	"Horizontal":Vector2i(80, 456),
	"Vertical (Zero)":Vector2i(0, 0)
}
var palette_offset_presets: Dictionary = {
	"Zero":Vector2i(0, 0)
}

var import_size: Vector2i = Vector2i(8, 8):
	get:
		return Vector2i(size_x_spinbox.value, size_y_spinbox.value)

var offset_base: Vector2i = Vector2i.ZERO
var import_offset: Vector2i = Vector2i.ZERO:
	get:
		return Vector2i(offset_base.x + offset_x_spinbox.value, offset_base.y + offset_y_spinbox.value)

var default_zoom:Dictionary = {
	ImportTab.PORTRAIT: Vector2(0.6, 0.6),
	ImportTab.PALETTE: Vector2(1.2, 1.2)
}


func initialize():
	get_ok_button().disabled = true
	
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
	import_sizes[ImportTab.PALETTE] = palette_import_sizes
	
	offset_presets[ImportTab.PORTRAIT] = portrait_offset_presets
	offset_presets[ImportTab.PALETTE] = palette_offset_presets
	
	if tab_container.current_tab == -1:
		tab_container.select_next_available()
	_on_tab_container_tab_changed(tab_container.current_tab)
	
	sprite_preview.material.set_shader_parameter("palette", main.palette_texture)

func initialize_palette_import() -> void:
	show_palette_previews(bmp)

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
	bmp = Bmp.new(bmp_file, path.get_file())
	
	if bmp.num_pixels > 0 or bmp.color_palette.size() > 0:
		get_ok_button().disabled = false
	else:
		get_ok_button().disabled = true
		return
	
	original_palette = bmp.color_palette.duplicate()
	original_indices = bmp.color_indices.duplicate()
	
	if tab_container.current_tab == 0: # portrait
		portrait_file_name_line.text = bmp.file_name
		if get_ok_button().pressed.is_connected(import_palettes):
			get_ok_button().pressed.disconnect(import_palettes)
		get_ok_button().pressed.connect(import_portrait)
		create_import_image()
	elif tab_container.current_tab == 1: # palette
		palette_file_name_line.text = bmp.file_name
		if get_ok_button().pressed.is_connected(import_portrait):
			get_ok_button().pressed.disconnect(import_portrait)
		if not get_ok_button().pressed.is_connected(import_palettes):
			get_ok_button().pressed.connect(import_palettes)
		
		show_palette_previews(bmp)

func create_import_image() -> Image:
	#import_image = Image.load_from_file(path)
	#import_image.convert(Image.FORMAT_RGBA8)
	if bmp.num_pixels == 0:
		import_image = Image.create_empty(0, 0, false, Image.FORMAT_RGBA8)
		create_preview_image()
		return import_image
	
	if swap_palette_options.selected == 0: # don't swap
		bmp.color_palette = original_palette.duplicate()
		bmp.color_indices = original_indices.duplicate()
		bmp.set_colors_by_indices()
	elif swap_palette_options.selected > 0:
		var new_palette: Array[Color] = []
		
		var palette_offset:int = (swap_palette_options.selected - 1) * 16
		new_palette.resize(bmp.color_palette.size())
		new_palette.fill(Color.BLACK)
		for i in bmp.color_palette.size():
			new_palette[i] = Palettes.current_palette.colors[i + palette_offset].color
		
		bmp.color_palette = new_palette
	
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
	if import_sizes[tab_container.current_tab].has(text):
		size_x_spinbox.editable = false
		size_y_spinbox.editable = false
		
		size_x_spinbox.value = import_sizes[tab_container.current_tab][text].x
		size_y_spinbox.value = import_sizes[tab_container.current_tab][text].y
	else:
		size_x_spinbox.editable = true
		size_y_spinbox.editable = true

func _on_offset_options_item_selected(index: int) -> void:
	var text: String = offset_selector.get_item_text(index)
	if offset_presets[tab_container.current_tab].has(text):
		offset_x_spinbox.editable = false
		offset_y_spinbox.editable = false
		
		offset_x_spinbox.value = offset_presets[tab_container.current_tab][text].x
		offset_y_spinbox.value = offset_presets[tab_container.current_tab][text].y
	else:
		offset_x_spinbox.editable = true
		offset_y_spinbox.editable = true


func import_portrait() -> void:
	if tab_container.current_tab == 0:
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
	path_dialog_popup.current_dir = main.api.project.current_project.export_directory_path
	
	path_dialog_popup.popup_centered()


func _on_path_dialog_canceled() -> void:
	# Needed because if native file dialogs are enabled
	# the export dialog closes when the path dialog closes
	if not visible:
		show()


func _on_tab_container_tab_changed(tab_idx: int) -> void:
	bmp = Bmp.new()
	
	if tab_idx == 0:
		portrait_file_name_line.text = ""
		
		offset_selector.clear()
		for key in offset_presets[tab_container.current_tab].keys():
			offset_selector.add_item(key)
		offset_selector.add_item("Custom")
		
		if size_selector.item_count > 0:
			size_selector.select(0)
			size_selector.item_selected.emit(0)
		
		if offset_selector.item_count > 0:
			offset_selector.select(0)
			offset_selector.item_selected.emit(0)
		
		preview_camera.offset = Vector2.ZERO
		preview_camera.zoom = default_zoom[tab_container.current_tab]
		
		create_checker_overlay()
		create_import_image()
		#create_preview_image()
	elif tab_idx == 1:
		palette_file_name_line.text = ""
		
		for child in palette_preview_grid.get_children():
			child.queue_free()
		
		initialize_palette_import()



func _on_rotated_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		import_image.rotate_90(CLOCKWISE)
	else:
		import_image.rotate_90(COUNTERCLOCKWISE)
	_on_size_value_changed(0)


func _on_path_dialog_file_selected(path: String) -> void:
	main.api.project.current_project.export_directory_path = path.get_base_dir()
	
	get_bmp_data(path)


func _on_swap_palette_options_item_selected(index: int) -> void:
	#sprite_preview.material.set_shader_parameter("palette_offset", swap_palette_options.selected + 1)
	create_import_image()


func show_palette_previews(preview_bmp:Bmp) -> void:
	for child in palette_preview_grid.get_children():
		child.queue_free()
	
	if not is_instance_valid(preview_bmp):
		return
	if preview_bmp.num_pixels == 0:
		return
	
	var palettes: Array = []
	
	if full_palette.button_pressed:
		var palette_preview:PalettePreview = PalettePreview.new(preview_bmp.file_name.get_slice(".", 0) + "_full", preview_bmp.color_palette, 16)
		palettes.append(palette_preview)
	
	if split_palette.button_pressed:
		for palette_index:int in ceil(preview_bmp.color_palette.size()/float(split_size.value)):
			var new_palette:Array[Color] = []
			new_palette.resize(split_size.value)
			new_palette.fill(Color.BLACK)
			
			for color_index in split_size.value:
				var bmp_color_index = color_index + (split_size.value * palette_index)
				if bmp_color_index >= preview_bmp.color_palette.size():
					break
				#print("Palette: " + str(palette_index + 1) + ", Color: " + str(color_index) + " - " + str(preview_bmp.color_palette[color_index + (split_size.value * palette_index)]))
				new_palette[color_index] = preview_bmp.color_palette[bmp_color_index]
			
			var palette_preview:PalettePreview = PalettePreview.new(preview_bmp.file_name.get_slice(".", 0) + "_" + palette_labels[palette_index], new_palette, split_size.value)
			palettes.append(palette_preview)
	
	
	for palette in palettes:
		palette_preview_grid.add_child(palette.name_label)
		palette_preview_grid.add_child(palette.palette_grid)


func import_palettes() -> void:
	for palette_index in palette_preview_grid.get_child_count()/2:
		var palette_label:Label = palette_preview_grid.get_child(palette_index * 2)
		var palette_name:String = palette_label.text
		
		var color_grid:GridContainer = palette_preview_grid.get_child(1 + (palette_index * 2))
		var num_colors:int = color_grid.get_child_count()
		var colors:Array[Color] = []
		colors.resize(num_colors)
		
		
		for color_index in num_colors:
			var color_rect:ColorRect = color_grid.get_child(color_index).get_child(0)
			#push_warning(color_rect.color)
			colors[color_index] = color_rect.color
		
		#Palettes.create_new_palette(Palettes.NewPalettePresetType.EMPTY, palette_name, "Imported from " + bmp.file_name, color_grid.columns, ceil(float(colors.size())/color_grid.columns), true, Palettes.GetColorsFrom.CURRENT_CEL)
		#Palettes.select_palette(palette_name)
		
		var width:int = color_grid.columns
		var height:int = ceil(float(colors.size())/color_grid.columns)
		Palettes._check_palette_settings_values(palette_name, width, height)
		var new_palette := Palette.new(palette_name, width, height, "Imported from " + bmp.file_name)
		Palettes.palettes[palette_name] = new_palette
		
		for color_index in num_colors:
			#push_warning(colors[color_index])
			Palettes.palettes[palette_name].colors[color_index] = Palette.PaletteColor.new(colors[color_index], color_index)
			#Palettes.palettes[palette_name].add_color(colors[color_index])
			#Palettes.current_palette.set_color(color_index, colors[color_index])
		
		Palettes.palettes[palette_name].data_changed.emit()
		Palettes.save_palette(Palettes.palettes[palette_name])
		
	Palettes.new_palette_created.emit()
	hide()


func _on_full_palette_toggled(toggled_on: bool) -> void:
	show_palette_previews(bmp)


func _on_split_palette_toggled(toggled_on: bool) -> void:
	show_palette_previews(bmp)


func _on_split_size_value_changed(value: float) -> void:
	show_palette_previews(bmp)
	

class PalettePreview:
	var name_label:Label = Label.new()
	var palette_grid:GridContainer = GridContainer.new()
	
	var name:String = "":
		set(value):
			name = value
			name_label.text = value
	
	func _init(new_name:String, colors:PackedColorArray, width:int = 16):
		name = new_name
		palette_grid.columns = width
		
		var swatch_size:int = 15
		var border_size:int = 2
		
		for color in colors:
			var border_rect:ColorRect = ColorRect.new()
			border_rect.custom_minimum_size = Vector2i(swatch_size + (border_size * 2), swatch_size + (border_size * 2))
			border_rect.color = Color.BLACK
			
			var color_rect:ColorRect = ColorRect.new()
			color_rect.custom_minimum_size = Vector2i(swatch_size, swatch_size)
			color_rect.color = color.to_html()
			color_rect.position = Vector2i(border_size, border_size)
			
			palette_grid.add_child(border_rect)
			border_rect.add_child(color_rect)
	
	func destroy() -> void:
		name_label.queue_free()
		palette_grid.queue_free()
