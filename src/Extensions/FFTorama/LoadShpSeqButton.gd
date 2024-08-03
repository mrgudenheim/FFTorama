extends Button


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

# # Called when the node enters the scene tree for the first time.
# func _ready():
# 	pass # Replace with function body.


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass

func ParseFile(filepath:String) -> void:
	# print_debug(filepath)

	# using var file = Godot.FileAccess.Open(filepath, Godot.FileAccess.ModeFlags.Read);
	# 	// string inputHex = file.GetAsText();
	
	var file_extension:String = filepath.get_extension()
	if file_extension.to_lower() == "shp":
		ParseShp(filepath)
	elif file_extension.to_lower() == "seq":
		pass
		# ParseSeq(filepath);


func ParseShp (filepath:String) -> void:
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
	print_debug("size " + str(hex_strings.size()))
	print_debug(hex_strings)


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

	print_debug("frame_data_start_index " + str(frame_data_start_index))
	print_debug("swim_start_index " + str(swim_start_index))
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

			# var frame_bits:Packed

			# BitArray frameBits = new BitArray(new int[] {frameDec} );
			# string frameBitsString = Reverse(ToBitString(frameBits));

			print_debug(str(frame_dec) + " " + frame_hex)
			print_debug(frame_dec & "0x001f".hex_to_int())
			print_debug((frame_dec & "0x03e0".hex_to_int()) >> 5)
			print_debug((frame_dec & "0x3c00".hex_to_int()) >> 10)
			# https://ffhacktics.com/wiki/SHP_%26_Graphic_info_page
			var top_left_x:int =  frame_dec & "0x001f".hex_to_int() # first 5 bits
			var top_left_y:int = (frame_dec & "0x03e0".hex_to_int()) >> 5 # next 5 bits
			var size_index:int = (frame_dec & "0x3c00".hex_to_int()) >> 10 # next 4 bits
			var flip_x:bool = 	 (frame_dec & "0x4000".hex_to_int()) != 0 # next bit
			var flip_y:bool = 	 (frame_dec & "0x8000".hex_to_int()) != 0 # next bit
			# var top_left_x:int = frame_dec % 2^5 # first 5 bits
			# var top_left_y:int = (frame_dec >> 5) % 2^5 # next 5 bits
			# var size_index:int = (frame_dec >> 10) % 2^4 # next 4 bits
			# var flip_x:bool = (frame_dec >> 14) % 2^1 # next bit
			# var flip_y:bool = (frame_dec >> 15) % 2^1 # next bit

			top_left_x = top_left_x * pixels_per_tile
			top_left_y = (top_left_y * pixels_per_tile) + y_offset

			# string topLeftXString = frameBitsString.Substring(frameBitsString.Length - 5, 5);
			# string topLeftYString = frameBitsString.Substring(frameBitsString.Length - 10, 5);
			# string sizeRefString = frameBitsString.Substring(frameBitsString.Length - 14, 4);
			# string flipXString = frameBitsString.Substring(frameBitsString.Length - 15, 1);
			# string flipYString = frameBitsString.Substring(frameBitsString.Length - 16, 1);

			# int topLeftX = Convert.ToInt32(topLeftXString, 2) * pixelsPerTile;
			# int topLeftY = (Convert.ToInt32(topLeftYString, 2) * pixelsPerTile) + yOffset;
			# int sizeRef = Convert.ToInt32(sizeRefString, 2);

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


func _on_pressed():
	# print_debug("load file button pressed")
	file_dialog.visible = true


func _on_file_dialog_file_selected(path):
	ParseFile(path)


func _on_file_dialog_files_selected(paths):
	for filepath in paths:
		ParseFile(filepath)
