class_name SeqPart

var opcode:String = "LoadFrameAndWait"
var opcode_name:String = "LoadFrameAndWait"
var parameters:Array[int] = []

var isOpcode:bool = false:
	get:
		return opcode != "LoadFrameAndWait"

var length:int = 0:
	get:
		var length_temp:int = parameters.size()
		if isOpcode:
			length_temp += 2
		return length_temp

func _to_string() -> String:
	var total_string:String = opcode_name + "("
	var parameters_string:PackedStringArray = []
	for parameter in parameters:
		parameters_string.append(str(parameter))
	return total_string + ",".join(parameters_string) + ")"
