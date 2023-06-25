extends Sprite2D

func _ready():
	texture_changed.connect(_offset_texture)
	centered = false
	_offset_texture()

func _offset_texture():
#	if texture == null: return
	offset.y = -texture.get_height()
	offset.x = -((texture.get_width() / hframes) / 2)
