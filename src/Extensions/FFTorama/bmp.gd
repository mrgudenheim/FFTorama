class_name Bmp

var bits_per_pixel:int
var pixel_data_start:int
var width: int
var height: int
var num_pixels:int = width*height
var palette_data_start := 0x0036
var num_colors:int
var compression:int

var color_palette: Array[Color] = []
var color_indices: Array[int] = []
var pixel_colors: Array[Color] = []

func bmp(bmp_file:PackedByteArray):
	pixel_data_start = bmp_file.decode_u32(0x000A)
	width = bmp_file.decode_u32(0x0012)
	height = bmp_file.decode_u32(0x0016)
	bits_per_pixel = bmp_file.decode_u16(0x001C)
	compression = bmp_file.decode_u16(0x001E)
	num_colors = (pixel_data_start - palette_data_start)/4
	
	# store palette_colors
	if bits_per_pixel > 8:
		print_debug("Bit depth > 8, no palette to extract") # a compressed 16bpp format can use a palette, but is not covered by this utility
	else:
		for i in num_colors:
			var color:Color = Color.BLACK
			color.b8 = bmp_file.decode_u8(palette_data_start + (i*4)) # blue
			color.g8 = bmp_file.decode_u8(palette_data_start + (i*4) + 1) # green
			color.r8 = bmp_file.decode_u8(palette_data_start + (i*4) + 2) # red
			color.a8 = bmp_file.decode_u8(palette_data_start + (i*4) + 3) # alpha?
			
			color_palette[i] = color
	
	# store color_indices
	if bits_per_pixel > 8:
		print_debug("Bit depth > 8, colors are not indexed") # a compressed 16bpp format can use indexed colors, but is not covered by this utility
	else:
		color_indices.resize(num_pixels)
		for i in num_pixels:
			var pixel_offset:int = (i * bits_per_pixel)/8
			var byte = bmp_file.decode_u8(pixel_data_start + pixel_offset)
			
			if bits_per_pixel == 1:
				color_indices[i] = byte & (2**(i % 8))
			elif bits_per_pixel == 4:
				if i % 2 == 0: # get 4 leftmost bits
					color_indices[i] = byte >> 4
				else:
					color_indices[i] = byte & 0b00001111 # get 4 rightmost bits
			elif bits_per_pixel == 8:
				color_indices[i] = byte
	
	# store color_indices
	pixel_colors.resize(num_pixels)
	if bits_per_pixel <= 8:
		for i in color_indices.size():
			pixel_colors[i] = color_palette[color_indices[i]]
	elif bits_per_pixel == 16 and compression == 0: # compression is not handled by this utility
		for i in num_pixels:
			var pixel_offset = i * 2
			var word = bmp_file.decode_u16(pixel_data_start + pixel_offset)
			var color:Color = Color.BLACK
			
			color.b8 = word & 0b0000000000011111 # blue is least significant 5 bits
			color.g8 = word & 0b0000001111100000 >> 5 # green is next least significant 5 bits
			color.r8 = word & 0b0111110000000000 >> 10 # red is next least significant 5 bits
			pixel_colors[i] = color
	elif bits_per_pixel == 24 and compression == 0: # compression is not handled by this utility
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


func get_color_index(x:int, y:int) -> int:
	if bits_per_pixel > 8:
		print_debug("Bit depth > 8, colors are not indexed") # a compressed 16bpp format can use indexed colors, but is not covered by this utility
		return -1
	
	return color_indices[x + ((height - y - 1) * width)]


func get_color(x:int, y:int) -> Color:
	return pixel_colors[x + ((height - y - 1) * width)]


func get_rgba8_image() -> Image:	
	var image:Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	
	for x in width:
		for y in height:
			image.set_pixel(x,height - y - 1, pixel_colors[x + (y * width)])
	return image


static func create_paletted_bmp(image:Image, palette:Array[Color], bits_per_pixel = 8) -> PackedByteArray:
	var bmp_file:PackedByteArray = []
	if not (bits_per_pixel == 1 or bits_per_pixel == 4 or bits_per_pixel == 8 or bits_per_pixel == 16 or bits_per_pixel == 24):
		print_debug("not valid bits_per_pixel: " + str(bits_per_pixel))
		return bmp_file
	
	image.convert(Image.FORMAT_RGBA8)
		
	var pixel_count: int = image.get_height() * image.get_width()
	var palette_num_colors:int = 0
	if bits_per_pixel <= 8:
		palette_num_colors = mini(2**bits_per_pixel, palette.size())
	
	var header_size: int = 54
	var palette_data_size: int = palette_num_colors * 4
	var pixel_data_start: int = header_size + palette_data_size
	var file_size: int = header_size + palette_data_size + (pixel_count * (bits_per_pixel/8.0))
	bmp_file.resize(file_size)
	bmp_file.fill(0)
	
	# BMP format
	# Header
	bmp_file.encode_u16(0x0000, 0x4D42) # signature (2 bytes) - BM
	bmp_file.encode_u32(0x0002, file_size) # FileSize (4 bytes) 0x0002
	#bmp_file.encode_u32(0x000A, 0x0) # reserved (4 bytes) 0x0006 - always zero?
	bmp_file.encode_u32(0x000A, pixel_data_start) # DataOffset (4 bytes) 0x000A - 0x76 for 4bpp with 16 colors, 0x436 for 8bpp with 256 colors

	# InfoHeader
	bmp_file.encode_u32(0x000E, 0x28) # Info Header Size (4 bytes) 0x000E
	bmp_file.encode_u32(0x0012, image.get_size().x) # Width (4 bytes) 0x0012
	bmp_file.encode_u32(0x0016, image.get_size().y) # Height (4 bytes) 0x0016
	bmp_file.encode_u16(0x001A, 0x01) # Planes (2 bytes) 0x001A
	bmp_file.encode_u16(0x001C, bits_per_pixel) # Bits per Pixel (2 bytes) 0x001C - 0x04 for 4bpp, 0x08 for 8bpp
	#bmp_file.encode_u32(0x001E, 0) # Compression (4 bytes) 0x001E - 0 for none
	#bmp_file.encode_u32(0x0022, 0) # ImageSize (4 bytes) 0x0022 - 0 if no compression
	bmp_file.encode_u32(0x0026, 0x0EC4) # XpixelsPerMeter (4 bytes) 0x0026
	bmp_file.encode_u32(0x002A, 0x0EC4) # YpixelsPerMeter (4 bytes) 0x002A
	bmp_file.encode_u32(0x002E, palette_num_colors) # Colors Used (4 bytes) 0x002E
	bmp_file.encode_u32(0x0032, palette_num_colors) # Important Colors (4 bytes) 0x0032

	# Color Table 0x0036 - either 16 (4bpp) colors long or 256 (8 bpp) colors long	
	var color_index: Dictionary = {} # Dictionary[string, int] to determine index based on pixel color
	for i in palette_num_colors:
		var palette_color_string: String = str(palette[i]) # use string to allow for correct dictionary lookup
		if color_index.has(palette_color_string): # keep lowest index for color
			if i < color_index[palette_color_string]:
				color_index[palette_color_string] = i
		else:
			color_index[palette_color_string] = i
		
		bmp_file.encode_u8(0x0036 + (i*4), palette[i].b8) # blue
		bmp_file.encode_u8(0x0036 + (i*4) + 1, palette[i].g8) # green
		bmp_file.encode_u8(0x0036 + (i*4) + 2, palette[i].r8) # red
		bmp_file.encode_u8(0x0036 + (i*4) + 3, palette[i].a8) # alpha
	
	# Pixel Data - left to right, bottom to top	
	var index: int = 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel_index: int = x + (image.get_width() * y)
			var color:Color = image.get_pixel(x, image.get_height() - y - 1)
			var color_string:String = str(color)
			
			if color_index.has(color_string):
				index = color_index[color_string]
			else:
				print_debug("color not in palette: " + color_string)
				index = 0
				
			if bits_per_pixel <= 8:
				var index_shifted = index << (8-bits_per_pixel) - (bits_per_pixel * (pixel_index % (8/bits_per_pixel))) # shift to position
				index_shifted = index_shifted | bmp_file.decode_u8(pixel_data_start + floor(pixel_index/(8/bits_per_pixel))) # keep all bits
				bmp_file.encode_u8(pixel_data_start + floor(pixel_index/(8/bits_per_pixel)), index_shifted)
			elif bits_per_pixel == 16:
				var word = bmp_file.decode_u16(pixel_data_start + (pixel_index * 2))
				word = word | color.b8 # blue is least significant 5 bits
				word = word | (color.g8 << 5) # green is next least significant 5 bits
				word = word | (color.r8 << 10) # red is next least significant 5 bits
				bmp_file.encode_u16(pixel_data_start + (pixel_index * 2), word)
			elif bits_per_pixel == 24:
				bmp_file.encode_u8(pixel_data_start + (pixel_index * 3), color.b8) # blue
				bmp_file.encode_u8(pixel_data_start + (pixel_index * 3) + 1, color.g8) # green
				bmp_file.encode_u8(pixel_data_start + (pixel_index * 3) + 2, color.r8) # red
			
			#if bits_per_pixel == 8:
				#bmp_file.encode_u8(pixel_data_start + pixel_index, index)
			#elif bits_per_pixel == 4:
				#var index_4bits: int = index # right half of byte
				#if pixel_index % 2 == 0:
					#index_4bits = index_4bits << 4 # left half of byte
				#
				#index_4bits = index_4bits | bmp_file.decode_u8(pixel_data_start + floor(pixel_index/2)) # keep both left and right half of byte
				#bmp_file.encode_u8(pixel_data_start + floor(pixel_index/2), index_4bits)
			#elif bits_per_pixel == 1:
				#var index_1bits: int = index
				#index_1bits = index_1bits << (7 - (pixel_index % 8)) # shift to position
				#
				#index_1bits = index_1bits | bmp_file.decode_u8(pixel_data_start + floor(pixel_index/8)) # keep all the bits
				#bmp_file.encode_u8(pixel_data_start + floor(pixel_index/8), index_1bits)
	
	return bmp_file
