class_name Garden
extends Control

## since monster actions usually target other entities in the garden, monsters
## will wait to deserialize their actions until all garden entities are loaded.
signal entities_loaded

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

func init(data):
	deserialize(data)
	Clock.start()


func open_menu(entity: Entity):
	var menu = load("res://ui/radial_menu.tscn").instantiate()
	add_child(menu)
	menu.position = entity.position
	#var screen_pos = get_screen_relative_position(entity.position)
	#Dispatcher.ui_open.emit('radial_menu')
	#$ui.add_child(menu)
	#menu.position = screen_pos


func close_menu():
	pass

# =========================================================================== #
#                      P O S I T I O N I N G   U T I L S                      #
# --------------------------------------------------------------------------- #

## takes a position relative to the garden and moves the mouse there.
## warp_mouse expects a position relative to the screen, so we convert between
## the two with get_target_position, which returns the difference.
func set_mouse_position(mouse_pos):
	var new_mouse_pos = mouse_pos - $camera.get_target_position()
	warp_mouse(new_mouse_pos)

## it seems that get_global_mouse_position and get_local_mouse_position both
## return the mouse's position relative to the garden ¯\_(ツ)_/¯
## note: currently unused, not sure if needed
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
#                            I N T E R A C T I O N                            #
# --------------------------------------------------------------------------- #

enum ControlState {
	FREE,
	SELECTING,
	PLACING,
	COMMANDING
}

var control_state := ControlState.FREE

## interaction targets
var highlighted: Entity = null
var selected: Entity = null
## this should specifically be a Monster but that gives us a circular dependecy
var commanding: Entity = null

# --------------------------------------------------------------------------- #

var outline_material = preload("res://outline_material.tres")
var cg_material = preload("res://cg_material.tres")

func highlight(entity: Entity):
	highlighted = entity
	Dispatcher.entity_highlighted.emit(entity)
	entity.cg.material = outline_material
	# apply some kind of shader to the entity
	# show the highlight hud for the entity

func unhighlight(entity: Entity):
	if !highlighted: return
	if highlighted != entity:
		Log.warn(self, str("called unhighlight on an entity that wasn't highlighted! entity: ", entity, " highlighted: ", highlighted))
	Dispatcher.entity_unhighlighted.emit(entity)
	highlighted.cg.material = cg_material
	highlighted = null
	# remove shader on the entity
	# hide highlight hud

# --------------------------------------------------------------------------- #

func select(entity):
	selected = entity
	Dispatcher.entity_selected.emit(entity)
	control_state = ControlState.SELECTING
	print("==================== SELECTED!!! ----- ", entity)
	open_menu(entity)


func unselect(entity):
	Dispatcher.entity_unselected.emit(entity)
	selected = null
	Dispatcher.ui_close.emit('radial_menu')
	control_state = ControlState.FREE
	close_menu()
	# unstick camera
	# close radial menu

# --------------------------------------------------------------------------- #

func command(monster: Monster):
	commanding = monster
	control_state = ControlState.COMMANDING



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
	entities_loaded.emit()
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
