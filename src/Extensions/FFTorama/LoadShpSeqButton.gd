extends Button

@export var data_loader:Node

@export	var file_dialog: FileDialog
var bytes_per_frame:int = 4;
var pixels_per_tile:int = 8;

var subframe_sizes: PackedVector2Array =[
	Vector2(  8,  8 ),
	Vector2( 16,  8 ),
	Vector2( 16, 16 ),
	Vector2( 16, 24 ),
	Vector2( 24,  8 ),
	Vector2( 24, 16 ),
	Vector2( 24, 24 ),
	Vector2( 32,  8 ),
	Vector2( 32, 16 ),
	Vector2( 32, 24 ),
	Vector2( 32, 32 ),
	Vector2( 32, 40 ),
	Vector2( 48, 16 ),
	Vector2( 40, 32 ),
	Vector2( 48, 48 ),
	Vector2( 56, 56 )];

# https://ffhacktics.com/wiki/Sprite_Y_Rotation_Table
var rotations_degrees: PackedFloat32Array = [
	0,
	15.996,
	23.027,
	26.455,
	26.719,
	26.982,
	29.971,
	42.979,
	45.000,
	55.020,
	60.029,
	70.049,
	90.000,
	119.971,
	120.059,
	124.980,
	127.969,
	129.990,
	135.000,
	140.010,
	145.020,
	150.029,
	153.018,
	154.951,
	160.049,
	164.971];

@export_file("*.txt") var opcode_list_filepath:String

# https://ffhacktics.com/wiki/SEQ_%26_Animation_info_page
var opcode_parameters: Dictionary
var opcode_names: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready():
	load_opcode_data(opcode_list_filepath);


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func parse_file(filepath:String) -> void:
	var file_extension:String = filepath.get_extension()
	if file_extension.to_lower() == "shp":
		parse_shp(filepath)
	elif file_extension.to_lower() == "seq":
		pass
		parse_seq(filepath);


func parse_shp(filepath:String) -> void:
	var file_name:String = filepath.get_file()
	file_name = file_name.trim_suffix(".shp")
	file_name = file_name.trim_suffix(".SHP")
	file_name = file_name.trim_suffix(".Shp")
	file_name = file_name.to_lower()
	# print_debug(file_name)

	# var file = FileAccess.open(filepath, FileAccess.READ)
	var bytes:PackedByteArray = FileAccess.get_file_as_bytes(filepath)
	var hex_strings:PackedStringArray = []
	for byte in bytes:
		var hex_string:String = String.num_int64(byte, 16)
		if hex_string.length() == 1:
			hex_string = "0" + hex_string
		hex_strings.append(hex_string)
	# print_debug("size " + str(hex_strings.size()))
	# print_debug(hex_strings)


	var output:String = "label,frame_id,subframes,rotation_degrees,x_shift,y_shift,top_left_x_pixels,top_left_y_pixels,sizeX,sizeY,flip_x,flip_y"
	var frame_data_string:String = ""

	var section1_length:int = 8
	var section2_length:int = "0x400".hex_to_int()
	var swim_start_index:int = (hex_strings[3] + hex_strings[2] + hex_strings[1] + hex_strings[0]).hex_to_int() + section2_length # only type1, type2, cyoko unit have swim frames
	var first_attack_frame:int = (hex_strings[5] + hex_strings[4]).hex_to_int() # starting at this point frames load from second (lower) half of spritesheet
	
	# these shapes have a slightly different format
	if (file_name.begins_with("wep") || file_name.begins_with("eff")):
		section1_length = "0x44".hex_to_int();
		section2_length = "0x800".hex_to_int();
		first_attack_frame = 9999; # these types do not have a second (lower) half 

	var frame_data_start_index = section2_length + section1_length
	var first_block_length = (hex_strings[frame_data_start_index + 1] + hex_strings[frame_data_start_index]).hex_to_int()

	var frame_count:int = 0
	var frame_id:int = 0
	
	# add 2 since first 2 were the firstBlockLength
	var hex_index:int = frame_data_start_index + 2
	while hex_index < hex_strings.size():
		if hex_index == (frame_data_start_index + first_block_length + 2): # add 2 to account for first 2 hex defining the block length
			hex_index = swim_start_index + 2 # add 2 to account for first 2 hex defining the block length
			frame_count = 0
		
		var num_subframes:int = 1 + (hex_strings[hex_index].hex_to_int() % 8) # right 3 (least significant) bits
		var rotation_index:int = hex_strings[hex_index].hex_to_int() >> 3 # left 5 (most significant) bits
		var sprite_rotation:float = rotations_degrees[rotation_index]

		var y_offset:int = 0
		if frame_count >= first_attack_frame:
			y_offset = 256 # subframe should be loaded from second half of sprite sheet

		frame_data_string = file_name + "," + str(frame_id) + "," + str(num_subframes) + "," + str(sprite_rotation)
		
		var subframe:int = 0
		while subframe < num_subframes:
			var x_shift:int = (hex_strings[hex_index + 2 + (subframe * bytes_per_frame)]).hex_to_int()
			var y_shift:int = (hex_strings[hex_index + 3 + (subframe * bytes_per_frame)]).hex_to_int()

			# correct for signed 8 bit int
			if x_shift > 128:
				x_shift -= 256
			if y_shift > 128:
				y_shift -= 256

			var frame_hex:String = hex_strings[hex_index + 5  + (subframe * bytes_per_frame)] + hex_strings[hex_index + 4 + (subframe * bytes_per_frame)] # accomadate little endian
			var frame_dec:int = frame_hex.hex_to_int()

			# https://ffhacktics.com/wiki/SHP_%26_Graphic_info_page
			var top_left_x:int =  frame_dec & "0x001f".hex_to_int() # first 5 bits
			var top_left_y:int = (frame_dec & "0x03e0".hex_to_int()) >> 5 # next 5 bits
			var size_index:int = (frame_dec & "0x3c00".hex_to_int()) >> 10 # next 4 bits
			var flip_x:bool = 	 (frame_dec & "0x4000".hex_to_int()) != 0 # next bit
			var flip_y:bool = 	 (frame_dec & "0x8000".hex_to_int()) != 0 # next bit

			top_left_x = top_left_x * pixels_per_tile
			top_left_y = (top_left_y * pixels_per_tile) + y_offset

			var text_parts:PackedStringArray = [
				frame_data_string, 
				str(x_shift), 
				str(y_shift), 
				str(top_left_x), 
				str(top_left_y), 
				str(subframe_sizes[size_index].x),
				str(subframe_sizes[size_index].y),
				str(flip_x), 
				str(flip_y)]

			frame_data_string = ",".join(text_parts);

			subframe += 1
		
		var allText:PackedStringArray = [output, frame_data_string];
		output = "\n".join(allText)

		hex_index = hex_index + 2 + (4 * num_subframes)
		frame_count +=1
		frame_id += 1

	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	var save_file = FileAccess.open("user://FFTorama/frame_data_"+file_name+".txt", FileAccess.WRITE)
	save_file.store_string(output)

	# print_debug(output)
	# print_debug("saved frame_data")

	# store frame offsets for wep and eff type spritesheets
	if (file_name.begins_with("wep") || file_name.begins_with("eff")):
		var offsets_start:int = 6 # start at knife
		
		var frame_offset_data:String = "Knife,Ninja Sword,Sword,Knight Sword,Katana,Axe,Rod,Staff,Flail,Gun,Crossbow,Bow,Instrument,Book,Spear,Pole,Bag,Cloth,Shield,Shuriken,Ball\n";
		
		var frame_offsets:PackedStringArray = [];
		var index:int = offsets_start
		while index < section1_length:
			var frame_offset:int = (hex_strings[index + 1] + hex_strings[index]).hex_to_int()
			frame_offsets.append(str(frame_offset))
			index += 2

		frame_offset_data = frame_offset_data + ",".join(frame_offsets)
		var save_file_offset:FileAccess = FileAccess.open("user://FFTorama/frame_offset_data_"+file_name+".txt", FileAccess.WRITE)
		save_file_offset.store_string(frame_offset_data);

		# print_debug(frame_offset_data)
		# print_debug("saved frame_offset_data")


func parse_seq(filepath:String) -> void:
	var file_name:String = filepath.get_file()
	file_name = file_name.trim_suffix(".seq")
	file_name = file_name.trim_suffix(".SEQ")
	file_name = file_name.trim_suffix(".Seq")
	file_name = file_name.to_lower()
	# print_debug(file_name)

	# var file = FileAccess.open(filepath, FileAccess.READ)
	var bytes:PackedByteArray = FileAccess.get_file_as_bytes(filepath)
	var hex_strings:PackedStringArray = []
	for byte in bytes:
		var hex_string:String = String.num_int64(byte, 16)
		if hex_string.length() == 1:
			hex_string = "0" + hex_string
		hex_strings.append(hex_string)
	# print_debug("size " + str(hex_strings.size()))
	# print_debug(hex_strings)


	var output:String = "label,animation_id,frame_id/opcode,delay/parameter"
	var data_string:String = ""

	var section1_length:int = 4
	var section2_length:int = "0x400".hex_to_int()
	var section3_start:int = section2_length + section1_length;
	var section3_length:int = (hex_strings[section3_start + 1] + hex_strings[section3_start]).hex_to_int()

	var data_start_index:int = section3_start + 2; # add 2 to get past the size

	var animation_indicies:PackedInt32Array = []
	var index:int = section1_length
	while index < section3_start:
		if ((hex_strings[index] + hex_strings[index+1] + hex_strings[index+2] + hex_strings[index+3]).to_lower() == "ffffffff"):
			index += 4
			continue

		var hex_index:String = hex_strings[index+1] + hex_strings[index]
		var dec_index = hex_index.hex_to_int()
		animation_indicies.append(dec_index)

		index += 4

	var animation_indicies_sorted:PackedInt32Array = animation_indicies.duplicate()
	animation_indicies_sorted.sort()

	var animation_id:int = 0
	while animation_id < animation_indicies.size():
		data_string = file_name + "," + str(animation_id)
		var text_parts:PackedStringArray

		# handle last animation
		var animation_end:int = section3_start + section3_length
		if (animation_id != animation_indicies.size() - 1): # handle non-last animation
			animation_end = animation_indicies_sorted[animation_indicies_sorted.find(animation_indicies[animation_id]) + 1] + data_start_index

		var pos:int = animation_indicies[animation_id] + data_start_index;
		while pos < animation_end:
			var opcode:String = (hex_strings[pos] + hex_strings[pos + 1]).to_lower()

			# handle opcodes
			if opcode_parameters.has(opcode):
				var opcode_name:String = opcode_names[opcode];
				var opcode_arguments:PackedStringArray = []
				var opcode_argument = 0
				while opcode_argument < opcode_parameters[opcode]:
					var argument_pos:int = pos + 2 + opcode_argument
					var argument:int = hex_strings[argument_pos].hex_to_int()

					# correct for signed 8 bit int
					if (opcode == "ffc0" || # WaitForDistort
					opcode == "ffc4" || # MFItemPosFBDU
					opcode == "ffc6" || # WaitForInput
					opcode == "ffd3" || # WeaponSheatheCheck1
					opcode == "ffd6" || # WeaponSheatheCheck2
					opcode == "ffd8" || # SetFrameOffset
					opcode == "ffee" || # MoveUnitFB
					opcode == "ffef" || # MoveUnitDU 
					opcode == "fff0" || # MoveUnitRL
					opcode == "fffa" || # MoveUnit RL, DU, FB
					(opcode == "fffc" && opcode_argument == 0) || # Wait (first parameter only)
					opcode == "fffd"): # HoldWeapon
						if (argument > 128):
							argument -= 256
					
					opcode_arguments.append(str(argument))
					opcode_argument += 1

				var arguments:String = ",".join(opcode_arguments)

				text_parts = [data_string, opcode_name]
				if arguments.length() > 0:
					text_parts.append(arguments)
				
				pos = pos + opcode_parameters[opcode] + 2; # add 2 to account for the bytes the opcode takes up
			else:
				var frame_id:int = hex_strings[pos].hex_to_int()
				var delay:int = hex_strings[pos + 1].hex_to_int()

				text_parts = [
					data_string, 
					str(frame_id),
					str(delay)]

				pos += 2

			data_string = data_string
			data_string = ",".join(text_parts) # ignore empty strings?

		var all_text:Array = [output, data_string];
		all_text.erase("") # ignore initial empty string
		output = "\n".join(all_text); 
		
		animation_id += 1

	
	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	var save_file = FileAccess.open("user://FFTorama/animation_data_"+file_name+".txt", FileAccess.WRITE)
	save_file.store_string(output)
	

func load_opcode_data(opcode_filepath:String) -> void:
	var file := FileAccess.open(opcode_filepath, FileAccess.READ)
	var input:String = file.get_as_text()		
	
	var lines:PackedStringArray = input.split("\n");

	# skip first row of headers
	var line_index:int = 1
	while line_index < lines.size():
		var parts:PackedStringArray = lines[line_index].split(",")
		var opcode_code:String = parts[2].substr(0, 4) # ignore any extra characters in text file
		var opcode_name:String = parts[0]
		var opcode_num_parameters:int = parts[1] as int

		opcode_names[opcode_code] = opcode_name
		opcode_parameters[opcode_code] = opcode_num_parameters

		line_index += 1


func _on_pressed():
	# print_debug("load file button pressed")
	file_dialog.visible = true


func _on_file_dialog_file_selected(path):
	parse_file(path)
	data_loader.load_custom_data()

func _on_file_dialog_files_selected(paths):
	for filepath in paths:
		parse_file(filepath)
		
	data_loader.load_custom_data()
