extends TileMap

# start and end in tile coordinates
var start_tile
var end_tile

# start and end in world coordinates
var start_pos
var end_pos

var path = [] # for printing
var neighbors = []

const WALKABLE = -1
const OBSTACLE = 0
const H = Vector2(1, 0)
const V = Vector2(0, 1)

#var grid = []

func _ready():
	pass

# in the future we want to initialize our walkable/obstacle
# grid based on the GardenObjects passed in by garden. for
# now, we initialize it based on our drawn tilemap. this
# works the same way as garden's serialize_terrain() method.
func initialize(objects = null): 
	return
	var size = get_used_rect().size
	grid.resize(size.y)
	for y in range(size.y):
		grid[y] = []
		grid[y].resize(size.x)
		for x in range(size.x):
			grid[y][x] = NavNode.new(Vector2(x, y), get_cell(x, y) == WALKABLE)
#	print(grid)

func test(start, end):
	start_pos = start
	end_pos = end
	start_tile = world_to_map(start)
	end_tile = world_to_map(end)
	print("start pos: ", start_pos, " | end pos: ", end_pos, 
			" | start tile: ", start_tile, " | end tile: ", end_tile, 
			" | start id: ", get_cellv(start_tile), " | end id: ", get_cellv(end_tile),
			" | walkable?: ", is_walkable_at(end_tile))
	#get_neighbors(end_tile)
	a_star(start_tile, end_tile)
	update()

#func get_neighbors(pos):
#	var grid = NavGrid.new(self)
#	var node = grid.node_at(pos)
#	neighbors = node.neighbors

func _draw():
#	if start_pos:
#		draw_circle(start_pos, 4, Color(0, 0.5, 1))
#	if end_pos:
#		draw_circle(end_pos, 4, Color(1, 0, 0.5))
#	if start_tile:
#		draw_circle(map_to_world(start_tile), 4, Color(0, 1, 1))
#	if end_tile:
#		draw_circle(map_to_world(end_tile), 4, Color(1, 0, 1))
	if open_list and !open_list.empty():
		for i in open_list.list:
			draw_circle(map_to_world(i.pos), 8, Color(0.5, 1, 0.5))
	for i in closed_list:
		draw_circle(map_to_world(i), 8, Color(1, 0.5, 0.5))
	for i in neighbors:
		draw_circle(map_to_world(i.pos), 5, Color(0, 1, 1))
	for i in path:
		draw_circle(map_to_world(i), 4, Color(1, 1, 0))
	if node:
		draw_circle(map_to_world(node.pos), 5, Color(0, 0, 1))


# get back tile centerpoints instead of corners
func map_to_world(tile):
	return .map_to_world(tile) + cell_size / 2

var timer = 0

func _process(delta):
	timer += delta
	if timer < 1:
		return
	timer -= 1
	if open_list and !open_list.empty():
		process_node()
		update()

var node
var closed_list = []

# -----------------------------------------------------------

class NavNode:
	var pos
	var neighbors = [] setget , _get_neighbors
	var parent
	var g # distance from start to node
	var f # heuristic value (manhattan = distance to goal)
	var opened = false
	var closed = false
	var grid # reference to our NavGrid object
	
	func _init(pos, grid):
		self.grid = grid
		self.pos = pos
	
	func direction_to(node):
		return node.pos - pos
	
	func distance_to(node):
		return pos.distance_to(node.pos)
	
	func _get_neighbors():
		if !neighbors:
			generate_neighbors()
		return neighbors
	
	func add_neighbor(pos):
		var node = grid.node_at(pos)
		if node:
			neighbors.push_back(node)
	
	func generate_neighbors():
		var n = []
		for h in [H, -H]:
			var h_walkable = grid.is_walkable_at(pos + h)
			if h_walkable:
				add_neighbor(pos + h)
			for v in [V, -V]:
				var v_walkable = grid.is_walkable_at(pos + v)
				if v_walkable:
					add_neighbor(pos + v)
					if h_walkable:
						add_neighbor(pos + h + v)
	
	func step(dir):
		return grid.node_at(pos + dir)
	
	# a node n in neighbors(x) is forced if:
	# 1. n is not a natural neighbor of x (would have been
	#    pruned? or has an obstacle? idfk)
	# 2. dist_with_x < dist_without_x
	func is_forced():
		return true
	
	func print():
		return str("pos: ", pos, " | opened: ", opened, " | closed: ", closed,
				" | parent: ", parent.pos if parent else "(none)")

# -----------------------------------------------------------

class NavGrid:
	var grid = []
	var tilemap
	
	func _init(tilemap):
		self.tilemap = tilemap
		var size = tilemap.get_used_rect().size
		grid.resize(size.x)
		for x in range(size.x):
			grid[x] = []
			grid[x].resize(size.y)
	
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
	
	func is_walkable_at(pos):
		return tilemap.is_walkable_at(pos)

# -----------------------------------------------------------

class Heap:
	var list = []
	
	func push(node):
		list.push_back(node)
	
	func pop():
		var min_f = INF
		var min_i = -1
		for i in list.size():
			if list[i].f < min_f:
				min_f = list[i].f
				min_i = i
		var node = list[min_i]
		list.remove(min_i)
		return node
	
	func empty():
		return list.empty()

# -----------------------------------------------------------

var open_list
var grid
var start_node
var goal_node

# -----------------------------------------------------------

func process_node():
	print("process node")
	node = open_list.pop()
	node.closed = true
	closed_list.push_back(node.pos)
	
	print("node: ", node.print())
#		var print_list = []
#		for n in open_list.list:
#			print_list.push_back(n.pos)
#		print("open_list: ", print_list)
	
	path = backtrace(node)
	
	if node == goal_node:
		set_process(false)
		open_list = null
		return
	
	neighbors = node.neighbors
	
	for neighbor in node.neighbors:
		if neighbor.closed:
			continue
		
		var g = node.g + node.distance_to(neighbor)
		
		if !neighbor.opened:
			open_list.push(neighbor)
			neighbor.opened = true
		elif g >= neighbor.g:
			continue
		
		neighbor.parent = node
		neighbor.g = g
		neighbor.f = neighbor.g + neighbor.distance_to(goal_node)


func a_star(start, goal):
	grid = NavGrid.new(self)
	start_node = grid.node_at(start)
	goal_node = grid.node_at(goal)
	closed_list = []
	
	open_list = Heap.new()
	open_list.push(start_node)
	start_node.g = 0
	start_node.f = start_node.distance_to(goal_node)
	set_process(true)

# -----------------------------------------------------------

func jump_point(start, goal):
	var grid = NavGrid.new(self)
	var start_node = grid.node_at(start)
	var goal_node = grid.node_at(goal)
	
	var open_list = [start_node]
	start_node.g = 0
	start_node.f = 0
	
	while open_list:
		var node = open_list.pop_back()
		
		print("node: ", node.print())
		var print_list = []
		for n in open_list:
			print_list.push_back(n.pos)
		print("open_list: ", print_list)
		
		if node.closed:
			continue
		node.closed = true
		
		if node == goal_node:
			return backtrace(goal_node)
		
		identify_successors(node, start_node, goal_node, open_list)

# -----------------------------------------------------------

func identify_successors(x, start, goal, open_list):
	for neighbor in prune(x):
		var successor = jump(x, x.direction_to(neighbor), start, goal)
		successor.parent = x
		open_list.push_back(successor)

# -----------------------------------------------------------

# we prune OUT neighbor n if the length of the path from x's
# parent p(x) straight to n (dist_without_x) is less than (or
# equal to, for a straight path) the length of the path from
# p(x) to x to n (dist_with_x). since we want to return a
# list of the neighbors we HAVEN'T pruned, we flip this.
#
# thus for n NOT to be pruned, dist_without_x should be >=
# dist_with_x for a diagonal path, and strictly > dist_with_x
# for a straight path.
func prune(x):
	# we need x's parent to tell which direction to prune by,
	# so if x is the start node (no parent), we can't prune
	if !x.parent:
		return x.neighbors
	
	var pruned_neighbors = []
	
	for n in x.neighbors:
		var dist_without_x = n.distance_to(x.parent)
		var dist_with_x = n.distance_to(x) + x.distance_to(x.parent)
		
		var d = x.parent.direction_to(x)
		
		if d.x and d.y: # diagonal (neither axis is 0)
			if dist_with_x <= dist_without_x:
				pruned_neighbors.push_back(n)
		
		elif dist_with_x < dist_without_x:
			pruned_neighbors.push_back(n)
	
	return pruned_neighbors

# -----------------------------------------------------------

func jump(x, d, start, goal):
	var n = x.step(d)
	
#	if !n.is_walkable():
#		return null
	
	if n == goal:
		return n
	
	# if exists n' in n.neighbors such that n is forced:
	if n.is_forced():
		return n
	
	if d.x and d.y: # diagonal (neither axis is 0)
		for i in ['x', 'y']:
			if jump(n, d[i], start, goal):
				return n
	
	return jump(n, d, start, goal)

# -----------------------------------------------------------

func is_walkable_at(pos):
	var walkable = get_cellv(pos) == WALKABLE
	var size = get_used_rect().size
	var in_bounds = (pos.x >=0 && pos.y >= 0 and
			pos.x < size.x && pos.y < size.y)
	return walkable && in_bounds

# -----------------------------------------------------------

func backtrace(node):
	var path = [node.pos]
	while node.parent:
		node = node.parent
		path.push_front(node.pos)
	return path
