extends TextureRect

@export var viewport: SubViewport


func _on_item_rect_changed() -> void:
	pass # Replace with function body.


func _on_resized() -> void:
	viewport.size = self.texture.get_size()
