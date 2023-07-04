extends Action

# calls move to pos of target, recalculate path every tick
# success when target is reached
# fail if duration runs out
# longish default duration - used as a timeout in case pet gets stuck

func _init(m, target, speed = null, t = null):
	super(m, t)
	pass
