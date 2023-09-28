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

func _init(config: Dictionary, state: Dictionary, parent_: Entity):
	parent = parent_
	configure(config)
	deserialize(state)

# --------------------------------------------------------------------------- #

# takes a trait configuration object from an entity's data definition and sets
# up the trait.  should be implemented by subclasses.
func configure(config: Dictionary = {}): pass

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
