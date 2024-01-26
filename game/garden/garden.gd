class_name Garden
extends Control

# we maintain a lookup table for our entities, primarily so that conditions
# can check what's in the garden (though it also makes serialization easier).
# these should match 1 to 1 with the actual entities in the garden, just like
# the ui singleton's stack should match with the instanced ui node's children.
var monsters:
	get: return get_tree().get_nodes_in_group(&'monsters')
	set(_x): return
var items:
	get: return get_tree().get_nodes_in_group(&'items')
	set(_x): return
var objects:
	get: return get_tree().get_nodes_in_group(&'objects')
	set(_x): return

func _ready():
	$tint.sync_anim()
# added to test pathing, camera sticking, etc. todo: remove someday

func init(data):
	Log.info(self, "initializing!")
	deserialize(data)
	Clock.start()

#func _process(_delta):
#	$nav_debug.draw_point(test_mon.position, 1, Color.from_hsv(0.5, 1, 1))

func _input(e):
	if e is InputEventMouseButton and e.is_pressed() and !monsters.is_empty():
		for uuid in monsters:
			var m = monsters[uuid]
			m.set_current_action(
				MoveAction.new(m, get_global_mouse_position(), { distance = 200 }),
				true
			)
		$nav_debug.draw_point(get_global_mouse_position(), 4, Color.from_hsv(0.5, 1, 1))

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

const entity_keys = [&'objects', &'monsters', &'items']

func serialize():
	var data = {
#		camera = $camera.serialize(),
		terrain = $map.save_terrain(),
	}
	for key in entity_keys:
		data[key] = save_entities(key)
	return data

func deserialize(data: Dictionary):
	$map.load_terrain(data.terrain)
	for key in entity_keys:
		load_entities(key, data)
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

func save_entities(key: StringName):
	var collection = get(key)
	var data = {}
	for entity in collection:
		data[entity.uuid] = entity.serialize()
	return data

var class_map = {
	&'objects': Sessile,
	&'monsters': Monster,
	&'items': Item
}

# state is a map of type keys (&'monsters', etc) to "entity maps", where each
# a map of uuids to a serialized entity
func load_entities(key: StringName, state = {}):
	var entities = state[key]
	for uuid in entities:
		var entity_data = entities[uuid]
		entity_data.uuid = uuid
		load_entity(key, entity_data)

# state is a serialized monster - see Monster.deserialize
func load_entity(key: StringName, state = {}):
	var entity = class_map[key].new(state, self)
	entity.add_to_group(key)
	entity.name = entity.uuid
	$entities.add_child(entity)
