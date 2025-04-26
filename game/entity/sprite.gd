extends Sprite2D

@onready var parent_radius: int = get_parent().get_parent().data.size

var aux_offset = Vector2(0, 0)

## set the offset based on the texture size so that the sprite is hoizontally
## centered and vertically bottom-aligned with the entity's collision shape.
func offset_texture():
	offset.y = aux_offset.y - texture.get_height() + parent_radius
	offset.x = aux_offset.x - round(
		( float(texture.get_width()) / float(hframes) )
		/ 2.0
	)

func _ready(): centered = false

func update_texture(anim_info: Dictionary):
	# set the hframes value of our sprite.
	hframes = anim_info.frames
	# set whether our sprite is h-flipped.  this can either be set on the data
	# definition itself, or in `get_anim_info_for_facing` if the data definition
	# doesn't specify the necessary horizontal facing.
	flip_h = anim_info.get('flip', false)
	# set the aux offset.  this modifies the offset we will apply below.
	var new_offset = U.parse_vec(anim_info.get('offset'), Vector2(0, 0))
	if flip_h: new_offset.x = -new_offset.x
	aux_offset = new_offset
	# set our texture to the spritesheet specified in the data.
	texture = ResourceLoader.load(anim_info.spritesheet)
	offset_texture()
