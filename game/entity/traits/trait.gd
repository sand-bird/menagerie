extends RefCounted
class_name Trait
"""
superclass for entity traits.
"""

var parent: Entity

# abstract, override on trait implementations
func get_actions(_m: Monster) -> Array[Action]:
	return [] as Array[Action]

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready(): pass
#	Dispatcher.tick_changed.connect(_on_tick_changed)

# --------------------------------------------------------------------------- #

# `config` is initialization parameters and comes from the data definition for
# the entity to which this trait belongs.  `state` comes from the serialized
# state for that entity.
func _init(config: Dictionary, state: Dictionary, parent_: Entity):
	parent = parent_
	configure(config)
	deserialize(state)

# --------------------------------------------------------------------------- #

# list of property names to load from a data definition
func config_keys() -> Array[StringName]:
	return [] as Array[StringName]

# --------------------------------------------------------------------------- #

# takes a trait configuration object from an entity's data definition and sets
# up the trait.  works exactly the same way as `deserialize`, except with
# config keys instead of save keys.
func configure(config: Dictionary = {}):
	var ck = config_keys()
	for key in ck:
		U.deserialize_value(self, config.get(key), key)


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

# list of property names to persist and load
func save_keys() -> Array[StringName]:
	return [] as Array[StringName]

# --------------------------------------------------------------------------- #

# trait state is stored on the parent entity
func serialize():
	var serialized = {}
	for key in save_keys():
		serialized[key] = parent.serialize_value(get(key))
	return serialized

# --------------------------------------------------------------------------- #

func deserialize(serialized = {}):
	var sk = save_keys()
	for key in sk:
		U.deserialize_value(self, serialized.get(key), key)

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #
