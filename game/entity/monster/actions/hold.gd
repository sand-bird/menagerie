class_name HoldAction
extends GrabAction
"""
grab an entity and hold it until timeout.
if the monster is not in grabbing range of the target, it will first approach
the target (see GrabAction).

differences from the parent grab action:
	- do NOT exit with success after grabbing the target
	- DO release the target on exit
"""

static func _save_keys(): return [&'target']

func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options)


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _tick():
	if require_in_range() and m.grabbed != t:
		prints(t, 'ticks remaining on hold')
		m.grab(t)

func _exit(_status): m.release()
