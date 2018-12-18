extends TileMap

# start and end in tile coordinates
var start_tile
var end_tile

# start and end in world coordinates
var start_pos
var end_pos

var path = [] # for printing

const WALKABLE = -1
const OBSTACLE = 0
const H = Vector2(1, 0)
const V = Vector2(0, 1)

var grid = []

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
	print(jump_point_2(start_tile, end_tile))
	print("path: ", path)
	update()

func _draw():
	if start_pos:
		draw_circle(start_pos, 4, Color(0, 0.5, 1))
	if end_pos:
		draw_circle(end_pos, 4, Color(1, 0, 0.5))
	if start_tile:
		draw_circle(map_to_world(start_tile), 4, Color(0, 1, 1))
	if end_tile:
		draw_circle(map_to_world(end_tile), 4, Color(1, 0, 1))
	for i in path:
		draw_circle(map_to_world(i), 4, Color(1, 1, 0))

# get back tile centerpoints instead of corners
func map_to_world(tile):
	return .map_to_world(tile) + cell_size / 2


class Heap:
	var items = []
	
	func push(item):
		items.push_back(item)
	
	func pop():
		if items.empty():
			return
		var m_f = INF
		var m_i = -1
		var m_item
		for i in items.size():
			var item = items[i]
			if item.f < m_f:
				m_f = item.f
				m_i = i
				m_item = item
		items.remove(m_i)
		return m_item
	
	func empty():
		return items.empty()
	
	func update_item():
		pass


class NavNode:
	var opened = false
	var closed = false
	var parent = null
	var position
	
	func _init(pos):
		position = pos

# -----------------------------------------------------------

func a_star(start, end):
	var open_list = [] # Heap.new() # (a, b) => return a.f - b.f
	var start_node = get_node_at(start)
	var end_node = get_node_at(end)
	start_node.g = 0
	start_node.f = 0

	open_list.push_back(start_node)
	start_node.opened = true

	while !open_list.empty():
		var node = open_list.pop_front()
		node.closed = true
		
		# print("evaluating node: ", node.print())

		if node == end_node:
			return backtrace(end_node)
		
		var neighbors = get_neighbors(node)

		for neighbor in neighbors:
			if neighbor.closed:
				continue
			
			var ng = node.g + neighbor.position.distance_squared_to(node.position)
			
			if !neighbor.opened or ng < neighbor.g:
				neighbor.g = ng
#				neighbor.h = neighbor.h #if neighbor.h else heuristic(
#					(neighbor.position - end).abs()
#				)
				neighbor.f = neighbor.g #+ neighbor.h
				neighbor.parent = node

				if !neighbor.opened:
					open_list.push_back(neighbor)
					neighbor.opened = true
				#else:
				#	open_list.update_item(neighbor)
	
	return []

# -----------------------------------------------------------

class NavNode2:
	var pos
	var neighbors = [] setget , _get_neighbors
	var parent
	var opened = false
	var closed = false
	var grid # reference to our NavGrid object
	
	func _init(pos, grid):
		self.grid = grid
		self.pos = pos
	
	func direction_to(node):
		return node.pos - pos
	
	func distance_to(node):
		return pos.distance_squared_to(node.pos)
	
	func _get_neighbors():
		if !neighbors:
			var dirs = [-V, H - V, H, H + V, V, -H + V, -H, -H - V]
			for dir in dirs:
				var node = grid.node_at(pos + dir)
				if node:
					neighbors.push_back(node)
		return neighbors
	
	func add_neighbor(pos):
		neighbors.push_back(grid.node_at(pos))
	
	func generate_neighbors():
		var n = []
		for h in [H, -H]:
			var h_walkable = is_walkable_at(pos + h)
			if h_walkable:
				add_neighbor(pos + h)
			for v in [V, -V]:
				if is_walkable_at(pos + v):
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

# -----------------------------------------------------------

class NavGrid:
	var grid = []
	
	func _init(size):
		grid.resize(size.x)
		for x in range(size.x):
			grid[x] = []
			grid[x].resize(size.y)
	
	func node_at(pos):
		# return null if out of bounds
		if pos.x >= grid.size() or pos.y >= grid[pos.x].size():
			return null
		
		# create nodes as necessary when coordinates are
		# accessed. we pass the node a reference to ourself
		# so that it can look up its neighbors.
		if !grid[pos.x][pos.y]:
			grid[pos.x][pos.y] = NavNode2.new(pos, self)
		
		return grid[pos.x][pos.y]

# -----------------------------------------------------------

func identify_successors_2(x, start, goal):
	var successors = []
	var neighbors = prune(x)
	for n in neighbors:
		var successor = jump_2(x, x.direction_to(n), start, goal)
		successor.parent = x
		successors.push_back(successor)
	return successors

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

func jump_2(x, d, start, goal):
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

func jump_point_2(start, goal):
	var grid = NavGrid.new(get_used_rect().size)
	var start_node = grid.node_at(start)
	var goal_node = grid.node_at(goal)
	var open_list = [start_node]
	start_node.opened = true
	while open_list:
		var node = open_list.pop_back()
		if node.closed:
			continue
		node.closed = true
		if node == goal_node:
			return backtrace(goal_node)
		var successors = identify_successors_2(node, start_node, goal_node)
		for successor in successors:
			open_list.push_front(successor)

# -----------------------------------------------------------

func jump_point(start, end):
	path = []
	print("\n------------------\nstart: ", start, " | end: ", end)
	var grid = init_grid()
	var open_list = []
	var start_node = get_node_at2(grid, start)
	var end_node = get_node_at2(grid, end)
	
	open_list.push_back(start_node)
	start_node.opened = true
	
	while !open_list.empty():
		var node = open_list.pop_back()
		node.closed = true
		Log.verbose(self, str("pos: ", node.position, " | parent: ", !!node.parent))
		if node == end_node:
			return backtrace(end_node)
		
		identify_successors(grid, node, open_list, end)

# -----------------------------------------------------------

func identify_successors(grid, node, open_list, end):
	var neighbors = find_neighbors(node)
	print("neighbors: ", neighbors)
	for neighbor in neighbors:
		var jump_point = jump(neighbor, node.position, end)
		if !jump_point:
			continue
		print("jump_point: ", jump_point)
		path.append(jump_point)
		var jump_node = get_node_at2(grid, jump_point)
		if jump_node.closed:
			continue
		var d = 0 # heuristic stuff
#		var ng = node.g + d
		if !jump_node.opened: # or ng < jump_node.g:
#			jump_node.g = ng
#			jump_node.h = 0 # heuristic stuff
#			jump_node.f = jump_node.g + jump_node.h
			jump_node.parent = node
			
			#if !jump_node.opened:
			open_list.push_back(jump_node)
			jump_node.opened = true

# -----------------------------------------------------------

func find_neighbors(node):
	var pos = node.position
	
	if !node.parent:
		return get_neighbors2(pos)
	
	var d = pos - node.parent.position
	Log.verbose(self, ["pos: ", pos, " | parent: ", node.parent.position, " | d: ", d])
	
	var dh = Vector2(d.x, 0)
	var dv = Vector2(0, d.y)
	
	var neighbors = []
	
	if d.x and d.y:
		var diags = [pos + dh, pos + dv]
		var both_walkable = true
		for diag in diags:
			if is_walkable_at(diag):
				neighbors.append(diag)
			else:
				both_walkable = false
		if both_walkable:
			neighbors.append(pos + d)
	
	elif d.x:
		add_neighbors_for_offset(pos, dh, Vector2(0, 1), neighbors)
	
	elif d.y:
		add_neighbors_for_offset(pos, dv, Vector2(1, 0), neighbors)
	
	return neighbors

# -----------------------------------------------------------

func add_neighbors_for_offset(pos, next, perp, neighbors):
	var walkable = [
		is_walkable_at(pos + perp),
		is_walkable_at(pos - perp)
	]
	if is_walkable_at(pos + next):
		neighbors.append(pos + next)
		if walkable[0]:
			neighbors.append(pos + next + perp)
		if walkable[1]:
			neighbors.append(pos + next - perp)
	if walkable[0]:
		neighbors.append(pos + perp)
	if walkable[1]:
		neighbors.append(pos - perp)

# -----------------------------------------------------------

func jump(pos, p_pos, end):
	if !is_walkable_at(pos):
		return null
	
	if pos == end:
		return pos
	
	var d = pos - p_pos
	
	var dh = Vector2(d.x, 0)
	var dv = Vector2(0, d.y)
	
	var h = Vector2(1, 0)
	var v = Vector2(0, 1)
	
	if d.x and d.y and (
			jump(pos + dh, pos, end) or 
			jump(pos + dv, pos, end)):
		return pos
	
	if d.x and (
			is_walkable_at(pos - v) &&
			!is_walkable_at(pos - dh - v) or
			is_walkable_at(pos + v) &&
			!is_walkable_at(pos - dh + v)):
		return pos
	
	if d.y and (
			is_walkable_at(pos - h) &&
			!is_walkable_at(pos - h - dv) or
			is_walkable_at(pos + h) &&
			!is_walkable_at(pos + h - dv)):
		return pos
	
	if (is_walkable_at(pos + dh) and 
			is_walkable_at(pos + dv)):
		return jump(pos + d, pos, end)
	
	return null

# -----------------------------------------------------------

func init_grid():
	var size = get_used_rect().size
	var grid = []
	grid.resize(size.x)
	for x in range(size.x):
		grid[x] = []
		grid[x].resize(size.y)
	return grid

# -----------------------------------------------------------

func get_node_at(tile):
	return grid[tile.y][tile.x]

# -----------------------------------------------------------

func get_node_at2(grid, pos):
	if !grid[pos.x][pos.y]:
		grid[pos.x][pos.y] = NavNode.new(pos)
	return grid[pos.x][pos.y]

# -----------------------------------------------------------

func get_neighbors(node):
	var neighbors = []
	var pos = node.position
	var directions = [
		get_node_at(Vector2(pos.x, pos.y - 1)),
		get_node_at(Vector2(pos.x + 1, pos.y)),
		get_node_at(Vector2(pos.x, pos.y + 1)), 
		get_node_at(Vector2(pos.x - 1, pos.y))
	]
	for direction in directions:
		if direction.walkable:
			neighbors.push_back(direction)
	
	return neighbors

# -----------------------------------------------------------

func get_neighbors2(pos):
	var neighbors = []
	var v = Vector2(0, 1)
	var h = Vector2(1, 0)
	var directions = [pos - v, pos + h, pos + v, pos - h]
	for direction in directions:
		if is_walkable_at(direction):
			neighbors.push_back(direction)
	
	return neighbors

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
