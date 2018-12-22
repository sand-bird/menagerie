extends Node

var pos
var neighbors = [] setget , _get_neighbors
var bad_neighbors = []
var parent
var g # distance from start to node
var f # heuristic value (manhattan = distance to goal)
var opened = false
var closed = false
var grid # reference to our NavGrid object
var walkable = false

# -----------------------------------------------------------

func _init(pos, grid, walkable = false):
	self.grid = grid
	self.pos = pos
	self.walkable = walkable

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
	# return pos.distance_squared_to(node.pos)
	var dist_vec = (node.pos - pos).abs()
	var straight_dist_to = abs(dist_vec.y - dist_vec.x)
	var diag_dist_to = max(dist_vec.y, dist_vec.x) - straight_dist_to
	return straight_dist_to + diag_dist_to * sqrt(2)


# -----------------------------------------------------------

func add_neighbor(pos):
	var node = grid.node_at(pos)
	if node:
		neighbors.push_back(node)

#func add_neighbor_2(pos):
#	var node = grid.node_at(pos)
#	if node and node.walkable:
#		neighbors.push_back(node)

# -----------------------------------------------------------

const H = Vector2(1, 0)
const V = Vector2(0, 1)

func generate_neighbors(include_nonwalkable = false):
	for dir in [H, -H, V, -V]:
		if include_nonwalkable or grid.is_walkable_at(pos + dir):
			add_neighbor(pos + dir)
	for h in [H, -H]:
		var h_walkable = grid.is_walkable_at(pos + h)
		for v in [V, -V]:
			if include_nonwalkable or (h_walkable and grid.is_walkable_at(pos + v)
					and grid.is_walkable_at(pos + h + v)):
				add_neighbor(pos + h + v)


#func generate_neighbors_2():
#	for dir in [H, -H, V, -V]:
#		add_neighbor_2(pos + dir)
#	for h in [H, -H]:
#		for v in [V, -V]:
#			add_neighbor_2(pos + h + v)

# -----------------------------------------------------------

func prune():
	# we need x's parent to tell which direction to prune by,
	# so if x is the start node (no parent), we can't prune
	if !parent:
		return self.neighbors
	
	var pruned_neighbors = []
	bad_neighbors = []
	
	for n in self.neighbors:
		var dist_without_x = n.distance_to(parent)
		var dist_with_x = distance_to(n) + distance_to(parent)
		
		var d = parent.direction_to(self)
		
		if d.x and d.y: # diagonal (neither axis is 0)
			if dist_with_x <= dist_without_x:
				pruned_neighbors.push_back(n)
		
		elif dist_with_x <= dist_without_x:
			pruned_neighbors.push_back(n)
		
		elif n.is_forced(d):
			pruned_neighbors.push_back(n)
		
		else:
			bad_neighbors.push_back(n)
	
	return pruned_neighbors

# -----------------------------------------------------------

func step(dir):
	return grid.node_at(pos + dir)

# -----------------------------------------------------------

# a node n in neighbors(x) is forced if:
# 1. n is not a natural neighbor of x (would have been
#    pruned? or has an obstacle? idfk)
# 2. dist_with_x < dist_without_x
# nodes are forced if they exist on a turning point. that
# means that in the direction we're coming from, there is a
# nonwalkable tile diagonally above or below, with walkable
# tiles next to it.
func is_forced(d):
	if Utils.is_diagonal(d):
		return check_diag_corner(d)
	elif Utils.is_horizontal(d):
		return check_straight_corner(d, V)
	elif Utils.is_vertical(d):
		return check_straight_corner(d, H)

# -----------------------------------------------------------

func check_straight_corner(from_dir, ortho_dir):
	for dir in [ortho_dir, -ortho_dir]:
		var corner_dir = dir - from_dir
		var is_walkable_at_corner = grid.is_walkable_at(pos + corner_dir)
		var check_walkable = corner_dir * ortho_dir
		var is_walkable_ortho = grid.is_walkable_at(pos + check_walkable)
		if (!is_walkable_at_corner and is_walkable_ortho):
			return true
	return false

# -----------------------------------------------------------

func check_diag_corner(from_dir):
	for cross_diag in [Vector2(1, -1), Vector2(-1, 1)]:
		var corner_dir = from_dir * cross_diag
		if (!grid.is_walkable_at(corner_dir) and
				grid.is_walkable_at((corner_dir + from_dir) / 2)):
			return true
	return false

# -----------------------------------------------------------

func print():
	return str("pos: ", pos, " | opened: ", opened, " | closed: ", closed,
			" | parent: ", parent.pos if parent else "(none)")
