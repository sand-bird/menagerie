extends TextureRect

var dest_pos = Vector2(0, 0)
var count = 0

func _ready():
	pass

func move_to(pos):
	dest_pos = pos
	set_process(true)

func _process(delta):
	var dest_vector = dest_pos - rect_position
	rect_position += dest_vector.clamped(max(dest_vector.length() / 4.0, 2.0))
#	rect_position += rect_position.linear_interpolate(dest_pos, 0.5)
#	if rect_position.distance_squared_to(dest_pos) < 25:
#		rect_position = dest_pos
#		set_process(false)
