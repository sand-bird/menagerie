extends Node2D

#warning-ignore-all:unused_class_variable

const H = Vector2(1, 0)
const V = Vector2(0, 1)

const NavGrid = preload("res://garden/navigation/nav_grid.gd")
const NavNode = preload("res://garden/navigation/nav_node.gd")
const Heap = preload("res://garden/navigation/heap.gd")

const STEP_TIME = 0.7 # in seconds

var map # reference to our parent tilemap

# start and end in tile coordinates
var start_tile
var goal_tile

# start and end in world coordinates
var start_pos
var goal_pos

var path = []
var neighbors = []
var bad_neighbors = []
var jump_nodes = []
var open_list
var closed_list = []

var grid
var node

var start_node
var goal_node

var draw_list = []

var is_done = false

# -----------------------------------------------------------

func _init(map, start, goal):
	self.map = map
	start_tile = start
	goal_tile = goal
	grid = NavGrid.new(map)
	start_node = grid.node_at(start)
	goal_node = grid.node_at(goal)

	open_list = Heap.new()
	closed_list = []
	open_list.push(start_node)

	start_node.g = 0
	start_node.f = start_node.distance_to(goal_node)

	set_process(true)

# -----------------------------------------------------------

# we can't pass this anything, so all the stuff it draws has
# to come from a class variable. one option: dump everything
# to be drawn into a queue, and let _draw pop it off as it
# goes along - at least that would isolate it a bit.
func _draw():
#	draw(start_pos, 4, Color(0, 0.5, 1))
#	draw(end_pos, 4, Color(1, 0, 0.5))
	draw(start_tile, 4, Color(0, 1, 1))
	draw(goal_tile, 4, Color(1, 0, 1))
	if open_list:
		draw(open_list.list, 8, Color(0.5, 1, 0.5))
	draw(closed_list, 8, Color(1, 0.5, 0.5))
	draw(neighbors, 5, Color(0, 1, 1))
	draw(bad_neighbors, 5, Color(0.5, 0.1, 0.1))
	draw(jump_nodes, 3, Color(0.7, 0.7, 0.7))
	draw(path, 4, Color(1, 1, 0))
	draw(node, 5, Color(0, 0, 1))

# -----------------------------------------------------------

var timer = 0
func _process(delta):
	timer += delta
	if timer < STEP_TIME:
		return
	timer -= STEP_TIME
	if open_list and !open_list.empty():
		process_node()
	update()

# -----------------------------------------------------------

# each step of the pathfinding expansion (where a new node is
# popped off the heap and examined) happens here. all the
# necessary state is stored as class objects, so that we can
# debug the algorithm by:
# 1. inserting an arbitrary delay between steps by calling
#    process_node from within _process (alternately, we could
#    use a timer, but this is simpler)
# 2. updating the drawstack or whatever after each call, which
#    causes _draw to update using our many class variables
func process_node():
	if open_list.empty():
		set_process(false)
		print("path not found!")

	node = open_list.pop()
	node.closed = true
	closed_list.push_back(node.pos)

	path = backtrace(node)

	if node == goal_node:
		set_process(false)
		print("path found!")
		update()

	neighbors = node.prune()
	bad_neighbors = node.bad_neighbors
	jump_nodes = []

	for neighbor in neighbors:
		var successor = jump(node, node.direction_to(neighbor), goal_node)

		if !successor:
			continue

		if successor.closed:
			continue

		var g = node.g + node.distance_to(successor)

		if !successor.opened:
			open_list.push(successor)
			successor.opened = true
		elif g >= successor.g:
			continue

		successor.parent = node
		successor.g = g
		successor.f = successor.g + successor.distance_to(goal_node)

# -----------------------------------------------------------

func jump(x, d, goal):
	var n = x.step(d)

	if !grid.is_walkable_at(n.pos):
		return null

	jump_nodes.push_back(n)

	if n == goal:
		return n

	# if exists n' in n.neighbors such that n is forced:
	if n.is_forced(d):
		return n

	if d.x and d.y: # diagonal (neither axis is 0)
		for i in [H, V]:
			if jump(n, d * i, goal):
				return n

	return jump(n, d, goal)

# -----------------------------------------------------------

func backtrace(node):
	var path = [node.pos]
	while node.parent:
		node = node.parent
		path.push_front(node.pos)
	return path

# -----------------------------------------------------------

# encapsulates null checking and iteration, if the thing we
# want to draw is an array. we only draw circles anyway
func draw(to_draw, size, color):
	if !to_draw:
		return
	if typeof(to_draw) == TYPE_ARRAY:
		for item in to_draw:
			do_draw(item, size, color)
	else:
		do_draw(to_draw, size, color)

# -----------------------------------------------------------

# make sure we only draw if our item is a Vector2 or has a
# Vector2 property with a reasonable name (pos for NavNode)
func do_draw(item, size, color):
	var pos
	if typeof(item) == TYPE_VECTOR2:
		pos = item
	elif typeof(item) == TYPE_OBJECT:
		if 'pos' in item:
			pos = item.pos
		elif 'position' in item:
			pos = item.position
	if !pos: return
	draw_circle(map.map_to_world(pos), size, color)
