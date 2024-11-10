extends Node

class_name Bmp_utility


static func get_palette(bmp_file:PackedByteArray) -> Array[Color]:
	var color_palette:Array[Color] = []
	
	var bits_per_pixel:int = get_bit_depth(bmp_file)
	if bits_per_pixel > 8:
		print_debug("Bit depth > 8, no palette to extract") # a compressed 16bpp format can use a palette, but is not covered by this utility
		return color_palette
	
	var palette_data_offset = 0x0036
	var num_colors := get_num_colors(bmp_file)
	
	for i in num_colors:
		var color:Color = Color.BLACK
		color.b8 = bmp_file.decode_u8(palette_data_offset + (i*4)) # blue
		color.g8 = bmp_file.decode_u8(palette_data_offset + (i*4) + 1) # green
		color.r8 = bmp_file.decode_u8(palette_data_offset + (i*4) + 2) # red
		color.a8 = bmp_file.decode_u8(palette_data_offset + (i*4) + 3) # alpha?
		
		color_palette[i] = color
	
	return color_palette


static func get_bit_depth(bmp_file:PackedByteArray) -> int:
	return bmp_file.decode_u16(0x001C)


static func get_num_colors(bmp_file:PackedByteArray) -> int:
	var palette_data_start := 0x0036
	var palette_data_end := bmp_file.decode_u32(0x000A)
	
	return (palette_data_end - palette_data_start)/4


static func get_color_indices(bmp_file:PackedByteArray) -> Array[int]:
	var color_indices:Array[int] = []
	
	var pixel_data_start:int = bmp_file.decode_u32(0x000A)
	var width: int = bmp_file.decode_u32(0x0012)
	var height: int = bmp_file.decode_u32(0x0016)
	var num_pixels:int = width*height
	var bit_depth:int = get_bit_depth(bmp_file)
	
	if bit_depth > 8:
		print_debug("Bit depth > 8, colors are not indexed") # a compressed 16bpp format can use indexed colors, but is not covered by this utility
		return color_indices
	
	for i in num_pixels:
		var pixel_offset = (i * bit_depth)/8
		var byte = bmp_file.decode_u8(pixel_data_start + pixel_offset)
		
		if bit_depth == 1:
			color_indices[i] = byte & (2**(i % 8))
		elif bit_depth == 4:
			if i % 2 == 0: # get 4 leftmost bits
				color_indices[i] = byte >> 4
			else:
				color_indices[i] = byte & 0b00001111 # get 4 rightmost bits
		elif bit_depth == 8:
			color_indices[i] = byte
	
	return color_indices


static func get_pixel_colors(bmp_file:PackedByteArray) -> Array[Color]:
	var pixel_colors:Array[Color] = []
	var bit_depth:int = get_bit_depth(bmp_file)
	
	var width: int = bmp_file.decode_u32(0x0012)
	var height: int = bmp_file.decode_u32(0x0016)
	var num_pixels:int = width*height
	var compression:int = bmp_file.decode_u32(0x001E)
	var pixel_data_start:int = bmp_file.decode_u32(0x000A)
	
	if bit_depth <= 8:
		var palette = get_palette(bmp_file)
		var color_indicies = get_color_indices(bmp_file)
		
		for i in color_indicies.size():
			pixel_colors[i] = palette[color_indicies[i]]
		return pixel_colors
	elif bit_depth == 16 and compression == 0: # compression is not handled by this utility
		for i in num_pixels:
			var pixel_offset = i * 2
			var word = bmp_file.decode_u16(pixel_data_start + pixel_offset)
			var color:Color = Color.BLACK
			
			color.b8 = word & 0b0000000000011111 # blue is least significant 5 bits
			color.g8 = word & 0b0000001111100000 >> 5 # green is next least significant 5 bits
			color.r8 = word & 0b0111110000000000 >> 10 # red is next least significant 5 bits
			pixel_colors[i] = color
	elif bit_depth == 24 and compression == 0: # compression is not handled by this utility
		for i in num_pixels:
			var pixel_offset = i * 3
			var word = bmp_file.decode_u16(pixel_data_start + pixel_offset)
			var color:Color = Color.BLACK
			
			color.b8 = word & bmp_file.decode_u8(pixel_data_start + pixel_offset) # blue
			color.g8 = word & bmp_file.decode_u8(pixel_data_start + pixel_offset + 1) # green
			color.r8 = word & bmp_file.decode_u8(pixel_data_start + pixel_offset + 2) # red
			pixel_colors[i] = color
	else:
		print_debug("Bit depth != 1, 4, 8, 16, or 24")
	
	return pixel_colors


static func get_color_index(x:int, y:int, bmp_file:PackedByteArray) -> int:
	var bit_depth:int = get_bit_depth(bmp_file)
	if bit_depth > 8:
		print_debug("Bit depth > 8, colors are not indexed") # a compressed 16bpp format can use indexed colors, but is not covered by this utility
		return -1
	
	var color_indicies = get_color_indices(bmp_file)
	var width: int = bmp_file.decode_u32(0x0012)
	var height: int = bmp_file.decode_u32(0x0016)
	
	return color_indicies[x + ((height - y - 1) * width)]


static func get_color(x:int, y:int, bmp_file:PackedByteArray) -> Color:
	var pixel_colors = get_pixel_colors(bmp_file)
	var width: int = bmp_file.decode_u32(0x0012)
	var height: int = bmp_file.decode_u32(0x0016)
	
	return pixel_colors[x + ((height - y - 1) * width)]

static func get_rgba8_image(bmp_file:PackedByteArray) -> Image:
	var width: int = bmp_file.decode_u32(0x0012)
	var height: int = bmp_file.decode_u32(0x0016)
	
	var image:Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	
	var pixel_colors = get_pixel_colors(bmp_file)
	for x in width:
		for y in height:
			image.set_pixel(x,height - y - 1, pixel_colors[x + (y * width)])
	return image
	
