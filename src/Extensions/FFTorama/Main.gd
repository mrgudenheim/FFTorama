extends Node

# NOTE: use get_node_or_null("/root/ExtensionsApi") to access the extension api.
@export var isReady: bool = false

@export_file("*.txt") var layer_priority_table_filepath: String
var layer_priority_table: Array = []
@export_file("*.txt") var weapon_table_filepath: String
var weapon_table: Array = []
@export_file("*.txt") var item_list_filepath: String
var item_list: Array = []

@export var seq_shape_data_node: Node
@export var theme_min_character_width: int = 3

# settings vars
# var settings = preload("res://src/Extensions/FFTorama/SavedSettings.gd").new()
@export_file("*.txt") var extension_layout_path: String = "res://src/Extensions/FFTorama/FFTorama.txt"

var palette_texture: ImageTexture
@export var export_viewport: SubViewport
@export var export_texture: TextureRect

@export var settings_container: Control
@export var weapon_selector: OptionButton
@export var item_selector: OptionButton

@export var cel_frame_selector: OptionButton
@export var cel_layer_selector: OptionButton
@export var sp2_frame_selector: OptionButton
@export var sp2_layer_selector: OptionButton
@export var weapon_frame_selector: OptionButton
@export var weapon_layer_selector: OptionButton
@export var effect_frame_selector: OptionButton
@export var effect_layer_selector: OptionButton
@export var item_frame_selector: OptionButton
@export var item_layer_selector: OptionButton
@export var other_frame_selector: OptionButton
@export var other_layer_selector: OptionButton
@export var other_type_selector: OptionButton
@export var weapon_frame: int = 0
@export var weapon_layer: int = 0
@export var weapon_type: int = 1
@export var effect_frame: int = 0
@export var effect_layer: int = 0
@export var effect_type: int = 1
@export var item_frame: int = 0
@export var item_layer: int = 0
@export var other_frame: int = 0
@export var other_layer: int = 0
@export var other_type_index: int = 0

@export var use_separate_sp2: bool = false
@export var sp2_start_frame_id: int = 43
@export var use_frame_id_for_sp2_offset: bool = false
@export var sp2_start_animation_id: int = 194
@export var sp2_v_offset: int = 232 # pixels
@export var sp2_v_offset2: int = 256 # pixels
@export var use_hardcoded_offsets: bool = false
var constant_sp2_v_offsets: Dictionary = {
	234: sp2_v_offset,
	235: sp2_v_offset,
	236: sp2_v_offset + (sp2_v_offset2 * 1),
	237: sp2_v_offset + (sp2_v_offset2 * 1),
	232: sp2_v_offset + (sp2_v_offset2 * 2),
	233: sp2_v_offset + (sp2_v_offset2 * 2),
	230: sp2_v_offset + (sp2_v_offset2 * 3),
	231: sp2_v_offset + (sp2_v_offset2 * 3)}

var display_cel_selector: CelSelector
var sp2_cel_selector: CelSelector

@export var select_frame: bool = true
@export var use_current_cel: bool = true
var auto_select_shape: bool = true:
	set(value):
		auto_select_shape = value
		# TODO update UI checkbox

@export var submerged_depth_options: OptionButton
@export var face_right_check: CheckBox

# frame vars
@onready var assembled_frame_viewport = $MarginAssembledFrame/AssembledFrame/AssembledFrameViewportContainer
var assembled_frame_node: Node2D
@export var assembled_frame_container: Control
@export var spritesheet_type_selector: OptionButton
@export var frame_id_spinbox: SpinBox

var all_frame_data: Dictionary = {}
var all_frame_offsets_data: Dictionary = {}
var global_spritesheet_type: Shp = Shp.new()

@export var global_frame_id: int = 0:
	get:
			return global_frame_id
	set(value):
		if (value != global_frame_id):
			global_frame_id = value
			_on_frame_changed(value)

# animation vars
@onready var assembled_animation_viewport = $MarginAssembledAnimation/AssembledAnimation/SubViewportContainer
var assembled_animation_primary: Sprite2D
@export var assembled_animation_container: Control
@export var animation_type_selector: OptionButton
@export var animation_id_spinbox: SpinBox
@export var animation_name_selector: OptionButton
@export var animation_frame_slider: Slider
@export var animation_speed_spinbox: SpinBox
@export var frame_id_text: LineEdit

var all_animation_data: Dictionary = {}
var all_animation_names: Dictionary = {}
var global_fft_animation := FftAnimation.new()
var global_animation_type := Seq.new()
@export var animation_is_playing: bool = true
@export var animation_speed: float = 60 # frames per sec
var opcode_frame_offset: int = 0
var weapon_sheathe_check1_delay: int = 0
var weapon_sheathe_check2_delay: int = 10
var wait_for_input_delay: int = 10
var item_index: int = 0
var weapon_v_offset: int = 0 # v_offset to lookup for weapon frames
var global_weapon_frame_offset_index: int = 0: # index to lookup frame offset for wep and eff animations
	get:
		return global_weapon_frame_offset_index
	set(value):
		if (value != global_weapon_frame_offset_index):
			global_weapon_frame_offset_index = value
			if global_animation_type != null: # check if data is ready
				_on_animation_changed()

@export var global_animation_id: int = 0:
	get:
		return global_animation_id
	set(value):
		if (value != global_animation_id):
			global_animation_id = value
			animation_name_selector.select(value)
			_on_animation_changed()
			#if isReady:
				#if not global_fft_animation.sequence.seq_parts[0].isOpcode:
					#frame_id_spinbox.value = global_fft_animation.sequence.seq_parts[0].parameters[0]

@export var animation_frame_id: int = 0:
	get:
		return animation_frame_id
	set(value):
		if (value != animation_frame_id):
			animation_frame_id = value
			if (!animation_is_playing): # don't emit signal when constantly playing
				animation_frame_slider.value = value # update animation_frame slider


@export var background_color: Color = Color.BLACK:
	get:
		return background_color
	set(value):
		if (value != background_color):
			background_color = value
			set_background_color(value);

var frame_size: Vector2i:
	get:
		if (global_spritesheet_type.file_name.to_lower().contains("kanzen") or global_spritesheet_type.file_name.to_lower().contains("arute")):
			return Vector2i(120, 180)
		else:
			return Vector2i(120, 120)

const Animation_types := {
	TYPE1 = "type1",
	TYPE2 = "type2 (Unused)",
	TYPE3 = "type3",
	TYPE4 = "type4 (Unused)",
	ARUTE = "Altima/arute",
	CYOKO = "Chocobo/cyoko",
	EFF1 = "eff1",
	EFF2 = "eff2 (Unused)",
	KANZEN = "Altima2/kanzen",
	MON = "Monster/mon",
	OTHER = "other",
	RUKA = "Lucavi/ruka",
	WEP1 = "wep1",
	WEP2 = "wep2"
}

const Spritesheet_shapes := {
	TYPE1 = "type1",
	TYPE2 = "type2",
	ARUTE = "Altima/arute",
	CYOKO = "Chocobo/cyoko",
	EFF1 = "eff1",
	EFF2 = "eff2 (Unused)",
	KANZEN = "Altima2/kanzen",
	MON = "Monster/Lucavi/mon",
	OTHER = "other",
	WEP1 = "wep1",
	WEP2 = "wep2",
	ITEM = "item"
}

var animation_shape_lookup:Dictionary = {
	Animation_types.TYPE1: Spritesheet_shapes.TYPE1,
	Animation_types.TYPE2: Spritesheet_shapes.TYPE1,
	Animation_types.TYPE3: Spritesheet_shapes.TYPE2,
	Animation_types.TYPE4: Spritesheet_shapes.TYPE2,
	Animation_types.CYOKO: Spritesheet_shapes.CYOKO,
	Animation_types.MON: Spritesheet_shapes.MON,
	Animation_types.OTHER: Spritesheet_shapes.OTHER,
	Animation_types.RUKA: Spritesheet_shapes.MON,
	Animation_types.ARUTE: Spritesheet_shapes.ARUTE,
	Animation_types.KANZEN: Spritesheet_shapes.KANZEN,
	Animation_types.WEP1: Spritesheet_shapes.WEP1,
	Animation_types.WEP2: Spritesheet_shapes.WEP2,
	Animation_types.EFF1: Spritesheet_shapes.EFF1,
	Animation_types.EFF2: Spritesheet_shapes.EFF2
}


# signals
signal frame_changed(frame_id: int)
signal animation_changed(animation_id: int)
signal animation_frame_changed(animation_frame_id: int)


# Runs as soon as extension is enabled. This script can act as a setup for the extension.
func _enter_tree() -> void:
	pass


func _exit_tree() -> void:  # Extension is being uninstalled or disabled
	# remember to remove things that you added using this extension
	ExtensionsApi.panel.remove_node_from_tab(assembled_frame_container)
	ExtensionsApi.panel.remove_node_from_tab(assembled_animation_container)
	ExtensionsApi.panel.remove_node_from_tab(settings_container)
	
	ExtensionsApi.signals.signal_current_cel_texture_changed(update_assembled_frame, true)
	ExtensionsApi.signals.signal_cel_switched(_on_current_cel_switched, true)
	# api.signals.signal_project_data_changed(initialize, true)
	ExtensionsApi.signals.signal_project_switched(initialize, true)
	ExtensionsApi.project.current_project.timeline_updated.disconnect(set_frame_layer_selectors_options)
	#assembled_frame_container.queue_free()


func _ready():
	isReady = false
	
	seq_shape_data_node.load_data()
	#all_frame_data = seq_shape_data_node.all_shape_data
	all_frame_data = seq_shape_data_node.all_shp_data
	all_frame_offsets_data = seq_shape_data_node.all_offsets_data
	all_animation_data = seq_shape_data_node.all_seq_data
	all_animation_names = seq_shape_data_node.animation_names
	
	#api = get_node_or_null("/root/ExtensionsApi")
	
	# api.signals.signal_project_data_changed(initialize)
	ExtensionsApi.signals.signal_project_switched(initialize)
	Palettes.palette_selected.connect(func(palette_name): _on_new_palette_selected())
	
	# add panels
	assembled_frame_container.visible = true
	remove_child(assembled_frame_container)
	ExtensionsApi.panel.add_node_as_tab(assembled_frame_container)
	assembled_frame_container.name = "Assembled Frame"
	
	assembled_animation_container.visible = true
	remove_child(assembled_animation_container)
	ExtensionsApi.panel.add_node_as_tab(assembled_animation_container)
	assembled_animation_container.name = "Assembled Animation"
	
	settings_container.visible = true
	remove_child(settings_container)
	ExtensionsApi.panel.add_node_as_tab(settings_container)
	settings_container.name = "FFT Settings"
	
	layer_priority_table = load_csv(layer_priority_table_filepath)
	weapon_table = load_csv(weapon_table_filepath)
	item_list = load_csv(item_list_filepath)
	
	assembled_frame_node = assembled_frame_viewport.sprite_primary
	assembled_animation_primary = assembled_animation_viewport.sprite_primary
	
	ExtensionsApi.signals.signal_current_cel_texture_changed(update_assembled_frame)
	ExtensionsApi.signals.signal_cel_switched(_on_current_cel_switched)
	
	set_sheet_and_animation_selector_options()
	
	# add layout
	var pixelorama_layout_path: String = ExtensionsApi.general.get_global().LAYOUT_DIR.path_join(extension_layout_path.get_file().trim_suffix(".txt") + ".tres")
	var dir := DirAccess.open(ExtensionsApi.general.get_global().LAYOUT_DIR)
	var layout_exists:bool = dir.file_exists(pixelorama_layout_path)
	
	# load layout txt, save as .tres, and reload
	if not layout_exists:
		var file = FileAccess.open(extension_layout_path, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var layout_content = file.get_as_text()
			file.close()
			file = FileAccess.open(pixelorama_layout_path, FileAccess.WRITE)
			if FileAccess.get_open_error() != OK:
				print("Error: 2 ", error_string(FileAccess.get_open_error()))
			file.store_string(layout_content)
			file.close()
		if FileAccess.get_open_error() != OK:
				print("Error: 2 ", error_string(FileAccess.get_open_error()))
		
		var extension_layout = ResourceLoader.load(pixelorama_layout_path)
		
		if extension_layout is DockableLayout:
			ExtensionsApi.general.get_global().layouts.append(extension_layout)
			if is_instance_valid(ExtensionsApi.general.get_global().control.main_ui): # prevent crash when extension is already enabled but extension_layout does not exist
				ExtensionsApi.general.get_global().control.main_ui.layout = extension_layout
		else:
			print_debug("Layout should be a DockableLayout: " + extension_layout_path)
	
	initialize()


func initialize():
	isReady = false
	
	display_cel_selector = CelSelector.new(cel_frame_selector, cel_layer_selector, self)
	sp2_cel_selector = CelSelector.new(sp2_frame_selector, sp2_layer_selector, self)
	
	if not display_cel_selector.cel_frame_selector.item_selected.is_connected(_on_cel_selection_changed):
		display_cel_selector.cel_frame_selector.item_selected.connect(_on_cel_selection_changed)
	if not display_cel_selector.cel_layer_selector.item_selected.is_connected(_on_cel_selection_changed):
		display_cel_selector.cel_layer_selector.item_selected.connect(_on_cel_selection_changed)
	
	if not ExtensionsApi.project.current_project.timeline_updated.is_connected(set_frame_layer_selectors_options):
		ExtensionsApi.project.current_project.timeline_updated.connect(set_frame_layer_selectors_options)
	
	load_settings()
	
	set_background_color(background_color)
	
	# initialize assembled frame
	for index in spritesheet_type_selector.item_count:
		if spritesheet_type_selector.get_item_text(index) == global_spritesheet_type.name_alias:
			spritesheet_type_selector.select(index)
			_on_spritesheet_type_option_button_item_selected(index)
	
	# spritesheet_type_selector.select(7) # initialize sprite to type1
	# _on_spritesheet_type_option_button_item_selected(7) # initialize sprite type
	frame_id_spinbox.value = global_frame_id; # emits frame changed signal that call select_subrames and?
	
	
	# initialize assembled animation
	for index in animation_type_selector.item_count:
		if animation_type_selector.get_item_text(index) == global_animation_type.name_alias:
			animation_type_selector.select(index)
			_on_animations_type_option_button_item_selected(index)
	
	# animation_type_selector.select(8) # initialize animation type to type1
	# _on_animations_type_option_button_item_selected(8) # initialize sprite type
	animation_id_spinbox.value = global_animation_id; # emits signal?
	
	set_animation_name_options(global_animation_type)
	
	# initialize settings panel
	set_weapon_selector_options()
	weapon_selector.select(weapon_type)
	set_item_selector_options()
	item_selector.select(item_index)
	
	set_frame_layer_selectors_options()
	
	
	isReady = true
	var pixelorama_is_ready: bool = ExtensionsApi.general.get_global().frame_hbox.get_child_count() >= ExtensionsApi.project.current_project.frames.size() # prevent crash due to null reference when switching projects
	if pixelorama_is_ready and (ExtensionsApi.project.current_project.frames.size() > 1 or ExtensionsApi.project.current_project.layers.size() > 1):
		ExtensionsApi.project.select_cels([[display_cel_selector.cel_frame, display_cel_selector.cel_layer]])
		
		_on_new_palette_selected()
	
	
	#await get_tree().process_frame
	#override_themes()


func set_animation_name_options(animation_type: Seq):
	# set animation name options
	animation_name_selector.clear()
	
	for seq_index:int in animation_type.sequences.size():
		var seq_name:String = str(seq_index)
		if Seq.seq_names.has(animation_type.name_alias):
			if Seq.seq_names[animation_type.name_alias].has(seq_index):
				seq_name = Seq.seq_names[animation_type.name_alias][seq_index]
		animation_name_selector.add_item(str(seq_index) + " " + seq_name)
	
	#for key in all_animation_names.keys():
		#var key_text:PackedStringArray = key.split(" ")
		#if key_text[0] == animation_type.name_alias:
			#animation_name_selector.add_item(key_text[1] + " " + all_animation_names[key])
	
	if global_animation_id < animation_name_selector.item_count:
		animation_name_selector.select(global_animation_id)
	elif animation_name_selector.item_count >= 1:
		animation_name_selector.select(0)
	else:
		animation_name_selector.select(-1)
		print_debug("No animation names...")
		push_warning("No animation names...")


func select_subframes(frame_index: int, shp: Shp):
	if (!all_frame_data.has(shp.name_alias)):
		return
	if not (frame_index >= 0 and frame_index < shp.frames.size()):
		return
	
	var v_offset:int = 0
	
	ExtensionsApi.selection.clear_selection()
	#print(all_frames[frame_index][0])
	#var frame:Array = all_frame_data[spritesheet_type][frame_index]
	#var frame:Array = all_frame_data[spritesheet_type].frames[frame_index]
	for subframe_index:int in shp.get_frame(frame_index, submerged_depth_options.selected).num_subframes:
		v_offset = get_v_offset(shp, frame_index, subframe_index, global_animation_id)
		#var subframe_data = frame[subframe_index + 2] # skip past num_subframe and rotation_degrees
		## var x_shift: int = 		subframe_data[0] # not used here
		## var y_shift: int = 		subframe_data[1] # not used here
		#var x_top_left: int = 	subframe_data[2]
		#var y_top_left: int = 	subframe_data[3] + v_offset
		#var size_x: int = 		subframe_data[4]
		#var size_y: int = 		subframe_data[5]
		
		var x_top_left: int = 	shp.get_frame(frame_index, submerged_depth_options.selected).subframes[subframe_index].load_location_x
		var y_top_left: int = 	shp.get_frame(frame_index, submerged_depth_options.selected).subframes[subframe_index].load_location_y + v_offset
		var size_x: int = 		shp.get_frame(frame_index, submerged_depth_options.selected).subframes[subframe_index].rect_size.x
		var size_y: int = 		shp.get_frame(frame_index, submerged_depth_options.selected).subframes[subframe_index].rect_size.y
		
		var subframeRect: Rect2i = Rect2i(x_top_left, y_top_left, size_x, size_y)
		#print(subframeRect)
		ExtensionsApi.selection.select_rect(subframeRect, 0)


func create_blank_frame(color: Color = Color.TRANSPARENT) -> Image:
	var blank_image: Image = Image.create(
		frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8
	)
	blank_image.fill(color)
	
	return blank_image


func get_assembled_frame(frame_index: int, shp:Shp, cel: PixelCel, animation_index:int = 0) -> Image:
	var assembled_image: Image = create_blank_frame()
	
	# print_debug(str(shape) + " " + str(frame_index) + " " + str(v_offset))
	if frame_index >= shp.frames.size(): # high frame offsets (such as shuriken) can only be used with certain animations
		return create_blank_frame()
	
	var frame:FrameData = shp.get_frame(frame_index, submerged_depth_options.selected)
	var num_subframes: int = frame.num_subframes
	
	var spritesheet: Image = cel.get_content()
	var source_image: Image = swap_image_color(spritesheet, Vector2i.ZERO, Color.TRANSPARENT)
	#var source_image: Image = spritesheet
	
	for subframe_index in range(num_subframes-1, -1, -1): # reverse order to layer them correctly 
		var v_offset:int = get_v_offset(shp, frame_index, subframe_index, animation_index)	
		
		var subframe_in_bottom:bool = frame_index >= shp.attack_start_index
		var use_sp2:bool = (shp.file_name.contains("mon") 
			and subframe_in_bottom 
			and not use_frame_id_for_sp2_offset 
			and use_separate_sp2 
			and animation_index >= sp2_start_animation_id)
		if use_sp2:
			source_image = swap_image_color(sp2_cel_selector.cel.get_content(), Vector2i.ZERO, Color.TRANSPARENT)
			#source_image = sp2_cel_selector.cel.get_content()
		
		assembled_image = add_subframe(frame.subframes[subframe_index], assembled_image, source_image, v_offset)
	
	return assembled_image


func get_v_offset(shp: Shp, frame_index:int, subframe_index:int = 0, animation_index:int = 0) -> int:
	var v_offset:int = 0
	var y_top = shp.get_frame(frame_index, submerged_depth_options.selected).subframes[subframe_index].load_location_y
	if frame_index >= shp.attack_start_index:
		v_offset += 256
	
	if shp.file_name.contains("wep"):
		v_offset = weapon_v_offset
	elif shp.file_name.contains("other"):
		v_offset = other_type_index * 24 * 2 # 2 rows each of chicken and frog frames
	elif shp.file_name.contains("mon") and use_frame_id_for_sp2_offset and frame_index >= sp2_start_frame_id: # game uses animation index, not the frame index to determine sp2 lookup
		if use_separate_sp2:
			v_offset = -256
		else:
			v_offset = sp2_v_offset
		# var sp_num:int = (frame_index/sp2_start_frame_id)
		# if sp_num <= 1:
		# 	v_offset = sp2_v_offset * sp_num
		# else:
		# 	v_offset = sp2_v_offset + (sp2_v_offset2 * (sp_num - 1))
	elif shp.file_name.contains("mon") and y_top >= 256 and not use_frame_id_for_sp2_offset: # if y_top left is in bottom half, check if it should look into sp2
		if use_separate_sp2 and animation_index >= sp2_start_animation_id:
			v_offset = -256
		elif use_hardcoded_offsets && constant_sp2_v_offsets.has(animation_index):
			v_offset = constant_sp2_v_offsets[animation_index]
		elif animation_index >= sp2_start_animation_id:
			v_offset = sp2_v_offset
	
	
	return v_offset


func add_subframe(subframe: SubFrameData, assembled_image: Image, source_image:Image, v_offset:int) -> Image:
	var index_offset: int = 2 # skip past num_subframes and rotation_degrees
	var x_shift: int = 		subframe.shift_x
	var y_shift: int = 		subframe.shift_y
	var x_top_left: int = 	subframe.load_location_x
	var y_top_left: int = 	subframe.load_location_y + v_offset
	var size_x: int = 		subframe.rect_size.x
	var size_y: int = 		subframe.rect_size.y
	var flip_x : bool = 		subframe.flip_x
	var flip_y : bool = 		subframe.flip_y
	
	var destination_pos: Vector2i = Vector2i(x_shift + (frame_size.x / 2), y_shift + frame_size.y - 40) # adjust by 40 to prevent frame from spilling over bottom
	var source_rect: Rect2i = Rect2i(x_top_left, y_top_left, size_x, size_y)
	
	if (flip_x or flip_y):
		var flipped_image: Image = Image.create(
			source_rect.size.x, source_rect.size.y, false, Image.FORMAT_RGBA8
		)
		flipped_image.blend_rect(source_image, source_rect, Vector2i.ZERO)
		if (flip_x):
			flipped_image.flip_x()
		if (flip_y):
			flipped_image.flip_y()
		
		source_rect = Rect2i(0, 0, size_x, size_y)
		source_image = flipped_image
	
	assembled_image.blend_rect(source_image, source_rect, destination_pos)
	#assembled_image.blit_rect(source_image, source_rect, destination_pos)
	return assembled_image


func draw_assembled_frame(frame_index: int, shp: Shp, cel: PixelCel):
	if (!all_frame_data.has(shp.name_alias)):
		return
	if display_cel_selector.cel_frame_selector.item_count == 0 or display_cel_selector.cel_layer_selector.item_count == 0:
		return
	if cel == null:
		return
	
	var assembled_image: Image = get_assembled_frame(frame_index, shp, cel, global_animation_id)
	assembled_frame_node.texture = ImageTexture.create_from_image(assembled_image)
	var rotation: float = shp.get_frame(frame_index, submerged_depth_options.selected).y_rotation
	(assembled_frame_node.get_parent() as Node2D).rotation_degrees = rotation


func start_animation(fft_animation: FftAnimation, draw_target: Sprite2D, is_playing: bool, isLooping: bool, force_loop: bool = false) -> void:
	var num_parts: int = fft_animation.sequence.seq_parts.size()
	
	var only_opcodes: bool = true
	for animation_part in fft_animation.sequence.seq_parts:
		if not animation_part.isOpcode:
			only_opcodes = false
			break
	
	# don't loop when no parts, only 1 part, or all parts are opcodes
	if (num_parts == 0 or only_opcodes): # TODO only_opcodes should play instead of showing a blank image, ie. if only a loop, but need to handle broken MON MFItem animation infinite loop
		# draw a blank image
		var assembled_image: Image = create_blank_frame()
		assembled_animation_primary.texture = ImageTexture.create_from_image(assembled_image)
		await get_tree().create_timer(.001).timeout # prevent infinite loop from Wait opcodes looping only opcodes
		return
	elif (num_parts == 1 and not force_loop):
		process_seq_part(fft_animation, 0, draw_target)
		return
	
	if (is_playing):
		await play_animation(fft_animation, draw_target, isLooping)
	else:
		process_seq_part(fft_animation, 0, draw_target)


func play_animation(fft_animation: FftAnimation, draw_target: Sprite2D, isLooping: bool):
	for animation_part_id:int in fft_animation.sequence.seq_parts.size():
		var seq_part:SeqPart = fft_animation.sequence.seq_parts[animation_part_id]
		# break loop animation when stopped or on selected animation changed to prevent 2 loops playing at once
		if (isLooping and (!animation_is_playing 
				or fft_animation != global_fft_animation)):
			return
		
		await process_seq_part(fft_animation, animation_part_id, draw_target)
		
		if not seq_part.isOpcode:
			var delay_frames: int = seq_part.parameters[1]  # param 1 is delay
			var delay_sec: float = delay_frames / animation_speed
			await get_tree().create_timer(delay_sec).timeout
		
	if isLooping:
		play_animation(fft_animation, draw_target, isLooping)
	else: # clear image when animation is over
		draw_target.texture = ImageTexture.create_from_image(create_blank_frame())


func process_seq_part(fft_animation: FftAnimation, seq_part_id: int, draw_target:Node2D) -> void:
	# print_debug(str(animation) + " " + str(animation_part_id + 3))
	var seq_part:SeqPart = fft_animation.sequence.seq_parts[seq_part_id]
	
	var frame_id_label:String = ""
	if seq_part.isOpcode:
		frame_id_label = seq_part.to_string()
	else:
		frame_id_label = str(seq_part.parameters[0])
	
	#var new_anim_opcode_part_id: int = 0
	if fft_animation.primary_anim_opcode_part_id == 0:
		#primary_anim_opcode_part_id = fft_animation.sequence.seq_parts.size()
		fft_animation.primary_anim_opcode_part_id = fft_animation.sequence.seq_parts.size()
		#new_anim_opcode_part_id = fft_animation.sequence.seq_parts.size()
	
	# handle LoadFrameWait
	if not seq_part.isOpcode:
		var new_frame_id:int = seq_part.parameters[0]
		var frame_id_offset:int = get_animation_frame_offset(fft_animation.weapon_frame_offset_index, fft_animation.shp)
		new_frame_id = new_frame_id + frame_id_offset + opcode_frame_offset
		frame_id_label = str(new_frame_id)
	
		if new_frame_id >= fft_animation.shp.frames.size(): # high frame offsets (such as shuriken) can only be used with certain animations
			var assembled_image: Image = create_blank_frame()
			draw_target.texture = ImageTexture.create_from_image(assembled_image)
		else:
			var assembled_image: Image = get_assembled_frame(new_frame_id, fft_animation.shp, fft_animation.cel, global_animation_id)
			draw_target.texture = ImageTexture.create_from_image(assembled_image)
			var rotation: float = fft_animation.shp.get_frame(new_frame_id, fft_animation.submerged_depth).y_rotation
			(draw_target.get_parent() as Node2D).rotation_degrees = rotation
	
	# only update ui for primary animation, not animations called through opcodes
	if fft_animation.is_primary_anim:
		animation_frame_slider.value = seq_part_id
		frame_id_text.text = str(frame_id_label)
	
		if(select_frame and !animation_is_playing):
			frame_id_spinbox.value = global_frame_id # emits signal to update draw and selection
	
	var position_offset: Vector2 = Vector2.ZERO
	
	# Handle opcodes
	if seq_part.isOpcode:
		#print(anim_part_start)
		if seq_part.opcode_name == "QueueSpriteAnim":
			#print("Performing " + anim_part_start) 
			if seq_part.parameters[0] == 1: # play weapon animation
				# print_debug("playing weapon animation " + str(anim_part[2]))
				var weapon_cel: PixelCel = ExtensionsApi.project.get_cel_at(ExtensionsApi.project.current_project, weapon_frame, weapon_layer) as PixelCel
				if weapon_cel:
					push_warning("Cel at frame %s and layer %s is not a PixelCel" % [weapon_frame, weapon_layer])
				#var new_animation: Sequence = all_animation_data["wep" + str(weapon_type)].sequences[seq_part.parameters[1]]
				var new_animation := FftAnimation.new()
				new_animation.seq = all_animation_data[Shp.shp_aliases["wep" + str(weapon_type)]]
				new_animation.shp = all_frame_data[Shp.shp_aliases["wep" + str(weapon_type)]]
				new_animation.sequence = new_animation.seq.sequences[seq_part.parameters[1]]
				new_animation.cel = weapon_cel
				new_animation.is_primary_anim = false
				
				start_animation(new_animation, assembled_animation_viewport.sprite_weapon, true, false, false)
			elif seq_part.parameters[0] == 2: # play effect animation
				# print_debug("playing effect animation " + str(anim_part[2]))
				var eff_cel: PixelCel = ExtensionsApi.project.get_cel_at(ExtensionsApi.project.current_project, effect_frame, effect_layer) as PixelCel
				if eff_cel:
					push_warning("Cel at frame %s and layer %s is not a PixelCel" % [effect_frame, effect_layer])
				#var new_animation: Sequence = all_animation_data["eff" + str(effect_type)].sequences[seq_part.parameters[1]]
				var new_animation := FftAnimation.new()
				new_animation.seq = all_animation_data[Shp.shp_aliases["eff" + str(effect_type)]]
				new_animation.shp = all_frame_data[Shp.shp_aliases["eff" + str(effect_type)]]
				new_animation.sequence = new_animation.seq.sequences[seq_part.parameters[1]]
				new_animation.cel = eff_cel
				new_animation.is_primary_anim = false
				
				start_animation(new_animation, assembled_animation_viewport.sprite_effect, true, false, false)
			else:
				print_debug("Error: QueueSpriteAnim: " + seq_part.to_string() + "\n" + fft_animation.sequence.to_string())
				push_warning("Error: QueueSpriteAnim: " + seq_part.to_string() + "\n" + fft_animation.sequence.to_string())
		elif seq_part.opcode_name.begins_with("Move"):
			if seq_part.opcode_name == "MoveUnitFB":
				position_offset = Vector2(-(seq_part.parameters[0]), 0) # assume facing left
			elif seq_part.opcode_name == "MoveUnitDU":
				position_offset = Vector2(0, seq_part.parameters[0])
			elif seq_part.opcode_name == "MoveUnitRL":
				position_offset = Vector2(seq_part.parameters[0], 0)
			elif seq_part.opcode_name == "MoveUnitRLDUFB":
				position_offset = Vector2((seq_part.parameters[0]) - (seq_part.parameters[2]), seq_part.parameters[1]) # assume facing left
			elif seq_part.opcode_name == "MoveUp1":
				position_offset = Vector2(0, -1)
			elif seq_part.opcode_name == "MoveUp2":
				position_offset = Vector2(0, -2)
			elif seq_part.opcode_name == "MoveDown1":
				position_offset = Vector2(0, 1)
			elif seq_part.opcode_name == "MoveDown2":
				position_offset = Vector2(0, 2)
			elif seq_part.opcode_name == "MoveBackward1":
				position_offset = Vector2(1, 0) # assume facing left
			elif seq_part.opcode_name == "MoveBackward2":
				position_offset = Vector2(2, 0) # assume facing left
			elif seq_part.opcode_name == "MoveForward1":
				position_offset = Vector2(-1, 0) # assume facing left
			elif seq_part.opcode_name == "MoveForward2":
				position_offset = Vector2(-2, 0) # assume facing left
			else:
				print_debug("can't inerpret " + seq_part.opcode_name)
				push_warning("can't inerpret " + seq_part.opcode_name)
			(draw_target.get_parent().get_parent() as Node2D).position += position_offset
		elif seq_part.opcode_name == "SetLayerPriority":
			# print(layer_priority_table)
			var layer_priority: Array = layer_priority_table[seq_part.parameters[0]]
			for i in range(0, layer_priority.size() - 1):
				var layer_name = layer_priority[i + 1] # skip set_id
				if layer_name == "unit":
					assembled_animation_viewport.sprite_primary.z_index = -i
				elif layer_name == "weapon":
					assembled_animation_viewport.sprite_weapon.z_index = -i
				elif layer_name == "effect":
					assembled_animation_viewport.sprite_effect.z_index = -i
				elif layer_name == "text":
					assembled_animation_viewport.sprite_text.z_index = -i
		elif seq_part.opcode_name == "SetFrameOffset":
			opcode_frame_offset = seq_part.parameters[0] # use global var since SetFrameOffset is only used in animations that do not call other animations
		elif seq_part.opcode_name == "FlipHorizontal":
			assembled_animation_viewport.sprite_primary.flip_h = !assembled_animation_viewport.sprite_primary.flip_h
		elif seq_part.opcode_name == "UnloadMFItem":
			var target_sprite = assembled_animation_viewport.sprite_item
			target_sprite.texture = create_blank_frame()
			# reset any rotation or movement
			(target_sprite.get_parent() as Node2D).rotation_degrees = 0
			(target_sprite.get_parent() as Node2D).position = Vector2(0,0)
		elif seq_part.opcode_name == "MFItemPosFBDU":
			var target_sprite_pivot := assembled_animation_viewport.sprite_item.get_parent() as Node2D
			target_sprite_pivot.position = Vector2(-(seq_part.parameters[0]), (seq_part.parameters[1]) + 20) # assume facing left, add 20 because it is y position from bottom of unit
		elif seq_part.opcode_name == "LoadMFItem":
			var item_frame_id:int = item_index # assumes loading item
			var item_sheet_type:Shp = all_frame_data["item"]
			var item_cel = ExtensionsApi.project.get_cel_at(ExtensionsApi.project.current_project, item_frame, item_layer)
			
			if item_index >= 180:
				item_sheet_type = all_frame_data["other"]
				item_cel = ExtensionsApi.project.get_cel_at(ExtensionsApi.project.current_project, other_frame, other_layer)
				
				if item_index <= 187: # load crystal
					item_frame_id = item_index - 179
					other_type_selector.select(2) # to update ui
					other_type_index = 2 # to set v_offset is correct
				elif item_index == 188: # load chest 1
					item_frame_id = 15
					other_type_selector.select(0)
					other_type_index = 0
				elif item_index == 189: # load chest 2
					item_frame_id = 16
					other_type_selector.select(0)
					other_type_index = 0
			
			frame_id_label = str(item_index)
			
			var assembled_image: Image = get_assembled_frame(item_frame_id, item_sheet_type, item_cel)
			var target_sprite = assembled_animation_viewport.sprite_item
			target_sprite.texture = ImageTexture.create_from_image(assembled_image)
			var rotation: float = item_sheet_type.get_frame(item_frame_id, submerged_depth_options.selected).y_rotation
			(target_sprite.get_parent() as Node2D).rotation_degrees = rotation
		elif seq_part.opcode_name == "Wait":
			var loop_length: int = seq_part.parameters[0]
			var num_loops: int = seq_part.parameters[1]
			
			var primary_animation_part_id = seq_part_id + fft_animation.primary_anim_opcode_part_id - fft_animation.sequence.seq_parts.size()
			# print_debug(str(primary_animation_part_id) + "\t" + str(animation_part_id) + "\t" + str(primary_anim_opcode_part_id) + "\t" + str(animation.size() - 3))
			
			var temp_seq: Sequence = get_sub_animation(loop_length, primary_animation_part_id, fft_animation.parent_anim.sequence)
			var temp_fft_animation: FftAnimation = fft_animation.get_duplicate()
			temp_fft_animation.sequence = temp_seq
			temp_fft_animation.parent_anim = fft_animation
			temp_fft_animation.is_primary_anim = false
			temp_fft_animation.primary_anim_opcode_part_id = primary_animation_part_id
			
			for iteration in num_loops:
				await start_animation(temp_fft_animation, draw_target, true, false, true)
			
		elif seq_part.opcode_name == "IncrementLoop":
			pass # handled by animations looping by default
		elif seq_part.opcode_name == "WaitForInput":
			var delay_frames = wait_for_input_delay
			var loop_length: int = seq_part.parameters[0]
			var primary_animation_part_id = seq_part_id + fft_animation.primary_anim_opcode_part_id - fft_animation.sequence.seq_parts.size()
			var temp_seq: Sequence = get_sub_animation(loop_length, primary_animation_part_id, fft_animation.parent_anim.sequence)
			var temp_fft_animation: FftAnimation = fft_animation.get_duplicate()
			temp_fft_animation.sequence = temp_seq
			temp_fft_animation.parent_anim = fft_animation
			temp_fft_animation.is_primary_anim = false
			temp_fft_animation.primary_anim_opcode_part_id = primary_animation_part_id
			
			# print_debug(str(temp_anim))
			var timer: SceneTreeTimer = get_tree().create_timer(delay_frames / animation_speed)
			while timer.time_left > 0:
				# print(str(timer.time_left) + " " + str(temp_anim))
				await start_animation(temp_fft_animation, draw_target, true, false, true)
		elif seq_part.opcode_name.begins_with("WeaponSheatheCheck"):
			var delay_frames = weapon_sheathe_check1_delay
			if seq_part.opcode_name == "WeaponSheatheCheck2":
				delay_frames = weapon_sheathe_check2_delay
			
			var loop_length: int = seq_part.parameters[0]
			var primary_animation_part_id = seq_part_id + fft_animation.primary_anim_opcode_part_id - fft_animation.sequence.seq_parts.size()
			# print_debug(str(primary_animation_part_id) + "\t" + str(animation_part_id) + "\t" + str(primary_anim_opcode_part_id) + "\t" + str(animation.size() - 3))
			
			var temp_seq: Sequence = get_sub_animation(loop_length, primary_animation_part_id, fft_animation.parent_anim.sequence)
			var temp_fft_animation: FftAnimation = fft_animation.get_duplicate()
			temp_fft_animation.sequence = temp_seq
			temp_fft_animation.parent_anim = fft_animation
			temp_fft_animation.is_primary_anim = false
			temp_fft_animation.primary_anim_opcode_part_id = primary_animation_part_id
			
			# print_debug(str(temp_anim))
			var timer: SceneTreeTimer = get_tree().create_timer(delay_frames / animation_speed)
			while timer.time_left > 0:
				# print(str(timer.time_left) + " " + str(temp_anim))
				await start_animation(temp_fft_animation, draw_target, true, false, true)
		elif seq_part.opcode_name == "WaitForDistort":
			pass
		elif seq_part.opcode_name == "QueueDistortAnim":
			# https://ffhacktics.com/wiki/Animate_Unit_Distorts
			pass


func get_animation_frame_offset(weapon_frame_offset_index:int, shp:Shp) -> int:
	if ((shp.file_name.contains("wep") or shp.file_name.contains("eff"))
		and shp.zero_frames.size() > 0):
		return shp.zero_frames[weapon_frame_offset_index]
	else:
		return 0


func get_sub_animation(length:int, sub_animation_end_part_id:int, parent_animation:Sequence) -> Sequence:
	var sub_anim_length: int = 0
	var sub_anim: Sequence = Sequence.new()
	var previous_anim_part_id = sub_animation_end_part_id - 1
	
	# print_debug(str(animation) + "\n" + str(previous_anim_part_id))
	while sub_anim_length < abs(length):
		# print_debug(str(previous_anim_part_id) + "\t" + str(sub_anim_length) + "\t" + str(parent_animation[previous_anim_part_id + 3]) + "\t" + str(parent_animation[sub_animation_end_part_id + 3][0]))
		var previous_anim_part: SeqPart = parent_animation.seq_parts[previous_anim_part_id]
		sub_anim.seq_parts.insert(0, previous_anim_part)
		sub_anim_length += previous_anim_part.length
	
		previous_anim_part_id -= 1
	
	# add label, id, and num_parts
	sub_anim.seq_name = parent_animation.seq_name + ":" + str(sub_animation_end_part_id - length) + "-" + str(sub_animation_end_part_id)
	
	return sub_anim


func set_frame_layer_selectors_options():	
	var project = ExtensionsApi.project.current_project
	
	if display_cel_selector.cel_frame_selector.item_count == 0 or display_cel_selector.cel_layer_selector.item_count == 0:
		return
	
	weapon_frame_selector.clear()
	effect_frame_selector.clear()
	item_frame_selector.clear()
	other_frame_selector.clear()
	
	weapon_layer_selector.clear()
	effect_layer_selector.clear()
	item_layer_selector.clear()
	other_layer_selector.clear()
	
	for frame_index in project.frames.size():
		weapon_frame_selector.add_item(str(frame_index + 1))
		effect_frame_selector.add_item(str(frame_index + 1))
		item_frame_selector.add_item(str(frame_index + 1))
		other_frame_selector.add_item(str(frame_index + 1))
	
	for layer_index in project.layers.size():
		if !(project.layers[layer_index] is PixelLayer):
			continue
		weapon_layer_selector.add_item(project.layers[layer_index].name)
		effect_layer_selector.add_item(project.layers[layer_index].name)
		item_layer_selector.add_item(project.layers[layer_index].name)
		other_layer_selector.add_item(project.layers[layer_index].name)
	
	if weapon_frame >= weapon_frame_selector.item_count:
		weapon_frame = 0
	if effect_frame >= effect_frame_selector.item_count:
		effect_frame = 0
	if item_frame >= item_frame_selector.item_count:
		item_frame = 0
	if other_frame >= other_frame_selector.item_count:
		other_frame = 0
	
	if weapon_layer >= weapon_layer_selector.item_count:
		weapon_layer = 0
	if effect_layer >= effect_layer_selector.item_count:
		effect_layer = 0
	if item_layer >= item_layer_selector.item_count:
		item_layer = 0
	if other_layer >= other_layer_selector.item_count:
		other_layer = 0
		
	weapon_frame_selector.select(weapon_frame)
	effect_frame_selector.select(effect_frame)
	item_frame_selector.select(item_frame)
	other_frame_selector.select(other_frame)
	
	weapon_layer_selector.select(weapon_layer)
	effect_layer_selector.select(effect_layer)
	item_layer_selector.select(item_layer)
	other_layer_selector.select(other_layer)


func set_weapon_selector_options():
	weapon_selector.clear()
	
	for weapon_index in weapon_table.size():
		weapon_selector.add_item(str(weapon_table[weapon_index][0]))


func set_item_selector_options():
	item_selector.clear()
	
	for item_list_index in item_list.size():
		item_selector.add_item(str(item_list[item_list_index][1]))

func set_background_color(color):
	#push_warning("Setting background color: " + str(color))
	assembled_frame_viewport.sprite_background.texture = ImageTexture.create_from_image(create_blank_frame(color))
	assembled_animation_viewport.sprite_background.texture = ImageTexture.create_from_image(create_blank_frame(color))


func set_sheet_and_animation_selector_options():
	spritesheet_type_selector.clear()
	for type in all_frame_data.keys():
		spritesheet_type_selector.add_item(type)

	for selector_index in spritesheet_type_selector.item_count - 1:
		if spritesheet_type_selector.get_item_text(selector_index) == global_spritesheet_type.name_alias:
			spritesheet_type_selector.select(selector_index)

	animation_type_selector.clear()
	for type in all_animation_data.keys():
		animation_type_selector.add_item(type)

	for selector_index in animation_type_selector.item_count - 1:
		if animation_type_selector.get_item_text(selector_index) == global_animation_type.name_alias:
			animation_type_selector.select(selector_index)


func swap_image_color(source_image:Image, color_location:Vector2i, new_color:Color) -> Image:
	var color_to_switch:Color = source_image.get_pixelv(color_location)
	var new_image:Image = Image.create_empty(source_image.get_width(), source_image.get_height(), false, Image.FORMAT_RGBA8)
	
	for x in source_image.get_width():
		for y in source_image.get_height():
			if source_image.get_pixel(x, y) == color_to_switch:
				new_image.set_pixel(x, y, new_color)
			else:
				new_image.set_pixel(x, y, source_image.get_pixel(x, y))
	
	return new_image


func load_file(filepath:String) -> String:
	var file = FileAccess.open(filepath, FileAccess.READ)
	var content: String = file.get_as_text()
	return content


func load_csv(filepath) -> Array:
	var table: Array = []
	var file_contents = load_file(filepath)
	var lines: Array = file_contents.split("\r\n")
	if lines.size() == 1:
		lines = file_contents.split("\n")
	if lines.size() == 1:
		lines = file_contents.split("\r")
	#print(lines)

	for line_index in range(1,lines.size()): # skip first row of headers
		table.append(lines[line_index].split(","))

	return table


func save_settings():
	var settings = preload("res://src/Extensions/FFTorama/SavedSettings.gd").new()

	settings.weapon_frame = weapon_frame
	settings.weapon_layer = weapon_layer
	settings.weapon_type = weapon_type
	settings.effect_frame = effect_frame
	settings.effect_layer = effect_layer
	settings.effect_type = effect_type
	settings.item_frame = item_frame
	settings.item_layer = item_layer
	settings.other_frame = other_frame
	settings.other_layer = other_layer
	settings.other_type_index = other_type_index
	settings.use_separate_sp2 = use_separate_sp2
	settings.use_frame_id_for_sp2_offset = use_frame_id_for_sp2_offset
	settings.use_hardcoded_offsets = use_hardcoded_offsets	
	settings.select_frame = select_frame
	settings.use_current_cel = use_current_cel	
	settings.global_spritesheet_type = global_spritesheet_type.name_alias
	settings.global_frame_id = global_frame_id
	settings.global_animation_type = global_animation_type.name_alias
	settings.animation_is_playing = animation_is_playing
	settings.animation_speed = animation_speed
	settings.opcode_frame_offset = opcode_frame_offset
	settings.weapon_sheathe_check1_delay = weapon_sheathe_check1_delay
	settings.weapon_sheathe_check2_delay = weapon_sheathe_check2_delay
	settings.wait_for_input_delay = wait_for_input_delay
	settings.item_index = item_index
	settings.weapon_v_offset = weapon_v_offset
	settings.global_weapon_frame_offset_index = global_weapon_frame_offset_index
	settings.global_animation_id = global_animation_id	
	settings.background_color = background_color
	settings.auto_select_shape = auto_select_shape

	# CelSelector vars
	settings.display_cel_selector_frame = display_cel_selector.cel_frame
	settings.display_cel_selector_layer = display_cel_selector.cel_layer
	settings.sp2_cel_selector_frame = sp2_cel_selector.cel_frame
	settings.sp2_cel_selector_layer = sp2_cel_selector.cel_layer

	
	var project_name:String = ExtensionsApi.project.current_project.name
	var settings_file:String = project_name + "_settings.tres"

	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	ResourceSaver.save(settings, "user://FFTorama/" + settings_file)


func load_settings():
	var project_name:String = ExtensionsApi.project.current_project.name
	var settings_file:String = project_name + "_settings.tres"

	var loaded_settings
	if FileAccess.file_exists("user://FFTorama/" + settings_file):
		loaded_settings = load("user://FFTorama/" + settings_file)
	else:
		print_debug("Trying to load settings that do not exist: " + "user://FFTorama/" + settings_file)
		push_warning("Trying to load settings that do not exist: " + "user://FFTorama/" + settings_file)
		return

	if not is_instance_valid(loaded_settings):
		return

	weapon_frame = loaded_settings.weapon_frame
	weapon_layer = loaded_settings.weapon_layer
	weapon_type = loaded_settings.weapon_type
	effect_frame = loaded_settings.effect_frame
	effect_layer = loaded_settings.effect_layer
	effect_type = loaded_settings.effect_type
	item_frame = loaded_settings.item_frame
	item_layer = loaded_settings.item_layer
	other_frame = loaded_settings.other_frame
	other_layer = loaded_settings.other_layer
	other_type_index = loaded_settings.other_type_index
	use_separate_sp2 = loaded_settings.use_separate_sp2
	use_frame_id_for_sp2_offset = loaded_settings.use_frame_id_for_sp2_offset
	use_hardcoded_offsets = loaded_settings.use_hardcoded_offsets	
	select_frame = loaded_settings.select_frame
	use_current_cel = loaded_settings.use_current_cel	
	global_spritesheet_type = all_frame_data[loaded_settings.global_spritesheet_type]
	global_frame_id = loaded_settings.global_frame_id
	global_animation_type = all_animation_data[loaded_settings.global_animation_type]
	animation_is_playing = loaded_settings.animation_is_playing
	animation_speed = loaded_settings.animation_speed
	opcode_frame_offset = loaded_settings.opcode_frame_offset
	weapon_sheathe_check1_delay = loaded_settings.weapon_sheathe_check1_delay
	weapon_sheathe_check2_delay = loaded_settings.weapon_sheathe_check2_delay
	wait_for_input_delay = loaded_settings.wait_for_input_delay
	item_index = loaded_settings.item_index
	weapon_v_offset = loaded_settings.weapon_v_offset
	global_weapon_frame_offset_index = loaded_settings.global_weapon_frame_offset_index
	global_animation_id = loaded_settings.global_animation_id	
	background_color = loaded_settings.background_color
	auto_select_shape = loaded_settings.auto_select_shape

	# CelSelector vars
	display_cel_selector.cel_frame = loaded_settings.display_cel_selector_frame
	display_cel_selector.cel_layer = loaded_settings.display_cel_selector_layer
	sp2_cel_selector.cel_frame = loaded_settings.sp2_cel_selector_frame
	sp2_cel_selector.cel_layer = loaded_settings.sp2_cel_selector_layer


#func override_themes():
	#for child in get_all_children(self, true):
		#if child is SpinBox:
			#child.get_line_edit().add_theme_constant_override("minimum_character_width", theme_min_character_width)
#
#
#func get_all_children(node:Node, include_internal: bool = false) -> Array[Node]:
	#var nodes : Array[Node] = []
	#for N in node.get_children(include_internal):
		#if N.get_child_count(include_internal) > 0:
			#nodes.append(N)
			#nodes.append_array(get_all_children(N))
		#else:
			#nodes.append(N)
#
	#return nodes


func _on_frame_id_spin_box_value_changed(value):
	global_frame_id = value


func _on_frame_changed(value):
	if not isReady:
		return
	
	# if !is_instance_valid(api):
	# 	return
	# if display_cel_selector.cel_frame_selector.item_count == 0 or display_cel_selector.cel_layer_selector.item_count == 0:
	# 	return
	
	draw_assembled_frame(value, global_spritesheet_type, display_cel_selector.cel)
	select_subframes(value, global_spritesheet_type)


func _on_spritesheet_type_option_button_item_selected(index):
	global_spritesheet_type = all_frame_data[spritesheet_type_selector.get_item_text(index)]
	frame_id_spinbox.max_value = global_spritesheet_type.frames.size() - 1
	if(global_frame_id >= global_spritesheet_type.frames.size()):
		global_frame_id = global_spritesheet_type.frames.size() - 1
	if global_frame_id >= 0:
		_on_frame_changed(global_frame_id)
	
	
	if global_animation_type.sequences.size() == 0:
		return
	_on_animation_changed()

func _on_background_color_picker_button_color_changed(color):
	background_color = color


func _on_animation_id_spin_box_value_changed(value):	
	global_animation_id = value


func _on_animations_type_option_button_item_selected(index):
	global_animation_type = all_animation_data[animation_type_selector.get_item_text(index)]
	animation_id_spinbox.max_value = global_animation_type.sequences.size() - 1
	if(global_animation_id >= global_animation_type.sequences.size()):
		global_animation_id = global_animation_type.sequences.size() - 1
	set_animation_name_options(global_animation_type)
	
	if auto_select_shape:
		for i:int in spritesheet_type_selector.item_count:
			if spritesheet_type_selector.get_item_text(i) == animation_shape_lookup[global_animation_type.name_alias]:
				spritesheet_type_selector.select(i)
				spritesheet_type_selector.item_selected.emit(i)
				break
	
	_on_animation_changed()


func _on_animation_name_item_selected(index:int) -> void:
	if index != global_animation_id:
		animation_id_spinbox.value = index


func _on_animation_changed():
	if not isReady:
		return
	
	# reset frame offset
	opcode_frame_offset = 0
	
	# reset position
	(assembled_animation_primary.get_parent().get_parent() as Node2D).position = Vector2.ZERO
	(assembled_animation_viewport.sprite_item.get_parent() as Node2D).position = Vector2.ZERO
	assembled_animation_viewport.sprite_item.texture = create_blank_frame()
	
	# reset layer priority
	assembled_animation_viewport.sprite_primary.z_index = -2
	assembled_animation_viewport.sprite_weapon.z_index = -3
	assembled_animation_viewport.sprite_effect.z_index = -1
	assembled_animation_viewport.sprite_text.z_index = 0
	
	if (all_animation_data.has(global_animation_type.name_alias)):
		var fft_animation = get_animation_from_globals()
		
		var num_parts: int = fft_animation.sequence.seq_parts.size()
		animation_frame_slider.tick_count = num_parts
		animation_frame_slider.max_value = num_parts - 1
		
		start_animation(fft_animation, assembled_animation_primary, animation_is_playing, true)
		#play_animation(animation, global_spritesheet_type, true, assembled_animation_primary, display_cel_selector.cel, animation_is_playing, animation)


func get_animation_from_globals() -> FftAnimation:
	var fft_animation = FftAnimation.new()
	fft_animation.seq = global_animation_type
	fft_animation.shp = global_spritesheet_type
	fft_animation.sequence = global_animation_type.sequences[global_animation_id]
	fft_animation.weapon_frame_offset_index = global_weapon_frame_offset_index
	fft_animation.cel = display_cel_selector.get_cell()
	fft_animation.flipped_h = face_right_check.button_pressed
	fft_animation.submerged_depth = submerged_depth_options.selected
	
	global_fft_animation = fft_animation
	return fft_animation


func _on_is_playing_check_box_toggled(toggled_on):
	animation_is_playing = toggled_on
	animation_frame_slider.editable = !toggled_on
	
	if (!toggled_on):
		animation_frame_slider.value = 0
	
	if global_animation_type.sequences.size() == 0:
		return
	_on_animation_changed()


func _on_spin_box_speed_value_changed(value):
	animation_speed = value


func _on_animation_frame_h_slider_value_changed(value):
	if(animation_is_playing):
		return
	if global_animation_type.sequences.size() == 0:
		return
	#var animation:Sequence = global_animation_type.sequences[global_animation_id]
	
	process_seq_part(global_fft_animation, value, assembled_animation_primary)
	#draw_animation_frame(animation, value, global_spritesheet_type, assembled_animation_primary, display_cel_selector.cel, animation)
	
	var anim_part:SeqPart = global_fft_animation.sequence.seq_parts[value]
	if(select_frame and not anim_part.isOpcode):
		var new_frame_id:int = anim_part.parameters[0]
		frame_id_spinbox.value = new_frame_id # emits signal to update draw and selection


func _on_selection_check_box_toggled(toggled_on):
	select_frame = toggled_on


func update_assembled_frame():
	draw_assembled_frame(global_frame_id, global_spritesheet_type, display_cel_selector.cel)
	
	# update_assembled_frame gets called when the texture is updated, which includes just changing the selection
	# if (!animation_is_playing):
	# 	var animation = all_animation_data[global_animation_type][global_animation_id]
	# 	draw_animation_frame(animation, animation_frame_slider.value, global_spritesheet_type, assembled_animation_primary, display_cel)


func _on_weapon_option_button_item_selected(index):
	global_weapon_frame_offset_index = weapon_table[index][2] as int
	weapon_v_offset = weapon_table[index][3] as int


func _on_option_wep_frame_item_selected(index):
	weapon_frame = index


func _on_option_wep_layer_item_selected(index):
	weapon_layer = index


func _on_option_wep_type_item_selected(index):
	weapon_type = index + 1 # add 1 since only options are 1 or 2, but index goes from 0 or 1


func _on_option_eff_frame_item_selected(index):
	effect_frame = index


func _on_option_eff_layer_item_selected(index):
	effect_layer = index


func _on_option_eff_type_item_selected(index):
	effect_type = index + 1 # add 1 since only options are 1 or 2, but index goes from 0 or 1


func _on_option_item_frame_item_selected(index):
	item_frame = index


func _on_option_item_layer_item_selected(index):
	item_layer = index


func _on_option_other_frame_item_selected(index):
	other_frame = index


func _on_option_other_layer_item_selected(index):
	other_layer = index


func _on_option_other_type_item_selected(index):
	other_type_index = index


func _on_item_option_button_item_selected(index):
	item_index = index


func _on_wsc_1_delay_spinbox_value_changed(value):
	weapon_sheathe_check1_delay = value


func _on_wsc_2_delay_spinbox_value_changed(value):
	weapon_sheathe_check2_delay = value


func _on_wait_for_inputdelay_spinbox_2_value_changed(value):
	wait_for_input_delay = value


func _on_use_current_cel_check_box_toggled(toggled_on):
	use_current_cel = toggled_on
	
	display_cel_selector.cel_frame_selector.disabled = toggled_on
	display_cel_selector.cel_layer_selector.disabled = toggled_on
	
	if toggled_on && display_cel_selector.cel != ExtensionsApi.project.get_current_cel():
		_on_current_cel_switched()


func _on_current_cel_switched():
	if use_current_cel:
		display_cel_selector.cel_frame = ExtensionsApi.project.current_project.current_frame
		display_cel_selector.cel_layer = ExtensionsApi.project.current_project.current_layer
	
		update_assembled_frame()
		if global_animation_type.sequences.size() == 0:
			return
		_on_animation_changed()


func _on_cel_selection_changed(_index:int):
	update_assembled_frame()
	if global_animation_type.sequences.size() == 0:
		return
	_on_animation_changed()


func _on_sp_2_by_animation_index_toggled(toggled_on):
	use_frame_id_for_sp2_offset = not toggled_on


func _on_sp_2_hardcoded_lookup_toggled(toggled_on):
	use_hardcoded_offsets = toggled_on


func _on_separate_sp_2_cel_check_box_toggled(toggled_on):
	use_separate_sp2 = toggled_on
	
	sp2_cel_selector.cel_frame_selector.disabled = !toggled_on
	sp2_cel_selector.cel_layer_selector.disabled = !toggled_on


func _on_save_settings_pressed():
	save_settings()


func _on_auto_shape_check_toggled(toggled_on: bool) -> void:
	auto_select_shape = toggled_on
	spritesheet_type_selector.disabled = toggled_on
	_on_animations_type_option_button_item_selected(animation_type_selector.selected)


func _on_flatten_frame_pressed() -> void:	
	var flattened_image:Image = ExtensionsApi.project.current_project.new_empty_image()
	
	var frame:int = ExtensionsApi.project.current_project.current_frame
	var current_layer = ExtensionsApi.project.current_project.current_layer
	
	var has_flattened_layer = ExtensionsApi.project.current_project.layers.any(func(layer): return layer.name == "Flattened")
	
	if not has_flattened_layer:
		ExtensionsApi.project.add_new_layer(0, "Flatenned", Global.LayerTypes.PIXEL)
		current_layer = current_layer + 1
	
	var to_layer:int = 0
	for layer_index in ExtensionsApi.project.current_project.layers.size():
		if ExtensionsApi.project.current_project.layers[layer_index].name == "Flattened":
			to_layer = layer_index
			break
	
	#var to_cel:PixelCel = api.project.get_cel_at(api.project.current_project)
	
	for layer_index:int in ExtensionsApi.project.current_project.layers.size():
		var layer:BaseLayer = ExtensionsApi.project.current_project.layers[layer_index]
		if (
			(not layer is PixelLayer) 
			or (not layer.visible)
			or layer.name == "Flattened"
		):
			continue	
		
		var from_cel:PixelCel = ExtensionsApi.project.get_cel_at(ExtensionsApi.project.current_project, frame, layer_index)
		var layer_image:Image = from_cel.get_content()
		var layer_image_rect:Rect2i = Rect2i(Vector2i.ZERO, layer_image.get_size())
		flattened_image.blend_rect(layer_image, layer_image_rect, Vector2i.ZERO)
	
	ExtensionsApi.project.set_pixelcel_image(flattened_image, frame, to_layer)
	
	ExtensionsApi.project.get_cel_at(ExtensionsApi.project.current_project, frame, to_layer).update_texture()
	ExtensionsApi.project.current_project.change_cel(frame, current_layer)


func _on_new_palette_selected() -> void:
	if not Palettes.current_palette.data_changed.is_connected(_on_palette_changed):
		Palettes.current_palette.data_changed.connect(_on_palette_changed)
	_on_palette_changed()


func _on_palette_changed() -> void:
	var palette_image:Image = Image.create_empty(Palettes.current_palette.width, Palettes.current_palette.height, false, Image.FORMAT_RGBAF) # RGBA8 would perform a sRGB to linear conversion which would change the color
	palette_image.fill(Color.MAGENTA)
	for y in palette_image.get_height():
		for x in palette_image.get_width():
			#print_debug(str(Vector2i(x, y)) + " - " + str(x + (y * palette_image.get_width())) + " - " + str(Palettes.current_palette.colors[x + (y * palette_image.get_width())].color))
			# handle when there are less colors than Palettes.current_palette.width * Palettes.current_palette.height
			if (x + (y * palette_image.get_width())) >= Palettes.current_palette.colors.size():
				#push_warning("Trying to get color " + str(x + (y * palette_image.get_width())) + " out of " + str(Palettes.current_palette.colors.size()))
				break
			
			var shader_palette_color:Color = Palettes.current_palette.colors[x + (y * palette_image.get_width())].color
			palette_image.set_pixel(x, y, shader_palette_color)
	
	palette_texture = ImageTexture.create_from_image(palette_image)
	assembled_frame_node.material.set_shader_parameter("palette", palette_texture)
	export_texture.material.set_shader_parameter("palette", palette_texture)


func _on_submerged_options_item_selected(index: int) -> void:
	_on_animation_changed()
	_on_frame_changed(global_frame_id)



func _on_face_right_check_toggled(toggled_on: bool) -> void:
	# TODO fix translation and rotation of sprites
	
	assembled_animation_viewport.flip_h()
	assembled_frame_viewport.flip_h()
	_on_animation_changed()
	_on_frame_changed(global_frame_id)


class CelSelector:
	var cel_main
	
	var cel_frame_selector: OptionButton
	var cel_layer_selector: OptionButton
	var cel_frame: int = 0:
		get:
			return cel_frame
		set(value):
			cel_frame = value
			if is_instance_valid(cel_frame_selector):
				if cel_frame_selector.item_count > 0:
					cel_frame_selector.select(value)
	var cel_layer: int = 0:
		get:
			return cel_layer
		set(value):
			cel_layer = value
			if is_instance_valid(cel_layer_selector):
				if cel_layer_selector.item_count > 0:
					cel_layer_selector.select(value)
	
	var cel: PixelCel:
		get:
			return get_cell()
	
	var bmp:Bmp = Bmp.new()
	var cel_image_color_swapped:Image
	
	func _init(frame_selector: OptionButton, layer_selector: OptionButton, main, frame: int = 0, layer: int = 0):
		self.cel_main = main
	
		self.cel_frame_selector = frame_selector
		self.cel_layer_selector = layer_selector
		self.cel_frame = frame
		self.cel_layer = layer
	
		frame_selector.item_selected.connect(_on_cel_frame_selector_item_selected)
		layer_selector.item_selected.connect(_on_cel_layer_selector_item_selected)
	
		if not ExtensionsApi.project.current_project.timeline_updated.is_connected(update_options):
			ExtensionsApi.project.current_project.timeline_updated.connect(update_options)
		
		update_options()
	
	
	func _on_cel_frame_selector_item_selected(index:int):
		cel_frame = index
		cel_main._on_cel_selection_changed(index)
	
	
	func _on_cel_layer_selector_item_selected(index:int):
		cel_layer = index
		cel_main._on_cel_selection_changed(index)
	
	
	func get_cell():
		if (cel_frame_selector.item_count > 0 and cel_layer_selector.item_count > 0
				and ExtensionsApi.project.current_project.frames.size() > cel_frame):
			if ExtensionsApi.project.current_project.frames[cel_frame].cels.size() <= cel_layer:
				return null
			var cel_attempt: PixelCel = ExtensionsApi.project.current_project.frames[cel_frame].cels[cel_layer] as PixelCel
			if cel_attempt != null:
				return cel_attempt
			else:
				push_warning("Cel at frame %s and layer %s is not a valid PixelCel" % [cel_frame, cel_layer])
				return null
		else:
			return null
	
	
	func update_color_swapped_image(palette_swap:int = 0):
		var base_image:Image = cel.get_content()
		
		var new_palette: Array[Color] = []
		new_palette.resize(Palettes.current_palette.colors.size())
		new_palette.fill(Color.BLACK)
		for palette_color in Palettes.current_palette.colors.values():
			new_palette[palette_color.index] = palette_color.color
		
		bmp.set_color_indexed_data(base_image, new_palette)
		#var original_indices := bmp.color_indices.duplicate()
		#var original_palette := bmp.color_palette.duplicate()
	
		var index_offset = palette_swap * 16
		if bmp.color_palette.size() >= 16 + index_offset:
			for i in bmp.color_indices.size():
				bmp.color_indices[i] = (bmp.color_indices[i] % 16) + index_offset
		else:
			print_debug("Palette does not have enough colors. Needs " + str(16 + index_offset) + ", but only has " + str(bmp.color_palette.size()))
			#bmp.color_palette = original_palette.duplicate()
			#bmp.color_indices = original_indices.duplicate()
		bmp.set_colors_by_indices()
		
		cel_image_color_swapped = bmp.get_RGBA8_image()
	
	
	func update_options():
		var project = ExtensionsApi.project.current_project
	
		cel_frame_selector.clear()
		cel_layer_selector.clear()
	
		for frame_index in project.frames.size():
			cel_frame_selector.add_item(str(frame_index + 1))
	
		for layer_index in project.layers.size():
			if !(project.layers[layer_index] is PixelLayer):
				continue
			cel_layer_selector.add_item(project.layers[layer_index].name)
	
		if cel_frame >= cel_frame_selector.item_count:
			cel_frame = 0
		if cel_layer >= cel_layer_selector.item_count:
			cel_layer = 0
	
		if cel_frame_selector.item_count == 0 or cel_layer_selector.item_count == 0:
			return
	
		cel_frame_selector.select(cel_frame)
		cel_layer_selector.select(cel_layer)
