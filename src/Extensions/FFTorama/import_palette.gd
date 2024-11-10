extends Button

@export var file_dialog:FileDialog
	
func _on_file_dialog_file_selected(path: String) -> void:
	var bmp_file:PackedByteArray = FileAccess.get_file_as_bytes(path)
	
	var bits_per_pixel:int = bmp_file.decode_u16(0x001C)
	var palette_data_offset = 0x0036
	var num_colors = 2**bits_per_pixel
	
	if bits_per_pixel > 8:
		print_debug("More than 8 bits per pixel, can't extract palette")
		return
	
	Palettes.create_new_palette(Palettes.NewPalettePresetType.EMPTY, path.get_file().split(".")[0], "Imported from " + path.get_file(), 16, num_colors/16, true, Palettes.GetColorsFrom.CURRENT_CEL)
	Palettes.select_palette(path.get_file().split(".")[0])
	#if num_colors > Palettes.current_palette.colors.size():
		#Palettes.current_palette.edit(Palettes.current_palette.name, 16, num_colors/16, "Imported from " + path.get_file())
	
	for i in num_colors:
		var color:Color = Color.BLACK
		color.b8 = bmp_file.decode_u8(0x0036 + (i*4))
		color.g8 = bmp_file.decode_u8(0x0036 + (i*4) + 1)
		color.r8 = bmp_file.decode_u8(0x0036 + (i*4) + 2)
		color.a8 = bmp_file.decode_u8(0x0036 + (i*4) + 3)
		
		if i >= Palettes.current_palette.colors.size():
			Palettes.current_palette.add_color(color)
		
		Palettes.current_palette.set_color(i, color)
		
	Palettes.save_palette()


func _on_pressed() -> void:
	#file_dialog.root_subfolder = main.api.project.current_project.export_directory_path
	
	file_dialog.show()
