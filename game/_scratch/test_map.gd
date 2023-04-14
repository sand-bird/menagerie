extends TileMap

var last_cell = Vector2(0, 0)
var is_tiling = false
var curr_tile = 0

func _ready():
	set_process(true)
	pass

func _process(delta):
	var curr_cell = local_to_map(get_local_mouse_position())
	if curr_cell != last_cell:
		last_cell = curr_cell
		print("cell: ", curr_cell, " | tile: ", get_cellv(curr_cell))
		#" | coords: ", map_to_world(curr_cell), " | mouse: ", get_local_mouse_position())
#		if is_tiling and can_place():
#			set_cellv(curr_cell, curr_tile)
	if Input.is_mouse_button_pressed(1) and can_place():
		set_cellv(curr_cell, 0)
		#update_bitmask_area(curr_cell)
		update_bitmask_region()
	if Input.is_mouse_button_pressed(2):
		set_cellv(curr_cell, -1)
		update_bitmask_area(curr_cell)

func start_tiling(tile_id):
	curr_tile = tile_id
	set_cellv(last_cell, curr_tile)
	is_tiling = true

func stop_tiling():
	is_tiling = false

func can_place():
	return get_cellv(last_cell) != curr_tile