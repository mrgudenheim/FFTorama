extends Node

signal custom_data_loaded()

var all_animation_data: Dictionary
var all_shape_data: Dictionary
var all_shp_data: Dictionary
var all_offsets_data: Dictionary
	
var animation_types: Dictionary = {
	"arute":"Altima/arute",
	"cyoko":"Chocobo/cyoko",
	"eff1":"eff1",
	"eff2":"eff2 (Unused)",
	"kanzen":"Altima2/kanzen",
	"mon":"Monster/mon",
	"other":"other",
	"ruka":"Lucavi/ruka",
	"type1":"type1",
	"type2":"type2 (Unused)",
	"type3":"type3",
	"type4":"type4 (Unused)",
	"wep1":"wep1",
	"wep2":"wep2"}

var animation_names: Dictionary = {}

var shape_types: Dictionary = {
	"arute":"Altima/arute",
	"cyoko":"Chocobo/cyoko",
	"eff1":"eff1",
	"eff2":"eff2 (Unused)",
	"kanzen":"Altima2/kanzen",
	"mon":"Monster/Lucavi/mon",
	"other":"other",
	"type1":"type1",
	"type2":"type2",
	"wep1":"wep1",
	"wep2":"wep2",
	"item":"item"}

var offset_types: Dictionary = {
	"eff1":"eff1",
	"eff2":"eff2 (Unused)",
	"wep1":"wep1",
	"wep2":"wep2"}


var opcodeParameters: Dictionary

func load_data():
	var pathOpcodeData: String = "res://src/Extensions/FFTorama/SeqData/opcodeParameters.txt"
	opcodeParameters = parse_opcode_data(load_text_file(pathOpcodeData))
	
	var file = FileAccess.open("res://src/Extensions/FFTorama/SeqData/animation_names.txt", FileAccess.READ)
	
	while not file.eof_reached(): # iterate through all lines until the end of file is reached
		var line: String = file.get_line()
		if line.length() == 0:
			continue
		var line_parts := line.split(",")
		var animation_type := line_parts[0]
		var animation_id := line_parts[1]
		var animation_name := line_parts[2]

		animation_names[animation_type + " " + str(animation_id)] = animation_name
	file.close()

	for type in animation_types.keys():
		var path: String = "res://src/Extensions/FFTorama/SeqData/animation_data_" + type + ".txt"
		all_animation_data[animation_types[type]] = parse_animation_data(load_text_file(path))
		
	#for type in shape_types.keys():
		#var path: String = "res://src/Extensions/FFTorama/FrameData/frame_data_" + type + ".txt"
		#all_shape_data[shape_types[type]] = parse_frame_data(load_text_file(path))
		
	for type in shape_types.keys():
		var path: String = "res://src/Extensions/FFTorama/FrameData/" + type + "_shp.cfg"
		var shp:Shp = Shp.new()
		shp.set_data_from_cfg(path)
		if shape_types.has(shp.file_name):
			shp.name_alias = shape_types[type]
		all_shp_data[shp.name_alias] = shp
	
	# handle data for item
	var path: String = "res://src/Extensions/FFTorama/FrameData/frame_data_item.txt"
	var shp:Shp = Shp.new()
	shp.set_frames_from_csv(path)
	if shape_types.has(shp.file_name):
		shp.name_alias = shape_types[shp.file_name]
	all_shp_data[shp.name_alias] = shp
	
	#for type in offset_types.keys():
		#var path: String = "res://src/Extensions/FFTorama/FrameData/frame_offset_data_" + type + ".txt"
		#all_offsets_data[offset_types[type]] = parse_offset_data(load_text_file(path))

	load_custom_data()

func load_custom_data():
	var directory:String = "user://FFTorama"
	var dir := DirAccess.open(directory)
	if dir:
		var files:PackedStringArray = dir.get_files()
		for file:String in files:
			#print_debug(file)
			var file_label:String = file.split(".")[0] # remove extension
			file_label.trim_suffix("_shp")
			file_label.trim_prefix("frame_data_")
			file_label.trim_prefix("animation_data_")
			
			var path:String = directory + "/" + file
			
			if file.ends_with("_shp.cfg"):
				var shp:Shp = Shp.new()
				shp.set_data_from_cfg(path)
				all_shp_data[shp.name_alias] = shp
			elif file.begins_with("frame_data_"):
				if files.has(file_label + "_shp.cfg"):
					continue # skip csv if shp is already defined through cfg
				var shp:Shp = Shp.new()
				shp.set_frames_from_csv(path)
				all_shp_data[shp.name_alias] = shp
				#load_custom_frame_data(file_label, path)
			elif file.begins_with("animation_data_"):
				load_custom_animation_data(file_label, path)
	else:
		print("An error occurred when trying to access the path: " + directory)

	custom_data_loaded.emit()
	


func load_custom_frame_data(label:String, path:String):
	all_shape_data[label] = parse_frame_data(load_text_file(path))

func load_custom_animation_data(label:String, path:String):
	all_animation_data[label] = parse_animation_data(load_text_file(path))

func load_text_file(path) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content

func parse_frame_data(all_frame_data: String) -> Array:
	var frames_split = all_frame_data.split("\n")
	frames_split = frames_split.slice(1, frames_split.size()) # skip first row of headers
	var subframe_offset:int = 4 # skip past label, frame_id, num_frames, and rotation
	var subframe_length:int = 8

	var frames = []

	for frame in frames_split:
		frame = frame.split(",")
		
		if(frame[0] == ""):
			continue
		
		var num_subframe:int = frame[2] as int
		var rotation_degrees:float = frame[3] as float
		var frame_data = [num_subframe, rotation_degrees]

		for i in num_subframe:
			var subframe = [
				frame[subframe_offset + (subframe_length*i)] as int,		# x_shift
				frame[subframe_offset + 1 + (subframe_length*i)] as int,	# y_shift
				frame[subframe_offset + 2 + (subframe_length*i)] as int,	# top_left_x_pixels
				frame[subframe_offset + 3 + (subframe_length*i)] as int,	# top_left_y_pixels
				frame[subframe_offset + 4 + (subframe_length*i)] as int,	# sizeX
				frame[subframe_offset + 5 + (subframe_length*i)] as int,	# sizeY
				frame[subframe_offset + 6 + (subframe_length*i)].to_lower() == "true" as bool,	# flip_x
				frame[subframe_offset + 7 + (subframe_length*i)].to_lower() == "true" as bool	# flip_y
			]

			frame_data.append(subframe)

		frames.append(frame_data)
		# print(frame_data)
	
	return frames

func parse_animation_data(all_animation_data_text: String) -> Array:
	var animations_split: Array = all_animation_data_text.split("\n")
	animations_split = animations_split.slice(1, animations_split.size())
	var initial_offset:int = 2
	var load_frame_and_weight_length:int = 2

	var animations: Array = []

	for animation in animations_split:
		animation = animation.split(",")
		var animation_data: Array = []
		var num_parts:int = 0
		
		var anim_part_id: int = initial_offset # skip first two (label and animation_id)
		# print(animation.size())
		while anim_part_id < animation.size():
			num_parts += 1
			var anim_part0 = animation[anim_part_id]
			if (opcodeParameters.has(anim_part0)):
				var opcode_parts: Array = [anim_part0]
				var argument_pos: int = 0
				while argument_pos < opcodeParameters[anim_part0]:
					opcode_parts.append(animation[anim_part_id + argument_pos + 1])
					argument_pos += 1

				animation_data.append(opcode_parts)
				anim_part_id += opcodeParameters[anim_part0] + 1
			else:
				var frame_id:int = animation[anim_part_id] as int # frame_id
				var frame_delay:int = animation[anim_part_id + 1] as int # delay in frames
				
				var frame_and_delay = [frame_id, frame_delay]
				animation_data.append(frame_and_delay)
				anim_part_id += load_frame_and_weight_length

		animation_data.insert(0, animation[0]) # animation type
		animation_data.insert(1, animation[1]) # animation_id
		animation_data.insert(2, num_parts)

		animations.append(animation_data)
		# print(frame_data)
	
	return animations

func parse_offset_data(all_offset_data_text: String) -> Array:
	var offsets_split: Array = all_offset_data_text.split("\n")
	offsets_split = offsets_split[1].split(",")
	return offsets_split

func parse_opcode_data(all_opcodeData: String) -> Dictionary:
	var opcode_data_parsed: Dictionary = {}
	
	var opcodes_split: Array = all_opcodeData.split("\n")
	opcodes_split = opcodes_split.slice(1) # skip first row of headers

	for opcode_parts in opcodes_split:
		var opcode_parts_split: Array = opcode_parts.split(",")
		if opcode_parts_split.size() > 1:
			opcode_data_parsed[str(opcode_parts_split[0])] = opcode_parts_split[1] as int

	return opcode_data_parsed
