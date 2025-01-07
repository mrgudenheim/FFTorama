class_name FftAnimation

var seq := Seq.new()
var shp := Shp.new()

var sequence := Sequence.new()
var weapon_frame_offset_index: int = 0
var cel: PixelCel # cel to get image from
var parent_anim: FftAnimation = null: # used for nested loops in animations
	get:
		if parent_anim != null:
			return parent_anim.parent_anim
		else:
			return self
	set(value):
		parent_anim = value
var is_primary_anim: bool = true # false if this animation created through an opcode of another animation, such as QueueSpriteAnim
var primary_anim_opcode_part_id: int = 0 # used for nested loops in animations
var flipped_h: bool = false # mirrors the animation. Set to true to create right-facing animations
var submerged_depth: int = 0

func get_duplicate() -> FftAnimation:
	var new_fft_animation = FftAnimation.new()
	new_fft_animation.seq = seq
	new_fft_animation.shp = shp
	new_fft_animation.sequence = sequence
	new_fft_animation.weapon_frame_offset_index = weapon_frame_offset_index
	new_fft_animation.cel = cel
	new_fft_animation.is_primary_anim = is_primary_anim
	new_fft_animation.primary_anim_opcode_part_id = primary_anim_opcode_part_id
	new_fft_animation.flipped_h = flipped_h
	new_fft_animation.submerged_depth = submerged_depth
	
	return new_fft_animation
