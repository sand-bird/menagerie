extends Control

const Monster = preload("res://monster/monster.tscn")
# todo: items and objects

"""
var color_night = Color("66588c")
var color_dawn = Color("db9ab4")
var color_morning = Color("dbc2b8")
var color_noon = Color("fbffe6")
var color_afternoon = Color("fcdec3")
var color_evening = Color("e48b9a")
var color_dusk = Color("b268dc")

var colors = {
	6: color_dawn,
	8: color_morning,
	11: color_noon,
	14: color_afternoon,
	18: color_evening,
	20: color_dusk
}
"""

# we maintain a lookup table for our entities, primarily so
# that conditions can check what's in the garden (though it
# also makes serialization slightly easier). these should
# match one to one with the actual entities in the garden, 
# just like the ui singleton's stack should match with the 
# instanced ui node's children. we have no way to guarantee
# this, though, unfortunately - we just have to be careful.
var monsters = {}
var items = {}
var objects = {}


func _ready():
	Dispatcher.connect("entity_highlighted", self, "highlight")

func init(data):
	Log.info(self, "initializing!")
	deserialize(data)
	Dispatcher.emit_signal("ui_open", ["garden/clock_hud", 0, false])
#	print("tint color: ", $tint.color)
#	$tint.color = color1
	Time.start()
#	Dispatcher.connect("hour_changed", self, "update_color")
#	$tint/anim.play("tint")

# -----------------------------------------------------------

# if we're using a cursor, it'll trigger the "highlighted"
# dispatch when it bumps into an entity. it also give us the
# node pointer. when we're using touch, somebody else has to
# handle that input, and it will probably be the us.
#
# we don't want our entities listening to the dispatches for
# *everyone* (at least for now? maybe someday they should, 
# and get jealous of each other or something?), so we 
func highlight(entity):
	print("(garden) entity ", entity, " has been highlighted!")
	if entity.has_method("highlight"): entity.highlight()

# -----------------------------------------------------------

func get_anim_duration(hour):
	pass

func update_color(hour):
	var anim = $tint/anim.get_animation("tint")
	anim.track_set_key_value(0, 0, $tint.color)
	anim.set_length(1)
	anim.track_insert_key(0, 1, Color(randf(), randf(), randf()))
	
	$tint/anim.play("tint")


# =========================================================== #
#                  S E R I A L I Z A T I O N                  #
# ----------------------------------------------------------- #
# man, the save and load functions for all the entities are
# literally identical. we COULD dry them... but let's not, it
# isn't worth it :(

func serialize():
	return {
		camera = $camera.serialize(),
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
	if data.has("camera"):
		$camera.deserialize(data.camera)

# -----------------------------------------------------------

func save_terrain(): 
	var size = $terrain.get_used_rect()
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
	Log.debug(self, ["terrain used cells: ", $terrain.get_used_cells()])

# -----------------------------------------------------------

func save_objects():
	var data = {}
	for uid in objects:
		data[uid] = objects[uid].serialize()
	return data

func load_objects(data): pass
#	for uid in data:
#		var object = ObjectEntity.instance()
#		object.initialize(data[uid])
#		objects[uid] = object
#		$entities.add_child(object)

# -----------------------------------------------------------

func save_monsters():
	var data = {}
	for uid in monsters:
		data[uid] = monsters[uid].serialize()
	print(data)

func load_monsters(data):
	for uid in data:
		var monster = Monster.instance()
		monster.initialize(data[uid])
		monsters[uid] = monster
		$entities.add_child(monster)

# -----------------------------------------------------------

func save_items():
	var data = {}
	for uid in items:
		data[uid] = items[uid].serialize()
	return data

func load_items(data): pass
#	for id in data:
#		var item = Item.instance()
#		item.initialize(data[uid])
#		items[uid] = item
#		$entities.add_child(item)
