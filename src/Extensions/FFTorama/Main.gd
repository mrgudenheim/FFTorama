extends Node

# NOTE: use get_node_or_null("/root/ExtensionsApi") to access the extension api.

var api: Node

@export_file("*.txt") var layer_priority_table_filepath: String
var layer_priority_table: Array = []
@export_file("*.txt") var weapon_table_filepath: String
var weapon_table: Array = []
@export_file("*.txt") var item_list_filepath: String
var item_list: Array = []


@export var seq_shape_data_node: Node

# settings vars
@export var settings_container: Control
@export var weapon_selector: OptionButton
@export var item_selector: OptionButton

@export var cel_frame_selector: OptionButton
@export var cel_layer_selector: OptionButton
@export var weapon_frame_selector: OptionButton
@export var weapon_layer_selector: OptionButton
@export var effect_frame_selector: OptionButton
@export var effect_layer_selector: OptionButton
@export var item_frame_selector: OptionButton
@export var item_layer_selector: OptionButton
@export var other_frame_selector: OptionButton
@export var other_layer_selector: OptionButton
@export var other_type_selector: OptionButton
# @export var cel_frame: int = 0
# @export var cel_layer: int = 0
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

var display_cel_selector: CelSelector
var display_cel:
	get:
		if is_instance_valid(api):
			return api.project.get_cel_at(api.project.current_project, display_cel_selector.cel_frame, display_cel_selector.cel_layer)
		else:
			return null

@export var select_frame: bool = true
@export var use_selected_cel: bool = true

# frame vars
@onready var assembled_frame_viewport = $MarginAssembledFrame/AssembledFrame/AssembledFrameViewportContainer
var assembled_frame_node: Node2D
@export var assembled_frame_container: Control
@export var spritesheet_type_selector: OptionButton
@export var frame_id_spinbox: SpinBox

var all_frame_data: Dictionary = {}
var all_frame_offsets_data: Dictionary = {}
var global_spritesheet_type: String = "type1"

@export var global_frame_id: int = 0:
	get:
			return global_frame_id
	set(value):
		if (value != global_frame_id):
			global_frame_id = value
			_on_frame_changed(value)

# animation vars
@onready var assembled_animation_viewport = $MarginAssembledAnimation/AssembledAnimation/SubViewportContainer
var assembled_animation_node: Node2D
@export var assembled_animation_container: Control
@export var animation_type_selector: OptionButton
@export var animation_id_spinbox: SpinBox
@export var animation_frame_slider: Slider
@export var animation_speed_spinbox: SpinBox
@export var frame_id_text: LineEdit

var all_animation_data: Dictionary = {}
var global_animation_type: String = "type1"
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
			if is_instance_valid(api): # check if data is ready
				play_animation(all_animation_data[global_animation_type][animation_id], global_spritesheet_type, true, assembled_animation_node, display_cel, animation_is_playing ) # start the animation with new weapon
@export var animation_id: int = 0:
	get:
		return animation_id
	set(value):
		if (value != animation_id):
			animation_id = value
			_on_animation_changed(value)

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
		if (global_spritesheet_type == "kanzen" || global_spritesheet_type == "arute"):
			return Vector2i(120, 180)
		else:
			return Vector2i(120, 120)

# things to remove when extension uninstalled or disabled
var menu_item_add_shape: int
var menu_item_add_animation: int

# signals
signal frame_changed(frame_id: int)
signal animation_changed(animation_id: int)
signal animation_frame_changed(animation_frame_id: int)

# Runs as soon as extension is enabled. This script can act as a setup for the extension.
func _enter_tree() -> void:
	pass

func _exit_tree() -> void:  # Extension is being uninstalled or disabled
	# remember to remove things that you added using this extension
	api.panel.remove_node_from_tab(assembled_frame_container)
	api.panel.remove_node_from_tab(assembled_animation_container)
	api.panel.remove_node_from_tab(settings_container)
	
	api.signals.signal_current_cel_texture_changed(update_assembled_frame, true)
	api.signals.signal_cel_switched(_on_cel_switched, true)
	api.project.current_project.timeline_updated.disconnect(set_frame_layer_selectors_options)
	api.project.current_project.timeline_updated.disconnect(update_cel_selectors_options)
	#assembled_frame_container.queue_free()

func _ready():
	seq_shape_data_node.load_data()
	all_frame_data = seq_shape_data_node.all_shape_data
	all_frame_offsets_data = seq_shape_data_node.all_offsets_data
	all_animation_data = seq_shape_data_node.all_animation_data

	api = get_node_or_null("/root/ExtensionsApi")

	display_cel_selector = CelSelector.new(cel_frame_selector, cel_layer_selector)
	display_cel_selector.cel_frame_selector.item_selected.connect(_on_cel_selection_changed)
	display_cel_selector.cel_layer_selector.item_selected.connect(_on_cel_selection_changed)

	layer_priority_table = load_csv(layer_priority_table_filepath)
	weapon_table = load_csv(weapon_table_filepath)
	item_list = load_csv(item_list_filepath)
	
	assembled_frame_node = assembled_frame_viewport.sprite_primary
	assembled_animation_node = assembled_animation_viewport.sprite_primary
	
	api.signals.signal_current_cel_texture_changed(update_assembled_frame)
	api.signals.signal_cel_switched(_on_cel_switched)
	api.project.current_project.timeline_updated.connect(set_frame_layer_selectors_options)
	api.project.current_project.timeline_updated.connect(update_cel_selectors_options)
	
	set_background_color(background_color)
	set_sheet_and_animation_selector_options()
	update_cel_selectors_options()

	# initialize assembled frame
	assembled_frame_container.visible = true
	spritesheet_type_selector.select(7); # initialize sprite type
	#_on_spritesheet_type_option_button_item_selected(7) # initialize sprite type
	frame_id_spinbox.value = 9; # emits frame changed signal that call select_subrames and?
	remove_child(assembled_frame_container)
	api.panel.add_node_as_tab(assembled_frame_container)
	assembled_frame_container.name = "Assembled Frame"
	
	# initialize assembled animation
	assembled_animation_container.visible = true
	animation_type_selector.select(8) # initialize animation type to type1
	_on_animations_type_option_button_item_selected(8) # initialize sprite type
	animation_id_spinbox.value = 0; # emits signal?
	remove_child(assembled_animation_container)
	api.panel.add_node_as_tab(assembled_animation_container)
	assembled_animation_container.name = "Assembled Animation"
	
	# initialize settings panel
	settings_container.visible = true
	remove_child(settings_container)
	api.panel.add_node_as_tab(settings_container)
	settings_container.name = "FFT Settings"

	set_weapon_selector_options()
	weapon_selector.select(0)
	set_item_selector_options()
	item_selector.select(0)

	set_frame_layer_selectors_options()


func select_subframes(frame_index: int, spritesheet_type: String, v_offset:int = 0):
	if (!all_frame_data.has(spritesheet_type)):
		return
		
	if v_offset == 0:
		v_offset = get_v_offset(spritesheet_type)
	
	api.selection.clear_selection()
	#print(all_frames[frame_index][0])
	for subframe_index in all_frame_data[spritesheet_type][frame_index][0] as int:
		var subframe_data = all_frame_data[spritesheet_type][frame_index][subframe_index + 2] # skip past num_subframe and rotation_degrees
		# var x_shift: int = 		subframe_data[0] # not used here
		# var y_shift: int = 		subframe_data[1] # not used here
		var x_top_left: int = 	subframe_data[2]
		var y_top_left: int = 	subframe_data[3] + v_offset
		var size_x: int = 		subframe_data[4]
		var size_y: int = 		subframe_data[5]

		var subframeRect: Rect2i = Rect2i(x_top_left, y_top_left, size_x, size_y)
		#print(subframeRect)
		api.selection.select_rect(subframeRect, 0)

func create_blank_frame(color: Color = Color.TRANSPARENT) -> Image:
	var blank_image: Image = Image.create(
		frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8
	)
	blank_image.fill(color)
	
	return blank_image

func get_assembled_frame(frame_index: int, spritesheet_type: String, cel, v_offset:int = 0) -> Image:
	var assembled_image: Image = create_blank_frame()

	if v_offset == 0:
		v_offset = get_v_offset(spritesheet_type)
	
	# print_debug(str(shape) + " " + str(frame_index) + " " + str(v_offset))
	if frame_index >= all_frame_data[spritesheet_type].size(): # high frame offsets (such as shuriken) can only be used with certain animations
		return create_blank_frame()
	var num_subframes: int = all_frame_data[spritesheet_type][frame_index][0] as int
	for subframe_index in range(num_subframes-1, -1, -1): # reverse order to layer them correctly 
		assembled_image = add_subframe(subframe_index, all_frame_data[spritesheet_type][frame_index], assembled_image, cel, v_offset)
		
	return assembled_image

func get_v_offset(spritesheet_type: String) -> int:
	var v_offset:int = 0
	
	if spritesheet_type.begins_with("wep") and v_offset == 0:
		v_offset = weapon_v_offset
	if spritesheet_type == "other" and v_offset == 0:
		v_offset = other_type_index * 24 * 2 # 2 rows each of chicken and frog frames

	return v_offset

func add_subframe(subframe_index: int, frame: Array, assembled_image: Image, cel, v_offset:int = 0) -> Image:
	var index_offset: int = 2 # skip past num_subframes and rotation_degrees
	var x_shift: int = 		frame[subframe_index + index_offset][0]
	var y_shift: int = 		frame[subframe_index + index_offset][1]
	var x_top_left: int = 	frame[subframe_index + index_offset][2]
	var y_top_left: int = 	frame[subframe_index + index_offset][3] + v_offset
	var size_x: int = 		frame[subframe_index + index_offset][4]
	var size_y: int = 		frame[subframe_index + index_offset][5]
	var flip_x : bool = 	frame[subframe_index + index_offset][6]
	var flip_y : bool = 	frame[subframe_index + index_offset][7]
	
	var destination_pos: Vector2i = Vector2i(x_shift + (frame_size.x / 2), y_shift + frame_size.y - 40) # adjust by 40 to prevent frame from spilling over bottom
	var source_rect: Rect2i = Rect2i(x_top_left, y_top_left, size_x, size_y)
	# var destination_rect: Rect2i = Rect2i(destination_pos.x, destination_pos.y, size_x, size_y)
	
	# var cel = api.project.get_current_cel()
	var spritesheet: Image = cel.get_content()
	var source_image: Image = spritesheet
	
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
	return assembled_image

func draw_assembled_frame(frame_index: int, sheet_type: String, cel):
	if (!all_frame_data.has(sheet_type)):
		return
	
	var assembled_image: Image = get_assembled_frame(frame_index, sheet_type, cel)
	assembled_frame_node.texture = ImageTexture.create_from_image(assembled_image)
	var rotation: float = all_frame_data[sheet_type][frame_index][1]
	(assembled_frame_node.get_parent() as Node2D).rotation_degrees = rotation

func play_animation(animation: Array, sheet_type:String, loop:bool, draw_target:Node2D, cel, is_playing:bool, primary_anim:bool = true, force_loop:bool = false) -> void:
	var num_parts:int = animation[2]

	var only_opcodes: bool = true
	for animation_part_id:int in range(num_parts):
		if !seq_shape_data_node.opcodeParameters.has(animation[animation_part_id + 3][0]):
			only_opcodes = false
			break

		
	# don't loop when no parts, only 1 part, or all parts are opcodes
	if (num_parts == 0 || only_opcodes):
		# draw a blank image
		var assembled_image: Image = create_blank_frame()
		assembled_animation_node.texture = ImageTexture.create_from_image(assembled_image)
		await get_tree().create_timer(.001).timeout # prevent infinite loop from Wait opcodes looping only opcodes
		return
	elif (num_parts == 1 and !force_loop):
		draw_animation_frame(animation, 0, sheet_type, draw_target, cel, primary_anim)
		return
	
	if (is_playing):
		await loop_animation(num_parts, animation, sheet_type, global_weapon_frame_offset_index, loop, draw_target, cel, primary_anim)
	else:
		draw_animation_frame(animation, 0, sheet_type, draw_target, cel, primary_anim)

func loop_animation(num_parts:int, animation: Array, sheet_type:String, weapon_frame_offset_index:int, loop:bool, draw_target:Node2D, cel, primary_anim = true):
	for animation_part_id:int in range(num_parts):
		# break loop animation when stopped or on selected animation changed to prevent 2 loops playing at once
		if (loop and (!animation_is_playing || 
		animation != all_animation_data[self.global_animation_type][self.animation_id] ||
		weapon_frame_offset_index != self.global_weapon_frame_offset_index ||
		(primary_anim && (global_spritesheet_type != sheet_type)) ||
		primary_anim && (cel != display_cel))):
			break

		await draw_animation_frame(animation, animation_part_id, sheet_type, draw_target, cel, primary_anim)

		if !seq_shape_data_node.opcodeParameters.has(animation[animation_part_id + 3][0]):
			var delay_frames: int = animation[animation_part_id + 3][1] as int # add 3 to skip past label, id, and num_parts
			var delay_sec: float = delay_frames / animation_speed
			await get_tree().create_timer(delay_sec).timeout
		
		if (animation_part_id == num_parts-1 and loop):
			loop_animation(num_parts, animation, sheet_type, weapon_frame_offset_index, loop, draw_target, cel, primary_anim)
		elif (animation_part_id == num_parts-1 and !loop): # clear image when animation is over
			draw_target.texture = ImageTexture.create_from_image(create_blank_frame())

func draw_animation_frame(animation: Array, animation_part_id: int, sheet_type:String, draw_target:Node2D, cel, primary_anim = true) -> void:
	# print_debug(str(animation) + " " + str(animation_part_id + 3))
	var anim_part = animation[animation_part_id + 3] # add 3 to skip past label, id, and num_parts
	var anim_part0: String = str(anim_part[0])
	
	var frame_id_label = anim_part0

	# print_debug(anim_part0 + " " + str(animation))
	# print_stack()

	var part_is_opcode:bool = seq_shape_data_node.opcodeParameters.has(anim_part0)

	# handle LoadFrameWait
	if !part_is_opcode:
		var new_frame_id:int = anim_part0 as int
		var frame_id_offset:int = get_animation_frame_offset(global_weapon_frame_offset_index, sheet_type)
		new_frame_id = new_frame_id + frame_id_offset + opcode_frame_offset
		frame_id_label = str(new_frame_id)

		if new_frame_id >= all_frame_data[sheet_type].size(): # high frame offsets (such as shuriken) can only be used with certain animations
			var assembled_image: Image = create_blank_frame()
			draw_target.texture = ImageTexture.create_from_image(assembled_image)
		else:
			var assembled_image: Image = get_assembled_frame(new_frame_id, sheet_type, cel)
			draw_target.texture = ImageTexture.create_from_image(assembled_image)
			var rotation: float = all_frame_data[sheet_type][new_frame_id][1]
			(draw_target.get_parent() as Node2D).rotation_degrees = rotation		

	# only update ui for primary animation, not animations called through opcodes
	if primary_anim:
		animation_frame_slider.value = animation_part_id
		frame_id_text.text = str(frame_id_label)

		if(select_frame and !animation_is_playing):
			frame_id_spinbox.value = global_frame_id # emits signal to update draw and selection

	var position_offset: Vector2 = Vector2.ZERO

	# Handle opcodes
	if part_is_opcode:
		#print(anim_part_start)
		if anim_part0 == "QueueSpriteAnim":
			#print("Performing " + anim_part_start) 
			if anim_part[1] as int == 1: # play weapon animation
				print_debug("playing weapon animation " + str(anim_part[2]))
				var weapon_cel = api.project.get_cel_at(api.project.current_project, weapon_frame, weapon_layer)
				var new_animation: Array = all_animation_data["wep" + str(weapon_type)][anim_part[2] as int]
				play_animation(new_animation, "wep" + str(weapon_type), false, assembled_animation_viewport.sprite_weapon, weapon_cel, true, false)
			elif anim_part[1] as int == 2: # play effect animation
				print_debug("playing effect animation " + str(anim_part[2]))
				var eff_cel = api.project.get_cel_at(api.project.current_project, effect_frame, effect_layer)
				var new_animation: Array = all_animation_data["eff" + str(effect_type)][anim_part[2] as int]
				play_animation(new_animation, "eff" + str(effect_type), false, assembled_animation_viewport.sprite_effect, eff_cel, true, false)
			else:
				print_debug("Error: QueueSpriteAnim with first parameter = " + str(anim_part) + anim_part[1] + "\n" + str(animation))
				print_stack()

		elif anim_part0.begins_with("Move"):
			if anim_part0 == "MoveUnitFB":
				position_offset = Vector2(-(anim_part[1] as int), 0) # assume facing left
			elif anim_part0 == "MoveUnitDU":
				position_offset = Vector2(0, anim_part[1] as int)
			elif anim_part0 == "MoveUnitRL":
				position_offset = Vector2(anim_part[1] as int, 0)
			elif anim_part0 == "MoveUnitRLDUFB":
				position_offset = Vector2((anim_part[1] as int) - (anim_part[3] as int), anim_part[2] as int) # assume facing left
			elif anim_part0 == "MoveUp1":
				position_offset = Vector2(0, -1)
			elif anim_part0 == "MoveUp2":
				position_offset = Vector2(0, -2)
			elif anim_part0 == "MoveDown1":
				position_offset = Vector2(0, 1)
			elif anim_part0 == "MoveDown2":
				position_offset = Vector2(0, 2)
			elif anim_part0 == "MoveBackward1":
				position_offset = Vector2(1, 0) # assume facing left
			elif anim_part0 == "MoveBackward2":
				position_offset = Vector2(2, 0) # assume facing left
			elif anim_part0 == "MoveForward1":
				position_offset = Vector2(-1, 0) # assume facing left
			elif anim_part0 == "MoveForward2":
				position_offset = Vector2(-2, 0) # assume facing left
			else:
				print_debug("can't inerpret " + anim_part0)
				print_stack()
			(draw_target.get_parent().get_parent() as Node2D).position += position_offset

		elif anim_part0 == "SetLayerPriority":
			# print(layer_priority_table)
			var layer_priority: Array = layer_priority_table[anim_part[1] as int]
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

		elif anim_part0 == "SetFrameOffset":
			opcode_frame_offset = anim_part[1] as int # use global var since SetFrameOffset is only used in animations that do not call other animations

		elif anim_part0 == "FlipHorizontal":
			assembled_animation_viewport.sprite_primary.flip_h = !assembled_animation_viewport.sprite_primary.flip_h
		
		elif anim_part0 == "UnloadMFItem":
			var target_sprite = assembled_animation_viewport.sprite_item
			target_sprite.texture = create_blank_frame()

			# reset any rotation or movement
			(target_sprite.get_parent() as Node2D).rotation_degrees = 0
			(target_sprite.get_parent() as Node2D).position = Vector2(0,0)

		elif anim_part0 == "MFItemPosFBDU":
			var target_sprite_pivot := assembled_animation_viewport.sprite_item.get_parent() as Node2D
			target_sprite_pivot.position = Vector2(-(anim_part[1] as int), (anim_part[2] as int) + 20) # assume facing left, add 20 because it is y position from bottom of unit

		elif anim_part0 == "LoadMFItem":
			var item_frame_id:int = item_index # assumes loading item
			var item_sheet_type:String = "item"
			var item_cel = api.project.get_cel_at(api.project.current_project, item_frame, item_layer)
			
			if item_index >= 180:
				item_sheet_type = "other"
				item_cel = api.project.get_cel_at(api.project.current_project, other_frame, other_layer)
				
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
			var rotation: float = all_frame_data[item_sheet_type][item_frame_id][1]
			(target_sprite.get_parent() as Node2D).rotation_degrees = rotation

		elif anim_part0 == "Wait":
			var delay_frames = wait_for_input_delay			
			var loop_length: int = anim_part[1] as int
			var temp_anim: Array = []

			var num_loops: int = anim_part[2] as int
			
			for iteration in range(num_loops):
				var anim_iteration: Array = get_sub_animation(loop_length, animation_part_id, animation)
				if iteration > 0:
					anim_iteration = anim_iteration.slice(3) # only include label, id, num parts from first iteration
				temp_anim.append_array(anim_iteration)
			
			temp_anim[2] = temp_anim[2] * num_loops # total num_parts = num_parts from 1 loop times the number of loops
			
			# print_debug(str(temp_anim))
			var timer: SceneTreeTimer = get_tree().create_timer(delay_frames / animation_speed)
			while timer.time_left > 0:
				# print(str(timer.time_left) + " " + str(temp_anim))
				await play_animation(temp_anim, sheet_type, false, draw_target, cel, true, false, true)
			
		elif anim_part0 == "IncrementLoop":
			pass # handled by animations looping by default

		elif anim_part0 == "WaitForInput":
			var delay_frames = wait_for_input_delay			
			var loop_length: int = anim_part[1] as int
			var temp_anim: Array = get_sub_animation(loop_length, animation_part_id, animation)

			# print_debug(str(temp_anim))
			var timer: SceneTreeTimer = get_tree().create_timer(delay_frames / animation_speed)
			while timer.time_left > 0:
				# print(str(timer.time_left) + " " + str(temp_anim))
				await play_animation(temp_anim, sheet_type, false, draw_target, cel, true, false, true)
			
		elif anim_part0.begins_with("WeaponSheatheCheck"):
			var delay_frames = weapon_sheathe_check1_delay
			if anim_part0 == "WeaponSheatheCheck2":
				delay_frames = weapon_sheathe_check2_delay
			
			var loop_length: int = anim_part[1] as int
			var temp_anim: Array = get_sub_animation(loop_length, animation_part_id, animation)

			# print_debug(str(temp_anim))
			var timer: SceneTreeTimer = get_tree().create_timer(delay_frames / animation_speed)
			while timer.time_left > 0:
				# print(str(timer.time_left) + " " + str(temp_anim))
				await play_animation(temp_anim, sheet_type, false, draw_target, cel, true, false, true)

		elif anim_part0 == "WaitForDistort":
			pass
		elif anim_part0 == "QueueDistortAnim":
			# https://ffhacktics.com/wiki/0008b234_-_0008b288
			pass


func get_animation_frame_offset(weapon_frame_offset_index:int, spritesheet_type:String) -> int:
	if (spritesheet_type.begins_with("wep") || spritesheet_type.begins_with("eff")):
		return all_frame_offsets_data[spritesheet_type][weapon_frame_offset_index] as int
	else:
		return 0

func get_sub_animation(length:int, sub_animation_end_part_id:int, animation:Array) -> Array:
	var sub_anim_length: int = 0
	var sub_anim: Array = []
	var previous_anim_part_id = sub_animation_end_part_id - 1
	
	# print(str(animation) + "\n" + str(previous_anim_part_id))
	while sub_anim_length < abs(length):
		var previous_anim_part: Array = animation[previous_anim_part_id + 3] # add 3 to skip past label, id, and num_parts
		sub_anim.insert(0, previous_anim_part)
		sub_anim_length += previous_anim_part.size()
		if seq_shape_data_node.opcodeParameters.has(previous_anim_part[0]):
			sub_anim_length += 1

		previous_anim_part_id -= 1
	
	# add label, id, and num_parts
	var num_parts: int = sub_anim.size()
	sub_anim.insert(0, num_parts) # num parts
	sub_anim.insert(0, length) # id
	sub_anim.insert(0, animation[sub_animation_end_part_id + 3][0]) # label
	
	return sub_anim

func update_cel_selectors_options():
	update_cel_selector_options(display_cel_selector)
	
	pass

func update_cel_selector_options(selector:CelSelector):
	var project = api.project.current_project

	selector.cel_frame_selector.clear()
	selector.cel_layer_selector.clear()

	for frame_index in project.frames.size():
		selector.cel_frame_selector.add_item(str(frame_index + 1))

	for layer_index in project.layers.size():
		if !(project.layers[layer_index] is PixelLayer):
			continue
		selector.cel_layer_selector.add_item(project.layers[layer_index].name)

	if selector.cel_frame >= selector.cel_frame_selector.item_count:
		selector.cel_frame = 0
	if selector.cel_layer >= selector.cel_layer_selector.item_count:
		selector.cel_layer = 0

	selector.cel_frame_selector.select(selector.cel_frame)
	selector.cel_layer_selector.select(selector.cel_layer)

func set_frame_layer_selectors_options():
	var project = api.project.current_project

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
	if !is_instance_valid(api):
		return
	
	assembled_frame_viewport.sprite_background.texture = ImageTexture.create_from_image(create_blank_frame(color))
	assembled_animation_viewport.sprite_background.texture = ImageTexture.create_from_image(create_blank_frame(color))


func set_sheet_and_animation_selector_options():
	spritesheet_type_selector.clear()
	for type in all_frame_data.keys():
		spritesheet_type_selector.add_item(type)

	for selector_index in spritesheet_type_selector.item_count - 1:
		if spritesheet_type_selector.get_item_text(selector_index) == global_spritesheet_type:
			spritesheet_type_selector.select(selector_index)

	animation_type_selector.clear()
	for type in all_animation_data.keys():
		animation_type_selector.add_item(type)

	for selector_index in animation_type_selector.item_count - 1:
		if animation_type_selector.get_item_text(selector_index) == global_animation_type:
			animation_type_selector.select(selector_index)


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


func _on_frame_id_spin_box_value_changed(value):
	global_frame_id = value

func _on_frame_changed(value):
	if !is_instance_valid(api):
		return
	draw_assembled_frame(value, global_spritesheet_type, display_cel)
	select_subframes(value, global_spritesheet_type)

func _on_spritesheet_type_option_button_item_selected(index):
	global_spritesheet_type = spritesheet_type_selector.get_item_text(index)
	frame_id_spinbox.max_value = all_frame_data[global_spritesheet_type].size() - 1
	if(global_frame_id >= all_frame_data[global_spritesheet_type].size()):
		global_frame_id = all_frame_data[global_spritesheet_type].size() - 1
	_on_frame_changed(global_frame_id)

	play_animation(all_animation_data[global_animation_type][animation_id], global_spritesheet_type, true, assembled_animation_node, display_cel, animation_is_playing)

func _on_background_color_picker_button_color_changed(color):
	background_color = color

func _on_animation_id_spin_box_value_changed(value):	
	animation_id = value

func _on_animations_type_option_button_item_selected(index):
	global_animation_type = animation_type_selector.get_item_text(index)
	animation_id_spinbox.max_value = all_animation_data[global_animation_type].size() - 1
	if(animation_id >= all_animation_data[global_animation_type].size()):
		animation_id = all_animation_data[global_animation_type].size() - 1
	_on_animation_changed(animation_id)

func _on_animation_changed(new_animation_id):
	if !is_instance_valid(api):
		return
	
	# reset frame offset
	opcode_frame_offset = 0

	# reset position
	(assembled_animation_node.get_parent().get_parent() as Node2D).position = Vector2.ZERO
	(assembled_animation_viewport.sprite_item.get_parent() as Node2D).position = Vector2.ZERO
	assembled_animation_viewport.sprite_item.texture = create_blank_frame()

	# reset layer priority
	assembled_animation_viewport.sprite_primary.z_index = -2
	assembled_animation_viewport.sprite_weapon.z_index = -3
	assembled_animation_viewport.sprite_effect.z_index = -1
	assembled_animation_viewport.sprite_text.z_index = 0

	if (all_animation_data.has(global_animation_type)):
		var animation: Array = all_animation_data[global_animation_type][new_animation_id]
		var num_parts:int = animation.size() - 3
		animation_frame_slider.tick_count = num_parts
		animation_frame_slider.max_value = num_parts - 1
		play_animation(animation, global_spritesheet_type, true, assembled_animation_node, display_cel, animation_is_playing)

func _on_is_playing_check_box_toggled(toggled_on):
	animation_is_playing = toggled_on
	animation_frame_slider.editable = !toggled_on
	
	if (!toggled_on):
		animation_frame_slider.value = 0

	play_animation(all_animation_data[global_animation_type][animation_id], global_spritesheet_type, true, assembled_animation_node, display_cel, animation_is_playing)

func _on_spin_box_speed_value_changed(value):
	animation_speed = value

func _on_animation_frame_h_slider_value_changed(value):
	if(animation_is_playing):
		return
	
	var animation = all_animation_data[global_animation_type][animation_id]

	draw_animation_frame(animation, value, global_spritesheet_type, assembled_animation_node, display_cel)
	
	var anim_part = animation[value + 3]
	if(select_frame and !seq_shape_data_node.opcodeParameters.has(anim_part[0])):
		var new_frame_id:int = anim_part[0] as int
		frame_id_spinbox.value = new_frame_id # emits signal to update draw and selection
	

func _on_selection_check_box_toggled(toggled_on):
	select_frame = toggled_on

func update_assembled_frame():
	draw_assembled_frame(global_frame_id, global_spritesheet_type, display_cel)	
	
	# update_assembled_frame gets called when the texture is updated, which includes just changing the selection
	# if (!animation_is_playing):
	# 	var animation = all_animation_data[global_animation_type][animation_id]
	# 	draw_animation_frame(animation, animation_frame_slider.value, global_spritesheet_type, assembled_animation_node, display_cel)


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


# func _on_option_cel_frame_item_selected(index):
# 	cel_frame = index


# func _on_option_cel_layer_item_selected(index):
# 	cel_layer = index


func _on_use_current_cel_check_box_toggled(toggled_on):
	use_selected_cel = toggled_on

	display_cel_selector.cel_frame_selector.disabled = toggled_on
	display_cel_selector.cel_layer_selector.disabled = toggled_on

	if toggled_on && display_cel != api.project.get_current_cel():
		_on_cel_switched()

func _on_cel_switched():
	if use_selected_cel:
		display_cel_selector.cel_frame = api.project.current_project.current_frame
		display_cel_selector.cel_layer = api.project.current_project.current_layer
	
	update_assembled_frame()
	play_animation(all_animation_data[global_animation_type][animation_id], global_spritesheet_type, true, assembled_animation_node, display_cel, animation_is_playing)

func _on_cel_selection_changed(_index:int):
	_on_cel_switched()

class CelSelector:	
	var cel_frame_selector: OptionButton
	var cel_layer_selector: OptionButton
	var cel_frame: int = 0:
		get:
			return cel_frame
		set(value):
			cel_frame = value
			if is_instance_valid(cel_frame_selector):
				cel_frame_selector.select(value)
	var cel_layer: int = 0:
		get:
			return cel_layer
		set(value):
			cel_layer = value
			if is_instance_valid(cel_layer_selector):
				cel_layer_selector.select(value)
	
	func _init(frame_selector: OptionButton, layer_selector: OptionButton, frame: int = 0, layer: int = 0):
		self.cel_frame_selector = frame_selector
		self.cel_layer_selector = layer_selector
		self.cel_frame = frame
		self.cel_layer = layer

		frame_selector.item_selected.connect(_on_cel_frame_selector_item_selected)
		layer_selector.item_selected.connect(_on_cel_layer_selector_item_selected)


	func _on_cel_frame_selector_item_selected(index:int):
		cel_frame = index


	func _on_cel_layer_selector_item_selected(index:int):
		cel_layer = index
