extends Node

var pos
var neighbors = [] setget , _get_neighbors
var parent
var g # distance from start to node
var f # heuristic value (manhattan = distance to goal)
var opened = false
var closed = false
var grid # reference to our NavGrid object

# -----------------------------------------------------------

func _init(pos, grid):
	self.grid = grid
	self.pos = pos

# -----------------------------------------------------------

func _get_neighbors():
	if !neighbors:
		generate_neighbors()
	return neighbors

# -----------------------------------------------------------

func direction_to(node):
	return node.pos - pos

# -----------------------------------------------------------

func distance_to(node):
	return pos.distance_squared_to(node.pos)

# -----------------------------------------------------------

func add_neighbor(pos):
	var node = grid.node_at(pos)
	if node:
		neighbors.push_back(node)

# -----------------------------------------------------------

const H = Vector2(1, 0)
const V = Vector2(0, 1)

func generate_neighbors():
	for dir in [H, -H, V, -V]:
		if grid.is_walkable_at(pos + dir):
			add_neighbor(pos + dir)
	for h in [H, -H]:
		var h_walkable = grid.is_walkable_at(pos + h)
		for v in [V, -V]:
			if (h_walkable and grid.is_walkable_at(pos + v)
					and grid.is_walkable_at(pos + h + v)):
				add_neighbor(pos + h + v)

# -----------------------------------------------------------

func step(dir):
	return grid.node_at(pos + dir)

# -----------------------------------------------------------

# a node n in neighbors(x) is forced if:
# 1. n is not a natural neighbor of x (would have been
#    pruned? or has an obstacle? idfk)
# 2. dist_with_x < dist_without_x
func is_forced():
	return true

# -----------------------------------------------------------

func print():
	return str("pos: ", pos, " | opened: ", opened, " | closed: ", closed,
			" | parent: ", parent.pos if parent else "(none)")
