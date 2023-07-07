extends Control
class_name Garden

#warning-ignore-all:unused_class_variable

# const GardenObject = preload("res://garden/object.tscn")
# const GardenItem = preload("res://garden/item.tscn")

# we maintain a lookup table for our entities, primarily so that conditions
# can check what's in the garden (though it also makes serialization easier).
# these should match 1 to 1 with the actual entities in the garden, just like
# the ui singleton's stack should match with the instanced ui node's children.
var monsters: Dictionary = {}
var items: Dictionary = {}
var objects: Dictionary = {}

func _ready():
	pass
# added to test pathing, camera sticking, etc. todo: remove someday

func init(data):
	Log.info(self, "initializing!")
	deserialize(data)
	Clock.start()

#func _process(_delta):
#	$nav_debug.draw_point(test_mon.position, 1, Color.from_hsv(0.5, 1, 1))

func _input(e):
	if e is InputEventMouseButton and e.is_pressed() and !monsters.is_empty() and false:
		for uuid in monsters:
			var m = monsters[uuid]
			m.set_current_action(
				MoveAction.new(m, get_global_mouse_position(), 1, 20)
			)
#		$nav_debug.draw_point(get_global_mouse_position(), 4, Color.from_hsv(0.5, 1, 1))

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

func get_map_size():
	# for some reason get_used_rect is short by one in the x-direction
	var map_size = $map.get_used_rect().size + Vector2i(1, 0)
	# get_used_rect.size is the number of tiles; we have to multiply it by the
	# grid size (stored on the tileset) to get the pixel size of the tilemap
	return map_size * $map.tile_set.tile_size

# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

func serialize():
	return {
#		camera = $camera.serialize(),
		terrain = $map.save_terrain(),
		objects = save_objects(),
		monsters = save_monsters(),
		items = save_items()
	}

func deserialize(data: Dictionary):
	$map.load_terrain(data.terrain)
	load_objects(data.objects)
	load_monsters(data.monsters)
	load_items(data.items)
#	if data.has("camera"):
#		$camera.deserialize(data.camera)

# --------------------------------------------------------------------------- #
# note: tilemaps can now instantiate scenes as tiles.  we may be able to use
# this for placing objects / adding them to the navmesh as unnavigable tiles.
# however, we probably still want to keep an index of objects in the garden,
# so we would need to start serialization/deserialization here and delegate to
# the tilemap only for placement/instantiation.
#
# note note: scene tiles literally just instance the scene at the specific tile
# coordinates, not really useful for this

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

# --------------------------------------------------------------------------- #

func save_monsters():
	var data = {}
	for uuid in monsters:
		data[uuid] = monsters[uuid].serialize()
	return data

# data is an map of ids to serialized monsters
func load_monsters(data = {}):
	for uuid in data:
		var monster_data = data[uuid]
		monster_data.uuid = uuid
		load_monster(monster_data)

# data is a serialized monster - see Monster.deserialize
func load_monster(data = {}):
	var monster = Monster.new(data, self)
	monsters[monster.uuid] = monster
	monster.name = monster.uuid
	$entities.add_child(monster)

# --------------------------------------------------------------------------- #

func save_items():
	var data = {}
	for uid in items:
		data[uid] = items[uid].serialize()
	return data

# data is an map of ids to serialized items
func load_items(data = {}):
	for uuid in data:
		var item_data = data[uuid]
		item_data.uuid = uuid
		load_item(item_data)

# data is a serialized item
func load_item(data = {}):
	var item = Item.new(data, self)
	items[item.uuid] = item
	item.name = item.uuid
	$entities.add_child(item)
