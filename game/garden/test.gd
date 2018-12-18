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

func _draw():
#	if start_pos:
#		draw_circle(start_pos, 4, Color(0, 0.5, 1))
#	if end_pos:
#		draw_circle(end_pos, 4, Color(1, 0, 0.5))
	if start_tile:
		draw_circle(map.map_to_world(start_tile), 4, Color(0, 1, 1))
	if goal_tile:
		draw_circle(map.map_to_world(goal_tile), 4, Color(1, 0, 1))
	if open_list and !open_list.empty():
		for i in open_list.list:
			draw_circle(map.map_to_world(i.pos), 8, Color(0.5, 1, 0.5))
	for i in closed_list:
		draw_circle(map.map_to_world(i), 8, Color(1, 0.5, 0.5))
	for i in neighbors:
		draw_circle(map.map_to_world(i.pos), 5, Color(0, 1, 1))
	for i in path:
		draw_circle(map.map_to_world(i), 4, Color(1, 1, 0))
	if node:
		draw_circle(map.map_to_world(node.pos), 5, Color(0, 0, 1))

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
