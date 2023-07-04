extends RigidBody2D
class_name Entity
"""
base class for "garden entities": monsters, objects/sessiles, and items.

defines common parameters (including child nodes; all entities should have at
minimum a sprite and a collision shape) and the core logic for initialization,
serialization, and deserialization.

entity subclasses can override the `save_keys` function to add their own keys
to serialize and deserialize, and define custom deserialization behavior by
adding new `load_` and `generate_` functions.

during initialization, input data must be deserialized first before any child
nodes are created.  thus entity subclasses should always call `super()` at the
*start* of their `_init` function, *then* initialize whatever extra child nodes
they need.
"""

var garden: Garden

# child nodes
# -----------
# var anim: AnimationPlayer
var sprite: Sprite2D
var shape: CollisionShape2D

# core properties
# ---------------
var uuid: StringName # unique id of the entity
var type: StringName # id of the entity's data definition

var data:
	get: return Data.fetch(type)
	set(_x): return

# var traits: Array[Trait] = []

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready(): pass
#	Dispatcher.tick_changed.connect(_on_tick_changed)

# --------------------------------------------------------------------------- #

# entities must be initialized in code because they depend on data definitions
# that are loaded at runtime.  this makes storing the node's children in a
# PackedScene (entity.tscn) counter-productive, because the scene would be
# incomplete/invalid without initialization at runtime.
#
# instead, we should create the entire scene programmatically.  this allows us
# to initialize entities in a single step with `new`, rather than having to
# instantiate an incomplete scene and then initialize it in a separate step.
func _init(_data: Dictionary, _garden: Garden):
	garden = _garden
	deserialize(_data)
	
	var script: Script = get_script()
	# if this is called from a subclass of Entity, `base_script` is `entity.gd`,
	# otherwise it's null.  this ensures we get the right directory for generic
	# Entity child nodes (they should live in the same folder as their parent).
	var base_script: Script = script.get_base_script()
	var path: String = (
			base_script if base_script else script
		).resource_path.get_base_dir()
	
	sprite = load(path.path_join('sprite.gd')).new()
	add_named_child(sprite, 'sprite')
	
	shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	var size = data.size
	shape.shape.radius = size
	shape.position.y -= size
	add_named_child(shape, 'shape')


# --------------------------------------------------------------------------- #

# it's nicer to use vars for children because of typing, but we name them so
# other nodes can get them with `get_node`.  this is also necessary for $anim
# since it takes a NodePath to $sprite (the target of all animations).
func add_named_child(node: Node, n: String):
	node.name = n
	add_child(node)


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

# list of property names to persist and load.
# order matters for deserialization; some properties depend on others earlier
# in the list to already be loaded or generated (especially `type`).
func save_keys() -> Array[StringName]:
	return [&'uuid', &'type', &'position'] as Array[StringName]

# --------------------------------------------------------------------------- #

func serialize():
	var serialized = {}
	for key in save_keys():
		serialized[key] = serialize_value(get(key))
	return serialized

func serialize_value(value: Variant, key: String = ''):
	if value == null:
		Log.warn(self, ["serializing null value for key `", key, "`"])
	elif value is Array:
		return value.map(serialize_value)
	elif value is Vector2 or value is Vector2i:
		return { x = value.x, y = value.y }
	elif value is Object:
		if value.has_method('serialize'): return value.serialize()
		else: Log.error(self, [
			"tried to serialize object without `serialize` method: ", value])
	else: return value

# --------------------------------------------------------------------------- #

func deserialize(serialized = {}):
	var sk = save_keys()
	for key in sk:
		deserialize_value(serialized.get(key), key)

func deserialize_value(value: Variant, key: String):
	var loader = str('load_', key)
	# if the key has a loader, just call it and trust it to initialize
	if has_method(loader): call(loader, value)
	elif value == null:
		var generator = str('generate_', key)
		if has_method(generator): set(key, call(generator))
	else: set(key, value)

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

func load_position(_position):
	position = U.parse_vec(_position, generate_position())

# ideally we would fail to load an entity with an invalid type.  i'm not sure
# how to fail out of the constructor though, so for now just pick a valid one
func load_type(_type):
	if _type == null or Data.missing(_type): _type = generate_type()
	type = _type

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #

func generate_uuid(): return Uuid.v4()
func generate_type(): return Data.data.keys().pick_random()

func generate_position():
	for x in Vector2(0, 0):
		print(x)
	var garden_size = garden.get_map_size()
	return Vector2(
		randi_range(0, garden_size.x),
		randi_range(0, garden_size.y)
	)
