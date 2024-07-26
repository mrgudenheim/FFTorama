extends Node

var all_animation_data: Dictionary
var all_shape_data: Dictionary
var all_offsets_data: Dictionary

var animation_types: Array = [
	"arute",
	"cyoko",
	"eff1",
	"eff2",
	"kanzen",
	"mon",
	"other",
	"ruka",
	"type1",
	"type2",
	"type3",
	"type4",
	"wep1",
	"wep2"]
	
var shape_types: Array = [
	"arute",
	"cyoko",
	"eff1",
	"eff2",
	"kanzen",
	"mon",
	"other",
	"type1",
	"type2",
	"wep1",
	"wep2"]

var offset_types: Array = [
	"eff1",
	"eff2",
	"wep1",
	"wep2"]

func load_data():
	for type in animation_types:
		var path: String = "res://src/Extensions/FFTorama/SeqData/seq_data_" + type + ".txt"
		all_animation_data[type] = parse_animation_data(load_text_file(path))
		
	for type in shape_types:
		var path: String = "res://src/Extensions/FFTorama/FrameData/frame_data_" + type + ".txt"
		print(type)
		all_shape_data[type] = parse_frame_data(load_text_file(path))
		
	for type in offset_types:
		var path: String = "res://src/Extensions/FFTorama/FrameData/frame_offset_data_" + type + ".txt"
		all_offsets_data[type] = parse_offset_data(load_text_file(path))

func load_custom_shape_data(label:String, path:String):
	all_shape_data[label] = parse_frame_data(load_text_file(path))

func load_custom_animation_data(label:String, path:String):
	all_animation_data[label] = parse_animation_data(load_text_file(path))

func load_text_file(path) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content

func parse_frame_data(all_frame_data: String) -> Array:
	var frames_split = all_frame_data.split("\n")
	frames_split = frames_split.slice(1, frames_split.size())
	var subframe_offset:int = 3
	var subframe_length:int = 8

	var frames = []

	for frame in frames_split:
		frame = frame.split(",")
		
		if(frame[0] == ""):
			continue
		
		var num_subframe:int = frame[1] as int
		var frame_data = [num_subframe]

		for i in num_subframe:
			var subframe = [
				frame[subframe_offset + (subframe_length*i)] as int,		# x_shift
				frame[subframe_offset + 1 + (subframe_length*i)] as int,	# y_shift
				frame[subframe_offset + 2 + (subframe_length*i)] as int,	# top_left_x_pixels
				frame[subframe_offset + 3 + (subframe_length*i)] as int,	# top_left_y_pixels
				frame[subframe_offset + 4 + (subframe_length*i)] as int,	# sizeX
				frame[subframe_offset + 5 + (subframe_length*i)] as int,	# sizeY
				frame[subframe_offset + 6 + (subframe_length*i)] == "True" as bool,	# flip_x
				frame[subframe_offset + 7 + (subframe_length*i)] == "True" as bool	# flip_y
			]

			frame_data.append(subframe)

		frames.append(frame_data)
		# print(frame_data)
	
	return frames

func parse_animation_data(all_animation_data: String) -> Array:
	var animations_split: Array = all_animation_data.split("\n")
	animations_split = animations_split.slice(1, animations_split.size())
	var initial_offset:int = 2
	var load_frame_and_weight_length:int = 2

	var animations = []

	for animation in animations_split:
		animation = animation.split(",")

		var num_frames:int = (animation.size() - initial_offset) / load_frame_and_weight_length

		var animation_data = [
			animation[0], # label
			animation[1], # animation_id
			num_frames
		]

		for i in num_frames:
			var frame_and_delay = [
				animation[initial_offset + (i * load_frame_and_weight_length)] as int,		# frame_id
				animation[initial_offset + (i * load_frame_and_weight_length) + 1] as int		# delay in frames
			]
			animation_data.append(frame_and_delay)

		animations.append(animation_data)
		# print(frame_data)
	
	return animations

func parse_offset_data(all_offset_data_text: String) -> Array:
	var offsets_split: Array = all_offset_data_text.split("\n")
	offsets_split = offsets_split[1].split(",")
	return offsets_split
