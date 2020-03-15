extends Control

#warning-ignore-all:unused_class_variable

# const GardenObject = preload("res://garden/object.tscn")
# const GardenItem = preload("res://garden/item.tscn")

# todo: move the color logic to the actual tint node whenever it becomes
# relevant. we will probably want to tint locales too, so it should be
# independent from the garden.
var colors = {
	6: Color("db9ab4"), # dawn
	8: Color("dbc2b8"), # morning
	11: Color("fbffe6"), # midday
	14: Color("fcdec3"), # afternoon
	18: Color("e48b9a"), # evening
	20: Color("b268dc"), # dusk
	23: Color("66588c") # night
}

# we maintain a lookup table for our entities, primarily so that conditions can
# check what's in the garden (though it also makes serialization slightly
# easier). these should match 1 to 1 with the actual entities in the garden,
# just like the ui singleton's stack should match with the instanced ui node's
# children. we have no way to guarantee this, though, unfortunately - we just
# have to be careful.
var monsters = {}
var items = {}
var objects = {}

func _ready():
	Dispatcher.connect("entity_highlighted", self, "highlight")
	Dispatcher.connect("entity_unhighlighted", self, "unhighlight")

var test_mon

func init(data):
	Log.info(self, "initializing!")
	deserialize(data)
#	print("tint color: ", $tint.color)
#	$tint.color = color1
	Time.start()
#	Dispatcher.connect("hour_changed", self, "update_color")
#	$tint/anim.play("tint")
	if !monsters.empty(): test_mon = monsters[monsters.keys().front()]

var path = []
var tpath = []

func _input(e):
	if e is InputEventMouseButton and e.is_pressed() and test_mon:
		$nav.calc_path(test_mon.get_position(), get_global_mouse_position())
		test_mon.current_action = Action.Walk.new(test_mon, get_global_mouse_position())

func calc_path(start, end):
	return $nav.calc_path(start, end)

# --------------------------------------------------------------------------- #

# if we're using a cursor, it'll trigger the "highlighted" dispatch when it
# bumps into an entity. it also give us the node pointer. when we're using
# touch, somebody else has to handle that input, and it will probably be us.
#
# we don't want our entities listening to the dispatches for *everyone* (at
# least for now? maybe someday they should, and get jealous of each other or
# something?), so we listen and delegate from the garden.
func highlight(entity):
	print("(garden) entity ", entity, " has been highlighted!")
	if entity.has_method("highlight"): entity.highlight()
	$ui/select_hud.select(entity)

func unhighlight(entity):
	$ui/select_hud.unselect(entity)

# --------------------------------------------------------------------------- #
# color stuff

#func get_anim_duration(hour):
#	pass

func update_color(hour):
	var anim = $tint/anim.get_animation("tint")
	anim.track_set_key_value(0, 0, $tint.color)
	anim.set_length(1)
	anim.track_insert_key(0, 1, colors[hour])

	$tint/anim.play("tint")

# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
# man, the save and load functions for all the entities are literally
# identical. we COULD dry them... but let's not, it isn't worth it :(

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
	var size = $terrain.get_used_rect().size
	var data = []
	data.resize(size.y)
	for y in range(size.y):
		data[y] = []
		data[y].resize(size.x)
		for x in range(size.x):
			data[y][x] = $terrain.get_cell(x, y)
	return data

func load_terrain(data):
	for y in data.size():
		for x in data[y].size():
			$terrain.set_cell(x, y, data[y][x])
	rect_size = Vector2(data[0].size(), data.size()) * $terrain.cell_size
	Log.debug(self, ["garden size: ", rect_size])
	Log.debug(self, ["terrain used rect: ", $terrain.get_used_rect()])
	Log.verbose(self, ["terrain used cells: ", $terrain.get_used_cells()])

# --------------------------------------------------------------------------- #

func save_objects():
	var data = {}
	for uid in objects:
		data[uid] = objects[uid].serialize()
	return data

func load_objects(data):
	print(data)
#	for uid in data:
#		var object = GardenObject.instance()
#		object.initialize(data[uid])
#		objects[uid] = object
#		$entities.add_child(object)

# --------------------------------------------------------------------------- #

func save_monsters():
	var data = {}
	for uid in monsters:
		data[uid] = monsters[uid].serialize()
	return data

func load_monsters(data):
	var Monster = load('res://monster/monster.tscn')
	for uid in data:
		var monster = Monster.instance()
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
