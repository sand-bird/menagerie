extends Sprite2D

var anim_offset = Vector2(0, 0)

func _ready():
	texture_changed.connect(_offset_texture)
	centered = false

func _offset_texture():
#	if texture == null: return
	offset.y = anim_offset.y - texture.get_height()
	offset.x = anim_offset.x - ((texture.get_width() / hframes) / 2)
