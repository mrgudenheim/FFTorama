extends Node

# NOTE: use get_node_or_null("/root/ExtensionsApi") to access the extension api.

var api: Node

@export_file("*.txt") var layer_priority_table_filepath: String
var layer_priority_table: Array = []

@export var seq_shape_data_node: Node

# settings vars
@export var settings_container: Control
@export var weapon_frame_selector: OptionButton
@export var weapon_layer_selector: OptionButton
@export var effect_frame_selector: OptionButton
@export var effect_layer_selector: OptionButton
@export var weapon_frame: int = 0
@export var weapon_layer: int = 0
@export var weapon_type: int = 1
@export var effect_frame: int = 0
@export var effect_layer: int = 0
@export var effect_type: int = 1

# frame vars
@onready var assembled_frame_viewport = $MarginAssembledFrame/AssembledFrame/AssembledFrameViewportContainer
var assembled_frame_node: Node2D
@export var assembled_frame_container: Control
@export var spritesheet_type_selector: OptionButton
@export var frame_id_spinbox: SpinBox

var all_frame_data: Dictionary = {}
var all_frame_offsets_data: Dictionary = {}
var spritesheet_shape: String = "type1"

@export var frame_id: int = 0:
	get:
			return frame_id
	set(value):
		if (value != frame_id):
			frame_id = value
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
var animation_type: String = "type1"
@export var animation_is_playing: bool = true
@export var animation_speed: float = 60 # frames per sec
@export var select_frame: bool = true
var opcode_frame_offset: int = 0
var weapon_sheathe_check1_delay: int = 0
var weapon_sheathe_check2_delay: int = 10
var wait_for_input_delay: int = 10
var weapon_index: int = 0: # index to lookup frame offset for wep and eff animations
	get:
		return weapon_index
	set(value):
		if (value != weapon_index):
			weapon_index = value
			play_animation(animation_id)
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
		if (spritesheet_shape == "kanzen" || spritesheet_shape == "arute"):
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
	#api.menu.remove_menu_item(api.menu.FILE, menu_item_add_animation)
	#api.menu.remove_menu_item(api.menu.FILE, menu_item_add_shape)
	api.panel.remove_node_from_tab(assembled_frame_container)
	api.panel.remove_node_from_tab(assembled_animation_container)
	api.panel.remove_node_from_tab(settings_container)
	
	api.signals.signal_current_cel_texture_changed(update_assembled_frame, true)
	api.signals.signal_cel_switched(update_assembled_frame, true)
	api.project.current_project.timeline_updated.disconnect(set_frame_layer_selector_options)
	#assembled_frame_container.queue_free()

func _ready():
	seq_shape_data_node.load_data()
	all_frame_data = seq_shape_data_node.all_shape_data
	all_frame_offsets_data = seq_shape_data_node.all_offsets_data
	all_animation_data = seq_shape_data_node.all_animation_data

	api = get_node_or_null("/root/ExtensionsApi")

	load_layer_priority_table(layer_priority_table_filepath)
	
	assembled_frame_node = assembled_frame_viewport.sprite_primary
	assembled_animation_node = assembled_animation_viewport.sprite_primary
	
	#menu_item_add_shape = api.menu.add_menu_item(api.menu.FILE, "Add Spritesheet Shape", self)
	#menu_item_add_animation = api.menu.add_menu_item(api.menu.FILE, "Add Animation Sequence", self)
	# api.signals.connect_current_cel_texture_changed(self, "update_assembled_frame")
	api.signals.signal_current_cel_texture_changed(update_assembled_frame)
	api.signals.signal_cel_switched(update_assembled_frame)
	api.project.current_project.timeline_updated.connect(set_frame_layer_selector_options)
	
	set_background_color(background_color)
	
	# initialize assembled frame
	assembled_frame_container.visible = true
	spritesheet_type_selector.clear()
	for type in all_frame_data.keys():
		spritesheet_type_selector.add_item(type)
	
	spritesheet_type_selector.select(7); # initialize sprite type
	#_on_spritesheet_type_option_button_item_selected(7) # initialize sprite type
	frame_id_spinbox.value = 9; # emits frame changed signal that call select_subrames and
	remove_child(assembled_frame_container)
	api.panel.add_node_as_tab(assembled_frame_container)
	assembled_frame_container.name = "Assembled Frame"
	
	# initialize assembled animation
	assembled_animation_container.visible = true
	animation_type_selector.clear()
	for type in all_animation_data.keys():
		animation_type_selector.add_item(type)
	
	animation_type_selector.select(8) # initialize sprite type
	_on_animations_type_option_button_item_selected(8) # initialize sprite type
	animation_id_spinbox.value = 6; # emits frame changed signal that call select_subrames and
	remove_child(assembled_animation_container)
	api.panel.add_node_as_tab(assembled_animation_container)
	assembled_animation_container.name = "Assembled Animation"
	
	# initialize settings panel
	settings_container.visible = true
	remove_child(settings_container)
	api.panel.add_node_as_tab(settings_container)
	settings_container.name = "FFT Settings"
	
	set_frame_layer_selector_options()
	weapon_frame_selector.select(0)
	effect_frame_selector.select(0)
	weapon_layer_selector.select(0)
	effect_layer_selector.select(0)

func menu_item_clicked():
	print("clicked")
	#_on_spritesheet_type_option_button_item_selected(0) # initialize sprite type
	#frame_id_spinbox.value = 9; # emits frame changed signal that call select_subrames and draw_assembled_frame

func select_subframes(frame_index: int, shape: String = spritesheet_shape):
	if (!all_frame_data.has(shape)):
		return
	
	api.selection.clear_selection()
	#print(all_frames[frame_index][0])
	for subframe_index in all_frame_data[spritesheet_shape][frame_index][0] as int:
		var subframe_data = all_frame_data[spritesheet_shape][frame_index][subframe_index + 2] # skip past num_subframe and rotation_degrees
		var x_shift: int = 		subframe_data[0]
		var y_shift: int = 		subframe_data[1]
		var x_top_left: int = 	subframe_data[2]
		var y_top_left: int = 	subframe_data[3]
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

func get_assembled_frame(frame_index: int, shape: String = spritesheet_shape, cel = api.project.get_current_cel()) -> Image:
	var assembled_image: Image = create_blank_frame()
	
	var num_subframes: int = all_frame_data[shape][frame_index][0] as int
	for subframe_index in range(num_subframes-1, -1, -1):
		assembled_image = add_subframe(subframe_index, all_frame_data[shape][frame_index], assembled_image, shape, cel)
		
	return assembled_image

func add_subframe(subframe_index: int, frame: Array, assembled_image: Image, shape: String = spritesheet_shape, cel = api.project.get_current_cel()) -> Image:
	var index_offset: int = 2 # skip past num_subframes and rotation_degrees
	var x_shift: int = 		frame[subframe_index + index_offset][0]
	var y_shift: int = 		frame[subframe_index + index_offset][1]
	var x_top_left: int = 	frame[subframe_index + index_offset][2]
	var y_top_left: int = 	frame[subframe_index + index_offset][3]
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

func draw_assembled_frame(frame_index: int, sheet_type: String = spritesheet_shape, cel = api.project.get_current_cel()):
	if (!all_frame_data.has(sheet_type)):
		return
	
	var assembled_image: Image = get_assembled_frame(frame_index, sheet_type, cel)
	assembled_frame_node.texture = ImageTexture.create_from_image(assembled_image)
	var rotation: float = all_frame_data[sheet_type][frame_id][1]
	(assembled_frame_node.get_parent() as Node2D).rotation_degrees = rotation

func play_animation(animation_id: int, animation_type:String = animation_type, sheet_type:String = spritesheet_shape, loop:bool = true, draw_target:Node2D = assembled_animation_node, cel = api.project.get_current_cel(), is_playing:bool = animation_is_playing, primary_anim = true) -> void:
	if (!all_animation_data.has(animation_type)):
		return
	
	var animation: Array = all_animation_data[animation_type][animation_id]
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
		return
	elif (num_parts == 1):
		draw_animation_frame(animation, 0, sheet_type, draw_target, cel, primary_anim)
		return
	
	if (is_playing):
		loop_animation(num_parts, animation, sheet_type, weapon_index, loop, draw_target, cel, primary_anim)
	else:
		draw_animation_frame(animation, 0, sheet_type, draw_target, cel, primary_anim)

func loop_animation(num_parts:int, animation: Array, sheet_type:String = spritesheet_shape, weapon_index:int = weapon_index, loop:bool = true, draw_target:Node2D = assembled_animation_node, cel = api.project.get_current_cel(), primary_anim = true):
	for animation_part_id:int in range(num_parts):
		# break loop animation when stopped or on selected animation changed to prevent 2 loops playing at once
		if (loop and (!animation_is_playing || 
		animation != all_animation_data[self.animation_type][self.animation_id] ||
		# animation_id != self.animation_id || 
		# animation_type != self.animation_type || 
		weapon_index != self.weapon_index)):
			break
		
		# var animation = all_animation_data[animation_type][animation_id]

		await draw_animation_frame(animation, animation_part_id, sheet_type, draw_target, cel, primary_anim)

		if !seq_shape_data_node.opcodeParameters.has(animation[animation_part_id + 3][0]):
			var delay_frames: int = animation[animation_part_id + 3][1] as int # add 3 to skip past label, id, and num_parts
			var delay_sec: float = delay_frames / animation_speed
			await get_tree().create_timer(delay_sec).timeout
		
		if (animation_part_id == num_parts-1 and loop):
			loop_animation(num_parts, animation, sheet_type, weapon_index, loop, draw_target, cel)
		elif (animation_part_id == num_parts-1 and !loop): # clear image when animation is over
			draw_target.texture = ImageTexture.create_from_image(create_blank_frame())

func draw_animation_frame(animation: Array, animation_part_id: int, sheet_type:String = spritesheet_shape, draw_target:Node2D = assembled_animation_node, cel = api.project.get_current_cel(), primary_anim = true) -> void:
	# var animation = all_animation_data[animation_type][animation_id]
	# print(animation)
	var anim_part = animation[animation_part_id + 3] # add 3 to skip past label, id, and num_parts
	var anim_part0: String = str(anim_part[0])
	
	var frame_id_label = anim_part0

	# print_debug(anim_part0 + " " + str(animation))
	# print_stack()

	var position_offset: Vector2 = Vector2.ZERO

	# Handle opcodes
	if seq_shape_data_node.opcodeParameters.has(anim_part0):
		#print(anim_part_start)
		if anim_part0 == "QueueSpriteAnim":
			#print("Performing " + anim_part_start) 
			if anim_part[1] as int == 1: # play weapon animation
				print_debug("playing weapon animation " + str(anim_part[2]))
				var weapon_cel = api.project.get_cel_at(api.project.current_project, weapon_frame, weapon_layer)
				play_animation(anim_part[2] as int, "wep" + str(weapon_type), "wep" + str(weapon_type), false, assembled_animation_viewport.sprite_weapon, weapon_cel, true, false)
			elif anim_part[1] as int == 2: # play effect animation
				print_debug("playing effect animation " + str(anim_part[2]))
				var eff_cel = api.project.get_cel_at(api.project.current_project, effect_frame, effect_layer)
				play_animation(anim_part[2] as int, "eff" + str(effect_type), "eff" + str(effect_type), false, assembled_animation_viewport.sprite_effect, eff_cel, true, false)
			else:
				print("Error: QueueSpriteAnim with first parameter = " + str(anim_part) + anim_part[1] + "\n" + str(animation))
				print_stack()

		elif anim_part0.begins_with("Move"):
			if anim_part0 == "MoveUnitFB":
				position_offset = Vector2(-anim_part[1], 0) # assume facing left
			elif anim_part0 == "MoveUnitDU":
				position_offset = Vector2(0, anim_part[1])
			elif anim_part0 == "MoveUnitRL":
				position_offset = Vector2(anim_part[1], 0)
			elif anim_part0 == "MoveUnitRLDUFB":
				position_offset = Vector2(anim_part[1] - anim_part[3], anim_part[2]) # assume facing left
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
				print("can't inerpret" + anim_part0)
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
			pass
		elif anim_part0 == "MFItemPos":
			pass
		elif anim_part0 == "LoadMFItem":
			pass
		elif anim_part0 == "Wait":
			pass
		elif anim_part0 == "IncrementLoop":
			pass
		elif anim_part0 == "WaitForInput":
			pass
		elif anim_part0.begins_with("WeaponSheatheCheck"):
			var delay_frames = weapon_sheathe_check1_delay
			if anim_part0 == "WeaponSheatheCheck2":
				delay_frames = weapon_sheathe_check2_delay
			
			var loop_length: int = anim_part[1] as int
			var temp_anim_length: int = 0
			var temp_anim: Array = []
			var previous_anim_part_id = animation_part_id - 1
			
			# print(str(animation) + "\n" + str(previous_anim_part_id))
			while temp_anim_length < abs(loop_length):
				var previous_anim_part: Array = animation[previous_anim_part_id + 3] # add 3 to skip past label, id, and num_parts
				temp_anim.insert(0, previous_anim_part)
				temp_anim_length += previous_anim_part.size()
				if seq_shape_data_node.opcodeParameters.has(previous_anim_part[0]):
					temp_anim_length += 1

				previous_anim_part_id -= 1
			
			# add label, id, and num_parts
			var num_parts: int = temp_anim.size()
			temp_anim.insert(0, num_parts) # num parts
			temp_anim.insert(0, loop_length) # id
			temp_anim.insert(0, anim_part0) # label

			print(str(temp_anim))
			var timer: SceneTreeTimer = get_tree().create_timer(delay_frames / animation_speed)
			while timer.time_left > 0:
				# print(str(timer.time_left) + " " + str(temp_anim))
				await loop_animation(num_parts, temp_anim, sheet_type, weapon_index, false, draw_target, cel, false)

		elif anim_part0 == "WaitForDistort":
			pass
		elif anim_part0 == "QueueDistortAnim":
			# https://ffhacktics.com/wiki/0008b234_-_0008b288
			pass
	else: # handle LoadFrameWait
		var frame_id:int = anim_part0 as int
		var frame_id_offset:int = get_animation_frame_offset(weapon_index, sheet_type)
		frame_id = frame_id + frame_id_offset + opcode_frame_offset
		frame_id_label = str(frame_id)
		
		var assembled_image: Image = get_assembled_frame(frame_id, sheet_type, cel)
		draw_target.texture = ImageTexture.create_from_image(assembled_image)
		var rotation: float = all_frame_data[sheet_type][frame_id][1]
		(draw_target.get_parent() as Node2D).rotation_degrees = rotation

	# only update ui for primary animation, not animations called through opcodes
	if primary_anim:
		animation_frame_slider.value = animation_part_id
		frame_id_text.text = str(frame_id_label)

		if(select_frame and !animation_is_playing):
			frame_id_spinbox.value = frame_id # emits signal to update draw and selection

func get_animation_frame_offset(weapon_index:int, spritesheet_type:String) -> int:
	if (spritesheet_type.begins_with("wep") || spritesheet_type.begins_with("eff")):
		return all_frame_offsets_data[spritesheet_type][weapon_index] as int
	else:
		return 0


func set_frame_layer_selector_options():
	var project = api.project.current_project
	
	for frame_index in project.frames.size():
		weapon_frame_selector.add_item(str(frame_index + 1))
		effect_frame_selector.add_item(str(frame_index + 1))
	
	for layer_index in project.layers.size():
		if !(project.layers[layer_index] is PixelLayer):
			continue
		weapon_layer_selector.add_item(project.layers[layer_index].name)
		effect_layer_selector.add_item(project.layers[layer_index].name)
	
func set_background_color(color):
	if !is_instance_valid(api):
		return
	
	assembled_frame_viewport.sprite_background.texture = ImageTexture.create_from_image(create_blank_frame(color))
	assembled_animation_viewport.sprite_background.texture = ImageTexture.create_from_image(create_blank_frame(color))


func load_file(filepath:String) -> String:
	var file = FileAccess.open(filepath, FileAccess.READ)
	var content: String = file.get_as_text()
	return content

func load_layer_priority_table(filepath):
	var file_contents = load_file(filepath)
	var lines: Array = 	file_contents.split("\r\n")
	for line_index in range(1,lines.size()): # skip first row of headers
		layer_priority_table.append(lines[line_index].split(","))

func _on_frame_id_spin_box_value_changed(value):
	frame_id = value

func _on_frame_changed(value):
	if !is_instance_valid(api):
		return
	draw_assembled_frame(value)
	select_subframes(value)

func _on_spritesheet_type_option_button_item_selected(index):
	spritesheet_shape = spritesheet_type_selector.get_item_text(index)
	frame_id_spinbox.max_value = all_frame_data[spritesheet_shape].size() - 1
	if(frame_id >= all_frame_data[spritesheet_shape].size()):
		frame_id = all_frame_data[spritesheet_shape].size() - 1
	_on_frame_changed(frame_id)

func _on_background_color_picker_button_color_changed(color):
	background_color = color

func _on_animation_id_spin_box_value_changed(value):	
	animation_id = value

func _on_animations_type_option_button_item_selected(index):
	animation_type = animation_type_selector.get_item_text(index)
	animation_id_spinbox.max_value = all_animation_data[animation_type].size() - 1
	if(animation_id >= all_animation_data[animation_type].size()):
		animation_id = all_animation_data[animation_type].size() - 1
	_on_animation_changed(animation_id)

func _on_animation_changed(animation_id):
	if !is_instance_valid(api):
		return
	
	# reset frame offset
	opcode_frame_offset = 0

	# reset position
	(assembled_animation_node.get_parent().get_parent() as Node2D).position = Vector2.ZERO

	# reset layer priority
	assembled_animation_viewport.sprite_primary.z_index = -2
	assembled_animation_viewport.sprite_weapon.z_index = -3
	assembled_animation_viewport.sprite_effect.z_index = -1
	assembled_animation_viewport.sprite_text.z_index = 0

	var animation: Array = all_animation_data[animation_type][animation_id]

	if (all_animation_data.has(animation_type)):
		var num_parts:int = animation.size() - 3
		animation_frame_slider.tick_count = num_parts
		animation_frame_slider.max_value = num_parts - 1
	play_animation(animation_id)

func _on_is_playing_check_box_toggled(toggled_on):
	animation_is_playing = toggled_on
	animation_frame_slider.editable = !toggled_on
	
	if (!toggled_on):
		animation_frame_slider.value = 0
	play_animation(animation_id)

func _on_spin_box_speed_value_changed(value):
	animation_speed = value

func _on_animation_frame_h_slider_value_changed(value):
	if(animation_is_playing):
		return
	
	var animation = all_animation_data[animation_type][animation_id]

	draw_animation_frame(animation, value)
	
	var anim_part = animation[value + 3]
	if(select_frame and !seq_shape_data_node.opcodeParameters.has(anim_part[0])):
		var frame_id:int = anim_part[0] as int
		frame_id_spinbox.value = frame_id # emits signal to update draw and selection
	
	

func _on_selection_check_box_toggled(toggled_on):
	select_frame = toggled_on

func update_assembled_frame():
	draw_assembled_frame(frame_id)
	
	#if (!animation_is_playing):
		#draw_animation_frame(animation_id, animation_frame_slider.value)


func _on_weapon_option_button_item_selected(index):
	weapon_index = index


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
