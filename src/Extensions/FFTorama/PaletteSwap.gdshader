/* https://github.com/KoBeWi/Godot-Palette-Swap-Shader/tree/master
MIT License

Copyright (c) 2020 KoBeWi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE
*/
shader_type canvas_item;

uniform sampler2D palette : filter_nearest, repeat_disable, source_color;
uniform bool skip_first_row = false;
uniform bool use_palette_alpha = true;
uniform float fps = 6;
uniform int palette_offset : hint_range(0, 15) = 0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	ivec3 colori = ivec3(round(original_color.rgb * 255.0));
	
	ivec2 color_count = textureSize(palette, 0);
	
	float idx = -1.0;
	for (int i = 0; i < color_count.x; i++) {
		vec3 color2 = texture(palette, vec2(float(i) / float(color_count.x - 1), 0)).rgb;
		ivec3 colori2 = ivec3(round(color2 * 255.0));
		
		if (colori == colori2) {
			idx = float(i);
			break;
		}
	}
	
	if (idx >= 0.0) {
		vec2 uv;
		uv.x = idx / float(color_count.x - 1);
		uv.y = float(palette_offset) / float(color_count.y);
		//uv.y = (mod(TIME * fps, max(float(color_count.y - 1 - int(skip_first_row)), 1.0)) + float(skip_first_row))  / float(color_count.y - 1);
		
		vec4 palette_color = texture(palette, uv);
		COLOR = vec4(palette_color.rgb, mix(original_color.a, palette_color.a, float(use_palette_alpha)));
	} else {
		COLOR = original_color;
		//COLOR = vec4(1, 0, 0, 1);
	}
}
