@tool
extends NinePatchRect

@export var mask_margin: Vector2i:
	set(new):
		mask_margin = new
		update_mask_position()

@export var mask_padding: int:
	set(new):
		mask_padding = new
		update_mask_position()

@export var bg_margin: int:
	set(new):
		bg_margin = new
		update_bg_margin()

@export var border_radius: int:
	set(new):
		border_radius = new
		update_border_radius()

# --------------------------------------------------------------------------- #

func _ready():
	update_mask_position()
	update_bg_margin()
	update_border_radius()
	$mask/sprite.texture_changed.connect(position_sprite)

# --------------------------------------------------------------------------- #

# only used in the select hud for now. probably temporary
const FEMALE_BG = Color("f86790")
const MALE_BG = Color("40c8f8")
const NONE_BG = Color("e9b5a3")
const BG_COLORS = [FEMALE_BG, MALE_BG]

# note: this duplicates a lot of the logic in `entity/sprite`.
# ideally we should have generic EntitySprite class that can parse sprite_info
# and animate itself accordingly, and use it both here and in Entity.
func update(e: Entity, idle = false):
	var sprite_info = e.get_sprite_info('idle' if idle else null, Vector2(1, 1))
	var panel_theme = $bg.get_theme_stylebox("panel")
	panel_theme.bg_color = BG_COLORS[e.sex] if 'sex' in e else NONE_BG
	var sprite: Sprite2D = $mask/sprite
	sprite.hframes = sprite_info.get('frames', 1)
	sprite.flip_h = sprite_info.get('flip', false)
	var offset = U.parse_vec(sprite_info.get('offset'), Vector2(0, 0))
	if sprite.flip_h: offset.x = -offset.x
	sprite.offset = offset
	sprite.texture = ResourceLoader.load(sprite_info.spritesheet)
	sprite.frame = min(e.sprite.frame, (sprite.hframes * sprite.vframes) - 1)

# --------------------------------------------------------------------------- #

func update_mask_position():
	if !has_node('mask'): return
	$mask.offset_bottom = -mask_margin.y
	$mask.offset_left = mask_margin.x
	$mask.offset_right = -mask_margin.x
	$mask.offset_top = mask_margin.y - mask_padding
	position_sprite()

# --------------------------------------------------------------------------- #

func update_border_radius():
	if !has_node('bg') or !has_node('mask'): return
	
	for panel in [$bg, $mask]:
		var panel_theme: StyleBoxFlat = panel.get_theme_stylebox("panel")
		panel_theme.set_corner_radius_all(border_radius)
	
	var mask_panel_theme: StyleBoxFlat = $mask.get_theme_stylebox("panel")
	mask_panel_theme.corner_radius_top_left = 0
	mask_panel_theme.corner_radius_top_right = 0

# --------------------------------------------------------------------------- #

# note: sprite positioning depends on this rect, but only for centering, and
# since bg is always centered in the parent it's not necessary to reposition the
# sprite when this changes.
func update_bg_margin():
	if !has_node('bg'): return
	$bg.set_offsets_preset(
			Control.PRESET_FULL_RECT,
			Control.PRESET_MODE_MINSIZE,
			bg_margin
		)

# --------------------------------------------------------------------------- #
# vertical alignment of the sprite relative to the container.
# 0 is top, 1 is bottom, 0.5 is center.
const VALIGN = 0.7

# update the sprite's position.  called when a container size changes or when
# the sprite's texture is updated.
func position_sprite():
	var sprite: Sprite2D = $mask/sprite
	sprite.centered = false
	var mask_size = $mask.size
	var bg_size = $bg.size
	var sprite_size = sprite.get_rect().size
	
	# right-align if the sprite is bigger than the container, else center it.
	sprite.position.x = min(
		mask_size.x - sprite_size.x, # used when sprite_size > mask_size
		ceil((mask_size.x - sprite_size.x) * 0.5) # used when sprite_size < mask_size
	) # when sprite_size == mask_size, this is 0
	
	# offset may interfere with right/top alignment on large sprites, so nix it
	for i in ['x', 'y']:
		if sprite_size[i] + sprite.offset[i] > mask_size[i]: sprite.offset[i] = 0
	
	# try to v-center the sprite on the $bg panel.
	# max(0) means its position will never overflow the top of $mask; if it's
	# taller than the mask, it will be top-aligned.
	sprite.position.y = max(0,
		(bg_size.y - sprite_size.y) * VALIGN
		+ $bg.offset_top - $mask.offset_top
	)
