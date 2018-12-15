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

var grid = []

func _ready():
	pass

# in the future we want to initialize our walkable/obstacle
# grid based on the GardenObjects passed in by garden. for
# now, we initialize it based on our drawn tilemap. this
# works the same way as garden's serialize_terrain() method.
func initialize(objects = null):
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
	path = a_star(start_tile, end_tile)
	grid = []
	initialize()
	print(path)
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
	var position
	var walkable = true
	var opened = false
	var closed = false
	var parent
	var g
	var f
	var h

	func _init(pos, walk = null):
		position = pos
		if walk != null: 
			walkable = walk
	
	func print():
		return str("pos: ", position, " | walk: ", walkable, " | parent: ", parent)


func get_node_at(tile):
	return grid[tile.y][tile.x]

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

func is_walkable_at(pos):
	return get_cellv(pos) == WALKABLE

func backtrace(node):
	var path = [node.position]
	while node.parent:
		node = node.parent
		path.push_front(node.position)
	return path

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


func jump_point(start, end):
	var open_list = Heap.new()
	var start_node = get_node_at(start)
	var end_node = get_node_at(end)

	start_node.g = 0
	start_node.f = 0

	open_list.push(start_node)
	start_node.opened = true

	while !open_list.empty():
		var node = open_list.pop()
		node.closed = true

		if node == end_node:
			return expand_path(backtrace(end_node))
		
		identify_successors(node)
	
	return []

func identify_successors(node):
	pass










