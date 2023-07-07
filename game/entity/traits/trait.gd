extends RefCounted
class_name Trait
"""
superclass for entity traits.
"""

var parent: Entity

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready(): pass
#	Dispatcher.tick_changed.connect(_on_tick_changed)

# --------------------------------------------------------------------------- #

func _init(_data: Dictionary, _parent: Entity):
	parent = _parent
	deserialize(_data)


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

# list of property names to persist and load
func save_keys() -> Array[StringName]:
	return [] as Array[StringName]

# --------------------------------------------------------------------------- #
# TODO: this is identical to serialization for entities.
# we should extract it to a static util function

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

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #
