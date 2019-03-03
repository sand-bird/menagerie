extends TileMap

const WALKABLE = -1
const OBSTACLE = 0


# get back tile centerpoints instead of corners
#warning-ignore-all:unused_argument
func map_to_world(tile, ignore_half_ofs = false):
	return .map_to_world(tile) + cell_size / 2

#func world_to_map(pos):
#	return .world_to_map(pos - cell_size / 2)

func is_walkable_at(pos):
	var walkable = get_cellv(pos) == WALKABLE
	var size = get_used_rect().size
	var in_bounds = (pos.x >=0 && pos.y >= 0 and
			pos.x < size.x && pos.y < size.y)
	return walkable and in_bounds
