extends TileMap

const WALKABLE = -1
const OBSTACLE = 0

const Nav = preload('res://garden/test.gd')
var nav # current navigation

# get back tile centerpoints instead of corners
#warning-ignore-all:unused_argument
func map_to_world(tile, ignore_half_ofs = false):
	return .map_to_world(tile) + cell_size / 2

#func world_to_map(pos):
#	return .world_to_map(pos - cell_size / 2)

func test(start, goal):
	var start_tile = world_to_map(start)
	var goal_tile = world_to_map(goal)
	if !is_walkable_at(goal_tile) or !is_walkable_at(start_tile):
		return
	if nav:
		nav.queue_free()
	nav = Nav.new(self, start_tile, goal_tile)
	add_child(nav)

func is_walkable_at(pos):
	var walkable = get_cellv(pos) == WALKABLE
	var size = get_used_rect().size
	var in_bounds = (pos.x >=0 && pos.y >= 0 and
			pos.x < size.x && pos.y < size.y)
	return walkable && in_bounds
