class_name Sequence

var seq_parts:Array[SeqPart] = []
var seq_name:String = ""

var length:int = 0:
	get:
		var sum:int = 0
		for seq_part in seq_parts:
			sum += seq_part.length
		return sum # bytes

func _to_string() -> String:
	var string_list:PackedStringArray = []
	for part in seq_parts:
		string_list.append(part.to_string())
	
	return ",".join(string_list)
