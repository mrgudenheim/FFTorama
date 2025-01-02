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
