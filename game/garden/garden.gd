extends Control

#warning-ignore-all:unused_class_variable

# const GardenObject = preload("res://garden/object.tscn")
# const GardenItem = preload("res://garden/item.tscn")

# we maintain a lookup table for our entities, primarily so that conditions
# can check what's in the garden (though it also makes serialization easier).
# these should match 1 to 1 with the actual entities in the garden, just like
# the ui singleton's stack should match with the instanced ui node's children.
var monsters = {}
var items = {}
var objects = {}

func _ready():
	pass
# added to test pathing, camera sticking, etc. todo: remove someday

var test_mon

func init(data):
	Log.info(self, "initializing!")
	deserialize(data)
	Clock.start()
	if !monsters.is_empty(): test_mon = monsters[monsters.keys().front()]
	# camera.stick_target = test_mon

func _input(e): pass
#	if e is InputEventMouseButton and e.is_pressed() and test_mon:
#		$nav.calc_path(test_mon.get_pos(), get_global_mouse_position())
#		test_mon.set_current_action(
#			MoveAction.new(test_mon, get_global_mouse_position(), 1.5)
#		)

func _process(_delta):
	queue_redraw()

func _draw():
	super.draw_circle(test_mon.get_pos(), 4, Color.from_hsv(0, 1, 1))

# --------------------------------------------------------------------------- #

func calc_path(start, end): pass
#	return $nav.calc_path(start, end)

# --------------------------------------------------------------------------- #

# takes a position relative to the garden and moves the mouse there.
# warp_mouse expects a position relative to the screen, so we convert between
# the two with get_target_position, which returns the difference.
func set_mouse_position(mouse_pos):
	var new_mouse_pos = mouse_pos - $camera.get_target_position()
	warp_mouse(new_mouse_pos)

# it seems that get_global_mouse_position and get_local_mouse_position both
# return the mouse's position relative to the garden ¯\_(ツ)_/¯
func get_screen_relative_mouse_pos():
	return get_global_mouse_position() - $camera.get_target_position()

func get_screen_relative_position(pos):
	return pos - $camera.get_target_position()


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

func serialize():
	return {
#		camera = $camera.serialize(),
		terrain = save_terrain(),
		objects = save_objects(),
		monsters = save_monsters(),
		items = save_items()
	}

func deserialize(data):
	load_terrain(data.terrain)
	load_objects(data.objects)
	load_monsters(data.monsters)
	load_items(data.items)
#	if data.has("camera"):
#		$camera.deserialize(data.camera)

# --------------------------------------------------------------------------- #

func save_terrain():
	var grid_size = $terrain.get_used_rect().size
	var data = []
	data.resize(grid_size.y)
	for y in range(grid_size.y):
		data[y] = []
		data[y].resize(grid_size.x)
		for x in range(grid_size.x):
			data[y][x] = $terrain.get_cell(x, y)
	return data

func load_terrain(data):
	for y in data.size():
		for x in data[y].size():
			$terrain.set_cell(0, Vector2i(x, y), data[y][x])
	size = Vector2(data[0].size(), data.size()) * $terrain.cell_quadrant_size
	Log.debug(self, ["garden size: ", size])
	Log.debug(self, ["terrain used rect: ", $terrain.get_used_rect()])
	Log.verbose(self, ["terrain used cells: ", $terrain.get_used_cells(0)])

# --------------------------------------------------------------------------- #

func save_objects():
	var data = {}
	for uid in objects:
		data[uid] = objects[uid].serialize()
	return data

func load_objects(data):
	var GardenObject = load('res://object/garden_object.tscn')
	print(data)
	for uid in data:
		var object = GardenObject.instantiate()
		object.initialize(data[uid])
		objects[uid] = object
		$entities.add_child(object)
#		place_object(object)

# make the object 
#func place_object(object):
#	var position = $nav/tilemap.map_to_local(object.coordinates)
#	object.position = position
#	$nav/tilemap.set_cellv(object.coordinates, -1)

# --------------------------------------------------------------------------- #

func save_monsters():
	var data = {}
	for uid in monsters:
		data[uid] = monsters[uid].serialize()
	return data

func load_monsters(data):
	var Monster = load('res://monster/monster.tscn')
	for uid in data:
		var monster = Monster.instantiate()
		monster.initialize(data[uid])
		monsters[uid] = monster
		monster.garden = self
		$entities.add_child(monster)

# --------------------------------------------------------------------------- #

func save_items():
	var data = {}
	for uid in items:
		data[uid] = items[uid].serialize()
	return data

func load_items(data):
	print(data)
#	for id in data:
#		var item = GardenItem.instance()
#		item.initialize(data[uid])
#		items[uid] = item
#		$entities.add_child(item)
