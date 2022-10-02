extends Action

# action to drop a held item.
# assumes the item is already held. fail if held item is missing or incorrect
# prepend moving to target if necessary. fail if target is missing.

# target can either be a position, an object, or null. if null, drop item at
# current position.

func _init(m, item, target = null).(m):
	pass
