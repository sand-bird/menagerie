extends Sprite2D

var anim_offset = Vector2(0, 0):
	set(new_offset):
		var is_changed = anim_offset != new_offset
		anim_offset = new_offset
		if is_changed: _offset_texture()

func _ready():
	texture_changed.connect(_offset_texture)
	centered = false

func _offset_texture():
	if texture == null: return
	offset.y = anim_offset.y - texture.get_height()
	offset.x = anim_offset.x - round(
		( float(texture.get_width()) / float(hframes) )
		/ 2.0
	)
