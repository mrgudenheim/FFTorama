extends SpinBox

@export var theme_min_character_width:int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_line_edit().add_theme_constant_override("minimum_character_width", theme_min_character_width)
	
	#for child in get_all_children(self, true):
		#if child is LineEdit:
			#child.add_theme_constant_override("minimum_character_width", theme_min_character_width)


#func get_all_children(node:Node, include_internal: bool = false) -> Array[Node]:
	#var nodes : Array[Node] = []
	#for N in node.get_children(include_internal):
		#if N.get_child_count(include_internal) > 0:
			#nodes.append(N)
			#nodes.append_array(get_all_children(N))
		#else:
			#nodes.append(N)
#
	#return nodes
