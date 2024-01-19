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

# options: duration
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	# note: the `duration` option is equivalent to `timeout` on the base class.
	# convention is to call it `duration` when it's a success condition (like
	# here) and `timeout` when it's a failure condition (like in GrabAction).
	if options.has('duration'): options.timeout = options.duration
	super(monster, target, options)
	name = 'hold'

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _tick():
	if require_in_range() and m.grabbed != t:
		prints(t, 'ticks remaining on hold')
		m.grab(t)

func _exit(_status): m.release()
