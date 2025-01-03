class_name Seq

static var seq_aliases: Dictionary = {
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


var file_name:String = "default_file_name"
var name_alias:String = "default_name_alias"

# section 1
var AA:int = 0
var BB:int = 0
var section1_length:int = 4

# section 2
var sequence_pointers:Array[int] = []
var section2_length:int = 0x400
	
# section 3
var sequences: Array[Sequence] = []
var section3_length:int = 0:
	get:
		#var sequence_pointers_sorted:Array[int] = sequence_pointers.duplicate()
		#sequence_pointers_sorted.sort()
		var sum:int = 2 + sequence_pointers[-1] # length to last seqence
		sum += sequences[-1].length # length of last sequence
		return sum
		
		#var sum:int = 0
		#for sequence in sequences:
			#sum += sequence.length
		#return sum + 2 # bytes

static var opcode_parameters: Dictionary
static var opcode_names: Dictionary
static var seq_names: Dictionary # [name_alias, [seq_index, seq_name]]


static func _static_init() -> void:
	load_opcode_data()
	load_seq_name_data()


func set_data_from_seq_object(seq_object:Seq) -> void:
	file_name = seq_object.file_name
	name_alias = seq_object.name_alias

	# section 1
	AA = seq_object.AA
	BB = seq_object.BB

	# section 2
	sequence_pointers = seq_object.sequence_pointers.duplicate()
	
	# section 3
	sequences = seq_object.sequences.duplicate()


func set_data_from_seq_file(filepath:String) -> void:	
	var new_file_name:String = filepath.get_file()
	new_file_name = new_file_name.trim_suffix(".seq")
	new_file_name = new_file_name.trim_suffix(".SEQ")
	new_file_name = new_file_name.trim_suffix(".Seq")
	new_file_name = new_file_name.to_lower()
	
	file_name = new_file_name
	if seq_aliases.has(file_name):
		name_alias = seq_aliases[file_name]
	else:
		name_alias = new_file_name
	
	var bytes:PackedByteArray = FileAccess.get_file_as_bytes(filepath)
	if bytes.size() == 0:
		push_warning("Open Error: " + filepath)
		return
	
	AA = bytes.decode_u16(0)
	BB = bytes.decode_u16(2)
	
	for seq_index in (section2_length / 4):
		var seq_pointer:int = bytes.decode_u32(section1_length + (seq_index * 4))
		if seq_index > 0 and seq_pointer == 0xFFFFFFFF:
			break # skip to section 3 if no more pointers in section 2
		sequence_pointers.append(seq_pointer)
	
	var sequence_data_start = section1_length + section2_length + 2
	var section3_length_temp = bytes.decode_u16(sequence_data_start - 2)
	sequences.clear()
	for seq_pointer in sequence_pointers:
		var seq_offset:int = sequence_data_start + seq_pointer
		
	var sequence_pointers_sorted:PackedInt32Array = sequence_pointers.duplicate()
	sequence_pointers_sorted.sort()

	for seq_index in sequence_pointers.size():
		var seq_pointer = sequence_pointers[seq_index]
		
		# get location of the end of the sequence
		var sequence_end_pointer:int = 0
		if seq_pointer == sequence_pointers_sorted[-1]:
				sequence_end_pointer = section3_length_temp
		else:
			for sorted_seq_index:int in sequence_pointers_sorted.size():
				if sequence_pointers_sorted[sorted_seq_index] > seq_pointer:
					sequence_end_pointer = sequence_pointers_sorted[sorted_seq_index]
					break
		
		var sequence_bytes:PackedByteArray = bytes.slice(sequence_data_start + seq_pointer, sequence_data_start + sequence_end_pointer)
		sequences.append(get_sequence_data(sequence_bytes))
		
		#push_warning(name_alias + " " + str(seq_names.has(name_alias)) + " " + str(seq_index))
		if seq_names.has(name_alias):
			#push_warning(name_alias + " " + str(seq_names.has(name_alias)) + " " + str(seq_index) + " " + str(seq_names[name_alias].has(seq_index)))
			if seq_names[name_alias].has(seq_index):
				sequences[-1].seq_name = seq_names[name_alias][seq_index]


func get_sequence_data(bytes:PackedByteArray) -> Sequence:
	var seq:Sequence = Sequence.new()
	var seq_part_pointer:int = 0
	while seq_part_pointer < bytes.size():
		var seq_part:SeqPart = SeqPart.new()
		var num_params:int = 2
		var signed:bool = false
		if bytes.decode_u8(seq_part_pointer) == 0xFF:
			var opcode:String = "%x%x" % [bytes.decode_u8(seq_part_pointer), bytes.decode_u8(seq_part_pointer + 1)]
			#push_warning(opcode)
			seq_part.opcode = opcode
			seq_part.opcode_name = opcode_names[opcode]
			num_params = opcode_parameters[opcode]
			
		for param:int in num_params:
			var offset:int = seq_part_pointer + param
			if seq_part.isOpcode:
				offset += 2
			# signed parameters
			if (seq_part.opcode == "ffc0" # WaitForDistort
				or seq_part.opcode == "ffc4" # MFItemPosFBDU
				or seq_part.opcode == "ffc6" # WaitForInput
				or seq_part.opcode == "ffd3" # WeaponSheatheCheck1
				or seq_part.opcode == "ffd6" # WeaponSheatheCheck2
				or seq_part.opcode == "ffd8" # SetFrameOffset
				or seq_part.opcode == "ffee" # MoveUnitFB
				or seq_part.opcode == "ffef" # MoveUnitDU 
				or seq_part.opcode == "fff0" # MoveUnitRL
				or seq_part.opcode == "fffa" # MoveUnit RL, DU, FB
				or (seq_part.opcode == "fffc" && param == 0) # Wait (first parameter only)
				or seq_part.opcode == "fffd"): # HoldWeapon:
				seq_part.parameters.append(bytes.decode_s8(offset))
			else:
				seq_part.parameters.append(bytes.decode_u8(offset))
		
		seq.seq_parts.append(seq_part)
		seq_part_pointer += seq_part.length
	
	return seq


func write_seq() -> void:
	var bytes:PackedByteArray = []
	bytes.resize(section1_length + section2_length + section3_length)
	bytes.fill(0)
	
	# section 1
	bytes.encode_u16(0, AA)
	bytes.encode_u16(2, BB)
	
	# section 2
	for seq_pointer_index in sequence_pointers.size():
		bytes.encode_u32(section1_length + (4 * seq_pointer_index), sequence_pointers[seq_pointer_index])
	
	var sequence_pointers_length:int = sequence_pointers.size() * 4
	var section2_empty_length:int = section2_length - sequence_pointers_length
	for empty_index:int in section2_empty_length:
		bytes.encode_u8(section1_length + sequence_pointers_length + empty_index, 0xFF)
	
	# section 3
	bytes.encode_u16(section1_length + section2_length, section3_length - 2)
	var offset:int = 0
	for seq_index:int in sequence_pointers.size():
		offset = section1_length + section2_length + 2 + sequence_pointers[seq_index] # pointers are not guaranteed to always increase
		for seq_part:SeqPart in sequences[seq_index].seq_parts:
			if seq_part.isOpcode:
				bytes.encode_u8(offset, 0xFF)
				bytes.encode_u8(offset + 1, seq_part.opcode.substr(2).hex_to_int())
				offset += 2
			for param:int in seq_part.parameters:
				bytes.encode_u8(offset, param)
				offset += 1
	
	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	var save_file := FileAccess.open("user://FFTorama/"+file_name+".seq", FileAccess.WRITE)
	save_file.store_buffer(bytes)


func set_data_from_cfg(filepath:String) -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(filepath)
	#var err = cfg.load("user://FFTorama/"+file_name+"_shp.cfg")

	if err != OK:
		push_warning("Error Opening: " + str(err) + " - " + filepath)
		return
	
	file_name = filepath.get_file()
	file_name = file_name.trim_suffix("_seq.cfg")
	name_alias = cfg.get_value(file_name, "name_alias")
	
	AA = cfg.get_value(file_name, "AA")
	BB = cfg.get_value(file_name, "BB")
	sequence_pointers = cfg.get_value(file_name, "sequence_pointers")
	
	for seq_index:int in sequence_pointers.size():
		var seq_label:String = file_name + "-" + str(seq_index)
		var seq_data:Sequence = Sequence.new()
		var seq_parts_size = cfg.get_value(seq_label, "size")
		seq_data.seq_name = cfg.get_value(seq_label, "seq_name")
		
		for seq_part_index in seq_parts_size:
			var seq_part_label:String = seq_label + "-" + str(seq_part_index)
			var seq_part_data:SeqPart = SeqPart.new()
			seq_part_data.opcode = cfg.get_value(seq_part_label, "opcode")
			seq_part_data.opcode_name = cfg.get_value(seq_part_label, "opcode_name")
			seq_part_data.parameters = cfg.get_value(seq_part_label, "parameters")
			
			seq_data.seq_parts.append(seq_part_data)
			
		sequences.append(seq_data)


func write_cfg() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value(file_name, "file_name", file_name)
	cfg.set_value(file_name, "name_alias", name_alias)
	cfg.set_value(file_name, "AA", AA)
	cfg.set_value(file_name, "BB", BB)
	cfg.set_value(file_name, "sequence_pointers", sequence_pointers)
	
	for seq_index:int in sequences.size():
		var seq_label:String = file_name + "-" + str(seq_index)
		var seq_data:Sequence = sequences[seq_index]
		cfg.set_value(seq_label, "size", seq_data.seq_parts.size())
		cfg.set_value(seq_label, "seq_name", seq_data.seq_name)
		
		for seq_part_index in seq_data.seq_parts.size():
			var seq_part_label:String = seq_label + "-" + str(seq_part_index)
			var seq_part_data:SeqPart = seq_data.seq_parts[seq_part_index]
			cfg.set_value(seq_part_label, "opcode", seq_part_data.opcode)
			cfg.set_value(seq_part_label, "opcode_name", seq_part_data.opcode_name)
			cfg.set_value(seq_part_label, "parameters", seq_part_data.parameters)
	
	cfg.save("user://FFTorama/"+file_name+"_seq.cfg")


func set_sequences_from_csv(filepath:String) -> void:
	sequences.clear()
	
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_warning(FileAccess.get_open_error())
		return
	var sequence_data_csv:String = file.get_as_text()
	
	if file_name == "default_file_name":
		var new_file_name:String = filepath.get_file()
		new_file_name = new_file_name.trim_suffix(".csv")
		new_file_name = new_file_name.trim_suffix(".txt")
		new_file_name = new_file_name.trim_prefix("animation_data_")
		new_file_name = new_file_name.to_lower()
		
		file_name = new_file_name
		name_alias = new_file_name
	
	var sequences_split:PackedStringArray = sequence_data_csv.split("\n")
	sequences_split = sequences_split.slice(1, sequences_split.size()) # skip first row of headers
	
	var seq_part_start:int = 3 # skip past label, seq_id, and seq_name
	
	name_alias = sequences_split[0].split(",")[0]
	
	for seq_text:String in sequences_split:
		var seq_text_split:PackedStringArray = seq_text.split(",")
		var new_seq:Sequence = Sequence.new()
		new_seq.seq_name = seq_text_split[2]
		seq_text_split = seq_text_split.slice(seq_part_start)
		
		var index:int = 0
		while index < seq_text_split.size():
			var seq_part:SeqPart = SeqPart.new()
			var initial:String = seq_text_split[index]
			if opcode_names.values().has(initial):
				seq_part.opcode_name = initial
				seq_part.opcode = opcode_parameters.keys()[opcode_parameters.values().find(initial)]
				var num_params:int = opcode_parameters[seq_part.opcode]
				for param_index:int in num_params:
					seq_part.parameters.append(seq_text_split[index + param_index].to_int())
				
				index += num_params + 1
			else:
				for param_index:int in 2:
					seq_part.parameters.append(seq_text_split[index + param_index].to_int())
					
				index += 2
				
			new_seq.seq_parts.append(seq_part)
		
		sequences.append(new_seq)


func write_csv() -> void:
	var headers:PackedStringArray = [
		"label",
		"seq_id",
		"seq_name",
		"frame_id/opcode",
		"delay/parameter",
	]
	
	var output:String = ",".join(headers)
	var seq_data_string:String = ""
	
	var seq_id:int = 0
	for seq:Sequence in sequences:
		var seq_data:PackedStringArray = [
			name_alias,
			str(seq_id),
			str(seq.seq_name),
		]
		seq_data_string = ",".join(seq_data)
		
		for seq_part:SeqPart in seq.seq_parts:
			var text_parts:PackedStringArray = [seq_data_string]
			
			if seq_part.isOpcode:
				text_parts.append(seq_part.opcode_name)
			if seq_part.parameters.size() > 0:
				text_parts.append(",".join(seq_part.parameters))

			seq_data_string = ",".join(text_parts);
		
		var allText:PackedStringArray = [output, seq_data_string];
		output = "\n".join(allText)
	
		seq_id += 1

	DirAccess.make_dir_recursive_absolute("user://FFTorama")
	var save_file = FileAccess.open("user://FFTorama/animation_data_"+file_name+".txt", FileAccess.WRITE)
	save_file.store_string(output)


# https://ffhacktics.com/wiki/SEQ_%26_Animation_info_page
static func load_opcode_data() -> void:
	var opcode_filepath:String = "res://src/Extensions/FFTorama/SeqData/opcodeParameters.txt"
	
	var file := FileAccess.open(opcode_filepath, FileAccess.READ)
	var input:String = file.get_as_text()
	
	var lines:PackedStringArray = input.split("\n");

	# skip first row of headers
	var line_index:int = 1
	while line_index < lines.size():
		var parts:PackedStringArray = lines[line_index].split(",")
		if parts.size() <= 2:
			line_index += 1
			continue
		
		var opcode_code:String = parts[2].substr(0, 4) # ignore any extra characters in text file
		var opcode_name:String = parts[0]
		var opcode_num_parameters:int = parts[1] as int

		opcode_names[opcode_code] = opcode_name
		opcode_parameters[opcode_code] = opcode_num_parameters

		line_index += 1


static func load_seq_name_data() -> void:
	var filepath:String = "res://src/Extensions/FFTorama/SeqData/animation_names.txt"
	
	var file := FileAccess.open(filepath, FileAccess.READ)
	var input:String = file.get_as_text()
	
	var lines:PackedStringArray = input.split("\n");

	# skip first row of headers
	var line_index:int = 1
	while line_index < lines.size():
		var parts:PackedStringArray = lines[line_index].split(",")
		if parts.size() <= 2:
			line_index += 1
			continue
		
		if not seq_names.has(parts[0]):
			seq_names[parts[0]] = {}
		seq_names[parts[0]][parts[1].to_int()] = parts[2]
		
		line_index += 1
