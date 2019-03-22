extends Navigation2D

const WALKABLE = -1
const OBSTACLE = 0

# get back tile centerpoints instead of corners
#warning-ignore-all:unused_argument
func map_to_world(tile, ignore_half_ofs = false):
	return $tilemap.map_to_world(tile) + $tilemap.cell_size / 2

#func world_to_map(pos):
#	return .world_to_map(pos - cell_size / 2)

func is_walkable_at(pos):
	var walkable = $tilemap.get_cellv(pos) == WALKABLE
	var size = $tilemap.get_used_rect().size
	var in_bounds = (pos.x >=0 && pos.y >= 0 and
			pos.x < size.x && pos.y < size.y)
	return walkable and in_bounds

var path := []
var tpath := []

func calc_path(from_pos, to_pos):
	path = get_simple_path(from_pos, to_pos, true)
	print(path)
	tpath = [path.front()]
	for i in range(1, path.size() - 1):
		tpath.push_back(test_corner(path[i]))
	tpath.push_back(path.back())
	.update()

func _draw():
	for i in path:
		.draw_circle(i, 3, Color(0, 0, 0))
	for i in tpath:
		.draw_circle(i, 3, Color(1, 0, 1))

const H = Vector2(8, 0)
const V = Vector2(0, 8)

func test_corner(p):
	for dir in [H + V, H - V, -H + V, -H - V]:
		if !is_walkable_at($tilemap.world_to_map(p + dir)):
			return p - dir
	return p