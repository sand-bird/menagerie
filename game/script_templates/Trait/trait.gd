extends Trait

func get_actions(_m: Monster) -> Array[Action]:
	return [] as Array[Action]

# list of property names to load from a data definition
func config_keys() -> Array[StringName]:
	return [] as Array[StringName]

# list of property names to persist and load
func save_keys() -> Array[StringName]:
	return [] as Array[StringName]

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #
