class_name Shp

const SUBFRAME_RECT_SIZES: PackedVector2Array = [
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
	Vector2( 56, 56 ),
];

# https://ffhacktics.com/wiki/Sprite_Y_Rotation_Table
const ROTATIONS_DEGREES: PackedFloat64Array = [
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
	164.971,
];

const PIXELS_PER_TILE = 8

var file_name:String = "default_file_name"
var name_alias:String = "default_name_alias"

# section 1
var swim_pointer:int = 0
var attack_start_index:int = 0
var sp_extra:int = 0
var zero_frames:Array[int] = [] # only used in wep or eff
var section1_length:int = 0:
	get:
		return 0x44 if (file_name.begins_with("wep") or file_name.begins_with("eff")) else 8

# section 2
var frame_pointers:Array[int] = []
var section2_length:int = 0:
	get:
		return 0x800 if (file_name.begins_with("wep") or file_name.begins_with("eff")) else 0x400
	
# section 3
var frames: Array[FrameData] = []
var section3_length:int = 0:
	get:
		var sum:int = 0
		for frame in frames:
			sum += frame.size
		return sum + 2 # bytes


func set_data_from_shp_object(shp_object:Shp) -> void:
	var file_name:String = "default_file_name"
	var name_alias:String = "default_name_alias"

	# section 1
	swim_pointer = shp_object.swim_pointer
	attack_start_index = shp_object.attack_start_index
	sp_extra = shp_object.sp_extra
	zero_frames = shp_object.zero_frames.duplicate()

	# section 2
	frame_pointers = shp_object.frame_pointers.duplicate()
	
	# section 3
	frames = shp_object.frames.duplicate()

func set_data_from_shp_file(bytes:PackedByteArray) -> void:	
	swim_pointer = bytes.decode_u32(0)
	attack_start_index = bytes.decode_u16(4)
	sp_extra = bytes.decode_u16(6)
	
	# these shapes have a slightly different format
	if (file_name.begins_with("wep") or file_name.begins_with("eff")):
		attack_start_index = 9999; # these types do not have a second (lower) half
		
		var initial_offset = 6 # skip first bytes and unarmed
		for index in ((section1_length - initial_offset) / 2):
			var zero_frame:int = bytes.decode_u16(initial_offset + (index*2))
			zero_frames.append(zero_frame)
		
	
	for frame_index in (section2_length / 4):
		var frame_pointer:int = bytes.decode_u32(section1_length + (frame_index * 4))
		if frame_index > 0 and frame_pointer == 0:
			break # skip to section 3 if no more pointers in section 2
		frame_pointers.append(frame_pointer)
	
	var frame_data_start = section1_length + section2_length + 2
	frames.clear()
	for frame_pointer in frame_pointers:
		var frame_offset:int = frame_data_start + frame_pointer
		var num_subframes:int = 1 + (bytes.decode_u8(frame_offset) & 0b00000111)
		var frame_length:int = 2 + (num_subframes * 4)
		frames.append(get_frame_data(bytes.slice(frame_offset, frame_offset + frame_length)))


func set_frames_from_csv(frame_data_csv:String) -> void:
	frames.clear()
	var frames_split:PackedStringArray = frame_data_csv.split("\n")
	frames_split = frames_split.slice(1, frames_split.size()) # skip first row of headers
	
	var subframe_offset:int = 6 # skip past label, frame_id, num_subframes, rotation_degrees, transparency_type, transparency_flag
	var subframe_length:int = 8

	var frames = []

	for frame_text:String in frames_split:
		var frame_text_split:PackedStringArray = frame_text.split(",")
		
		if(frame_text[0] == ""):
			continue
		
		var new_frame:FrameData = FrameData.new()
		
		new_frame.num_subframe = frame_text_split[2] as int
		new_frame.rotation_degrees = frame_text_split[3] as float
		new_frame.transparency_type = frame_text_split[4] as int
		new_frame.transparency_flag = frame_text_split[5] as bool
		#var frame_data = [num_subframe, rotation_degrees]

		for i in new_frame.num_subframe:
			var new_subframe:SubFrameData = SubFrameData.new()
			
			new_subframe.shift_x = frame_text_split[subframe_offset + (subframe_length*i)] as int
			new_subframe.shift_y = frame_text_split[subframe_offset + 1 + (subframe_length*i)] as int
			new_subframe.load_location_x = frame_text_split[subframe_offset + 2 + (subframe_length*i)] as int
			new_subframe.load_location_y = frame_text_split[subframe_offset + 3 + (subframe_length*i)] as int
			var rect_size_x = frame_text_split[subframe_offset + 4 + (subframe_length*i)] as int
			var rect_size_y = frame_text_split[subframe_offset + 5 + (subframe_length*i)] as int
			new_subframe.rect_size = Vector2i(rect_size_x, rect_size_y)
			new_subframe.flip_x = frame_text_split[subframe_offset + 6 + (subframe_length*i)].to_lower() == "true" as bool
			new_subframe.flip_y = frame_text_split[subframe_offset + 7 + (subframe_length*i)].to_lower() == "true" as bool

			new_frame.sub_frames.append(new_subframe)

		frames.append(new_frame)
		# print(frame_data)


func set_zero_frames_from_csv(frame_offsets_data_csv:String) -> void:
	zero_frames.clear()
	
	var offsets_split:PackedStringArray = frame_offsets_data_csv.split("\n")
	offsets_split = offsets_split[1].split(",")
	for offset:String in offsets_split:
		zero_frames.append(offset as int)
	pass


func set_data_from_cfg() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load("user://FFTorama/"+file_name+"_shp.cfg")

	if err != OK:
		print_debug(err)
	
	file_name = cfg.get_value(file_name, "file_name")
	name_alias = cfg.get_value(file_name, "name_alias")
	swim_pointer = cfg.get_value(file_name, "swim_pointer")
	attack_start_index = cfg.get_value(file_name, "attack_start_index")
	sp_extra = cfg.get_value(file_name, "sp_extra")
	zero_frames = cfg.get_value(file_name, "zero_frames")
	frame_pointers = cfg.get_value(file_name, "frame_pointers")
	
	for frame_index in frame_pointers.size():
		var frame_label:String = file_name + "-" + str(frame_index)
		frames.append(FrameData.new())
		frames[frame_index].num_subframes = cfg.get_value(frame_label, "num_subframes")
		frames[frame_index].y_rotation = cfg.get_value(frame_label, "y_rotation")
		frames[frame_index].transparency_type = cfg.get_value(frame_label, "transparency_type")
		frames[frame_index].transparency_flag = cfg.get_value(frame_label, "transparency_flag")
		frames[frame_index].byte2_3 = cfg.get_value(frame_label, "byte2_3")
		frames[frame_index].byte2_4 = cfg.get_value(frame_label, "byte2_4")
		
		for subframe_index in frames[frame_index].num_subframes:
			var subframe_label:String = frame_label + "-" + str(subframe_index)
			frames[frame_index].sub_frames.append(SubFrameData.new())
			frames[frame_index].sub_frames[subframe_index].shift_x = cfg.get_value(subframe_label, "shift_x")
			frames[frame_index].sub_frames[subframe_index].shift_y = cfg.get_value(subframe_label, "shift_y")
			frames[frame_index].sub_frames[subframe_index].load_location_x = cfg.get_value(subframe_label, "load_location_x")
			frames[frame_index].sub_frames[subframe_index].load_location_y = cfg.get_value(subframe_label, "load_location_y")
			frames[frame_index].sub_frames[subframe_index].rect_size = cfg.get_value(subframe_label, "rect_size")
			frames[frame_index].sub_frames[subframe_index].flip_x = cfg.get_value(subframe_label, "flip_x")
			frames[frame_index].sub_frames[subframe_index].flip_y = cfg.get_value(subframe_label, "flip_y")

func write_csvs() -> void:
	var headers:PackedStringArray = [
		"label",
		"frame_id",
		"num_subframes",
		"rotation_degrees",
		"transparency_type",
		"transparency_flag",
		"shift_x",
		"shift_y",
		"top_left_x_pixels",
		"top_left_y_pixels",
		"sizeX",
		"sizeY",
		"flip_x",
		"flip_y",
	]
	var output:String = ",".join(headers)
	var frame_data_string:String = ""
	
	var frame_id:int = 0
	for frame:FrameData in frames:
		var frame_data:PackedStringArray = [
			file_name,
			str(frame_id),
			str(frame.num_subframes),
			str(frame.y_rotation),
			str(frame.transparency_type),
			str(frame.transparency_flag),
		]
		frame_data_string = ",".join(frame_data)
		#frame_data_string = file_name + "," + str(frame_id) + "," + str(frame.num_subframes) + "," + str(frame.y_rotation)
		
		var subframe_index:int = 0
		for subframe:SubFrameData in frame.sub_frames:
		#while subframe_index < frame.num_subframes:
			var text_parts:PackedStringArray = [
				frame_data_string, 
				str(subframe.shift_x),
				str(subframe.shift_y), 
				str(subframe.load_location_x), 
				str(subframe.load_location_y), 
				str(subframe.rect_size.x),
				str(subframe.rect_size.y),
				str(subframe.flip_x), 
				str(subframe.flip_y)]

			frame_data_string = ",".join(text_parts);
		
		var allText:PackedStringArray = [output, frame_data_string];
		output = "\n".join(allText)
	
		frame_id += 1

	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	var save_file = FileAccess.open("user://FFTorama/frame_data_"+file_name+".txt", FileAccess.WRITE)
	save_file.store_string(output)
	
	if (file_name.begins_with("wep") || file_name.begins_with("eff")):
		var offsets_start:int = 6 # start at knife
		
		var frame_offset_headers:PackedStringArray = [
			"Knife",
			"Ninja Sword",
			"Sword",
			"Knight Sword",
			"Katana",
			"Axe",
			"Rod",
			"Staff",
			"Flail",
			"Gun",
			"Crossbow",
			"Bow",
			"Instrument",
			"Book",
			"Spear",
			"Pole",
			"Bag",
			"Cloth",
			"Shield",
			"Shuriken",
			"Ball",
		]
		var frame_offset_data:String = ",".join(frame_offset_headers)
		frame_offset_data = frame_offset_data + "\n"
		
		frame_offset_data = frame_offset_data + ",".join(zero_frames)
		var save_file_offset:FileAccess = FileAccess.open("user://FFTorama/frame_offset_data_"+file_name+".txt", FileAccess.WRITE)
		save_file_offset.store_string(frame_offset_data);


func write_shp() -> void:
	var bytes:PackedByteArray = []
	bytes.resize(section1_length + section2_length + section3_length)
	bytes.fill(0)
	
	# section 1
	# wep and eff shapes have a slightly different format
	if (file_name.begins_with("wep") or file_name.begins_with("eff")):
		var initial_offset = 6
		
		# skip zero bytes and unarmed
		bytes.encode_u8(0, 0)
		bytes.encode_u8(1, 0)
		bytes.encode_u8(2, 0)
		bytes.encode_u8(3, 0)
		bytes.encode_u8(4, 0)
		bytes.encode_u8(5, 0)
				
		for zero_frame_index in zero_frames.size():
			bytes.encode_u16(initial_offset + (zero_frame_index*2), zero_frames[zero_frame_index])
	else:
		bytes.encode_u32(0, swim_pointer)
		bytes.encode_u16(4, attack_start_index)
		bytes.encode_u16(6, sp_extra)
		
	
	# section 2
	for frame_index in frame_pointers.size():
		bytes.encode_u32(section1_length + (frame_index * 4), frame_pointers[frame_index])
	
	# section 3
	bytes.encode_u16(section1_length + section2_length, section3_length)
	var frame_data_start = section1_length + section2_length + 2
	for frame_index in frame_pointers.size():
		var frame_offset:int = frame_data_start + frame_pointers[frame_index]
		var frame_data := frames[frame_index]
		var b1:int = frame_data.num_subframes - 1
		var b1_2:int = ROTATIONS_DEGREES.find(frame_data.y_rotation) << 3
		b1 = b1 | b1_2
		
		var b2:int = (frame_data.transparency_flag as int) & 0b01
		var b2_2:int = frame_data.byte2_3 << 1
		var b2_3:int = frame_data.transparency_type << 5
		var b2_4:int = frame_data.byte2_4 << 7
		b2 = b2 | b2_2
		b2 = b2 | b2_3
		b2 = b2 | b2_4
		
		bytes.encode_u8(frame_offset, b1)
		bytes.encode_u8(frame_offset + 1, b2)
		
		for subframe_index in frame_data.sub_frames.size():
			var subframe:SubFrameData = frame_data.sub_frames[subframe_index]
			var b56:int = subframe.load_location_x
			var b56_2:int = subframe.load_location_y << 5
			var b56_3:int = SUBFRAME_RECT_SIZES.find(subframe.rect_size) << 10
			var b56_4:int = (subframe.flip_x as int) << 14
			var b56_5:int = (subframe.flip_y as int) << 15
			
			b56 = b56 | b56_2
			b56 = b56 | b56_3
			b56 = b56 | b56_4
			b56 = b56 | b56_5
			
			bytes.encode_s8(frame_offset + 2 + (subframe_index * 4), subframe.shift_x)
			bytes.encode_s8(frame_offset + 3 + (subframe_index * 4), subframe.shift_y)
			bytes.encode_u16(frame_offset + 4 + (subframe_index * 4), b56)
		
	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	var save_file := FileAccess.open("user://FFTorama/"+file_name+".shp", FileAccess.WRITE)
	save_file.store_buffer(bytes)


func write_cfg() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value(file_name, "file_name", file_name)
	cfg.set_value(file_name, "name_alias", name_alias)
	cfg.set_value(file_name, "swim_pointer", swim_pointer)
	cfg.set_value(file_name, "attack_start_index", attack_start_index)
	cfg.set_value(file_name, "sp_extra", sp_extra)
	cfg.set_value(file_name, "zero_frames", zero_frames)
	cfg.set_value(file_name, "frame_pointers", frame_pointers)
	
	for frame_index:int in frames.size():
		var frame_label:String = file_name + "-" + str(frame_index)
		var frame_data:FrameData = frames[frame_index]
		cfg.set_value(frame_label, "num_subframes", frame_data.num_subframes)
		cfg.set_value(frame_label, "y_rotation", frame_data.y_rotation)
		cfg.set_value(frame_label, "transparency_type", frame_data.transparency_type)
		cfg.set_value(frame_label, "transparency_flag", frame_data.transparency_flag)
		cfg.set_value(frame_label, "byte2_3", frame_data.byte2_3)
		cfg.set_value(frame_label, "byte2_4", frame_data.byte2_4)
		
		for subframe_index in frame_data.num_subframes:
			var subframe_label:String = frame_label + "-" + str(subframe_index)
			var subframe_data:SubFrameData = frame_data.sub_frames[subframe_index]
			cfg.set_value(subframe_label, "shift_x", subframe_data.shift_x)
			cfg.set_value(subframe_label, "shift_y", subframe_data.shift_y)
			cfg.set_value(subframe_label, "load_location_x", subframe_data.load_location_x)
			cfg.set_value(subframe_label, "load_location_y", subframe_data.load_location_y)
			cfg.set_value(subframe_label, "rect_size", subframe_data.rect_size)
			cfg.set_value(subframe_label, "flip_x", subframe_data.flip_x)
			cfg.set_value(subframe_label, "flip_y", subframe_data.flip_y)
	
	
	cfg.save("user://FFTorama/"+file_name+"_shp.cfg")
	
	
	#var json_string = JSON.stringify(self)
	#
	#DirAccess.make_dir_recursive_absolute("user://FFTorama")
	#var save_file = FileAccess.open("user://FFTorama/"+file_name+"_shp.json", FileAccess.WRITE)
	#save_file.store_string(json_string)


func get_frame_data(bytes:PackedByteArray) -> FrameData:
	var frame_data = FrameData.new()
	
	frame_data.num_subframes = 1 + (bytes.decode_u8(0) & 0x07)
	var y_rotation_pointer:int = (bytes.decode_u8(0) & 0xF8) >> 3
	frame_data.y_rotation = ROTATIONS_DEGREES[y_rotation_pointer]
	frame_data.transparency_type = (bytes.decode_u8(1) & 0x60) >> 5
	frame_data.transparency_flag = (bytes.decode_u8(1) & 0x01) == 1
	frame_data.byte2_3 = (bytes.decode_u8(1) & 0x1E) >> 1
	frame_data.byte2_4 = (bytes.decode_u8(1) & 0x80) >> 7
	
	for subframe_index in frame_data.num_subframes:
		var subframe_start:int = 2 + (subframe_index * 4)
		var subframe_bytes:PackedByteArray = bytes.slice(subframe_start, subframe_start + 4)
		frame_data.sub_frames.append(get_subframe_data(subframe_bytes))
	
	return frame_data


func get_subframe_data(bytes:PackedByteArray) -> SubFrameData:
	var subframe:SubFrameData = SubFrameData.new()
	
	subframe.shift_x = bytes.decode_s8(0)
	subframe.shift_y = bytes.decode_s8(1)
	
	var bytes23 = bytes.decode_u16(2)
	subframe.load_location_x = bytes23 & 0x001F # 8px tiles
	subframe.load_location_y = (bytes23 & 0x03E0) >> 5 # 8px tiles
	var rect_size_index:int = (bytes23 & 0x3C00) >> 10
	subframe.rect_size = SUBFRAME_RECT_SIZES[rect_size_index] # in 8px tiles
	subframe.flip_x = (bytes23 & 0x4000) != 0
	subframe.flip_y = (bytes23 & 0x8000) != 0
	
	#var y_offset:int = 0
	#if frame_count >= first_attack_frame:
		#y_offset = 256 # subframe should be loaded from second half of sprite sheet
	#subframe.load_location_x = subframe.load_location_x * PIXELS_PER_TILE
	#subframe.load_location_y = (subframe.load_location_y * PIXELS_PER_TILE) + y_offset
	
	return subframe


class FrameData:
	var num_subframes:int = 0
	var y_rotation:float = 0
	var transparency_type:int = 0
	var transparency_flag:bool = false
	var byte2_3:int = 0
	var byte2_4:int = 0
	var sub_frames: Array[SubFrameData] = []
	
	var size:int = 0:
		get:
			return 2 + (4 * sub_frames.size()) # bytes


class SubFrameData:
	const SUBFRAME_LENGTH:int = 4 # bytes
	var shift_x:int = 0
	var shift_y:int = 0
	var load_location_x:int = 0 # 8px tiles
	var load_location_y:int = 0 # 8px tiles
	var rect_size:Vector2i = Vector2i.ONE # in 8px tiles
	var flip_x:bool = false
	var flip_y:bool = false
