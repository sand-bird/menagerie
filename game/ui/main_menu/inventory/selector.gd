extends TextureRect

var dest_pos = Vector2(0, 0)
var count = 0

func _ready():
	pass

func move_to(pos):
	dest_pos = pos
	set_process(true)

func _process(delta):
	rect_position = rect_position.linear_interpolate(dest_pos, 0.3)
	if rect_position.distance_squared_to(dest_pos) < 25:
		rect_position = dest_pos
#		set_process(false)
