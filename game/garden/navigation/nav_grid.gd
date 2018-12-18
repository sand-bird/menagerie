extends Node

const NavNode = preload("res://garden/navigation/nav_node.gd")

var grid = []
var tilemap

# -----------------------------------------------------------

func _init(tilemap):
	self.tilemap = tilemap
	var size = tilemap.get_used_rect().size
	grid.resize(size.x)
	for x in range(size.x):
		grid[x] = []
		grid[x].resize(size.y)

# -----------------------------------------------------------

func node_at(pos):
	# return null if out of bounds
	if (pos.x < 0 or pos.y < 0 or pos.x >= grid.size() 
			or pos.y >= grid[pos.x].size()):
		return null
	
	# create nodes as necessary when coordinates are
	# accessed. we pass the node a reference to ourself
	# so that it can look up its neighbors.
	if !grid[pos.x][pos.y]:
		grid[pos.x][pos.y] = NavNode.new(pos, self)
	
	return grid[pos.x][pos.y]

# -----------------------------------------------------------

func is_walkable_at(pos):
	return tilemap.is_walkable_at(pos)
