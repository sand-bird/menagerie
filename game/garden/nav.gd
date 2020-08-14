extends Navigation2D

const WALKABLE = -1
const OBSTACLE = 0

# get back tile centerpoints instead of corners
#warning-ignore-all:unused_argument
func map_to_world(tile, ignore_half_ofs = false):
	return $tilemap.map_to_world(tile) + $tilemap.cell_size / 2

func world_to_map(pos):
	return $tilemap.world_to_map(pos)

func is_walkable_at_pos(pos):
	var coords = world_to_map(pos)
	return is_walkable_at(coords.x, coords.y)

func is_walkable_at(x, y):
	var tile_at = $tilemap.get_cell(x, y)
	var size = $tilemap.get_used_rect().size
	var in_bounds = (x >= 0 && y >= 0 and x <= size.x && y <= size.y)
	return tile_at == 0 and in_bounds

var path := []
var tpath := []
var walkable = []
var not_walkable = []

func calc_path(from_pos, to_pos):
	path = get_simple_path(from_pos, to_pos, true)
	Log.debug(self, ['path: ', path])
	tpath = [path.front()]
	for i in range(1, path.size() - 1):
		tpath.push_back(test_corner(path[i]))
	tpath.push_back(path.back())
	.update()
	return tpath

func _draw():
	var hsv = 0.0
	var hsv_step = 1.0 / max(tpath.size(), 1)
	for i in tpath:
		.draw_circle(i, 4, Color.from_hsv(hsv, 1, 0.9))
		hsv += hsv_step
	for i in path:
		.draw_circle(i, 2, Color(1, 1, 1))
	for i in walkable:
		.draw_circle(i, 2, Color(1, 1, 0))
	for i in not_walkable:
		.draw_circle(i, 2, Color(1, 0, 1))
	path = []
	tpath = []
	walkable = []
	not_walkable = []

const H = Vector2(8, 0)
const V = Vector2(0, 8)

func test_corner(p):
	for dir in [H + V, H - V, -H + V, -H - V]:
		if !is_walkable_at_pos(p + dir):
			not_walkable.push_back(p + dir)
			return p - dir
		else: walkable.push_back(p + dir)
	return p
