extends Node2D

const NavGrid = preload("res://garden/navigation/nav_grid.gd")
const NavNode = preload("res://garden/navigation/nav_node.gd")
const Heap = preload("res://garden/navigation/heap.gd")

const STEP_TIME = 0.5 # in seconds

var map # reference to our parent tilemap

# start and end in tile coordinates
var start_tile
var goal_tile

# start and end in world coordinates
var start_pos
var goal_pos

var path = []
var neighbors = []
var open_list
var closed_list = []

var grid
var node

var start_node
var goal_node

var draw_list = []

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
	node = open_list.pop()
	node.closed = true
	closed_list.push_back(node.pos)
	
	path = backtrace(node)
	
	if node == goal_node:
		set_process(false)
		print("path found!")
		return
	
	neighbors = node.neighbors
	
	for neighbor in neighbors:
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
