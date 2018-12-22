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

func get_node(pos):
	return grid[pos.x][pos.y]

# -----------------------------------------------------------

func set_node(pos, node):
	grid[pos.x][pos.y] = node

# -----------------------------------------------------------

func node_at(pos):
	# return null if out of bounds
	if (pos.x < 0 or pos.y < 0 or pos.x >= grid.size() 
			or pos.y >= grid[pos.x].size()):
		return null
	
	# create nodes as necessary when coordinates are
	# accessed. we pass the node a reference to ourself
	# so that it can look up its neighbors.
	if !get_node(pos):
		set_node(pos, NavNode.new(pos, self, tilemap.is_walkable_at(pos)))
	
	return get_node(pos)

# -----------------------------------------------------------

func is_walkable_at(pos):
	var node = node_at(pos)
	if node:
		return node.walkable
	else:
		return false
