extends TextureRect

var dest_pos = Vector2(0, 0)

func move_to(pos):
	if !visible: position = pos  # if the selector is hidden, just jump it
	dest_pos = pos
	set_process(true)

func _process(_delta):
	var dest_vector = dest_pos - position
	position += dest_vector.limit_length(max(dest_vector.length() / 4.0, 2.0))
	if position == dest_pos: set_process(false)
