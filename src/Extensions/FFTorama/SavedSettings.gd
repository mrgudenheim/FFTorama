extends Resource

@export var project_name: String = "project_name"

@export var weapon_frame: int = 0
@export var weapon_layer: int = 0
@export var weapon_type: int = 1
@export var effect_frame: int = 0
@export var effect_layer: int = 0
@export var effect_type: int = 1
@export var item_frame: int = 0
@export var item_layer: int = 0
@export var other_frame: int = 0
@export var other_layer: int = 0
@export var other_type_index: int = 0

@export var use_separate_sp2: bool = false
@export var use_frame_id_for_sp2_offset: bool = false
@export var use_hardcoded_offsets: bool = false

@export var select_frame: bool = true
@export var use_current_cel: bool = true

@export var global_spritesheet_type: String = "type1"
@export var global_frame_id: int = 0

@export var global_animation_type: String = "type1"
@export var animation_is_playing: bool = true
@export var animation_speed: float = 60 # frames per sec
@export var opcode_frame_offset: int = 0
@export var weapon_sheathe_check1_delay: int = 0
@export var weapon_sheathe_check2_delay: int = 10
@export var wait_for_input_delay: int = 10
@export var item_index: int = 0
@export var weapon_v_offset: int = 0 # v_offset to lookup for weapon frames
@export var global_weapon_frame_offset_index: int = 0 # index to lookup frame offset for wep and eff animations
@export var global_animation_id: int = 0

@export var background_color: Color = Color.BLACK

# CelSelector vars
@export var display_cel_selector_frame:int = 0
@export var display_cel_selector_layer:int = 0

@export var sp2_cel_selector_frame:int = 0
@export var sp2_cel_selector_layer:int = 0