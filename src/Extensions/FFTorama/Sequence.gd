class_name Sequence

var seq_parts:Array[SeqPart] = []

var length:int = 0:
	get:
		var sum:int = 0
		for seq_part in seq_parts:
			sum += seq_part.length
		return sum # bytes
