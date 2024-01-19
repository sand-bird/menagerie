class_name FleeAction
extends MoveAction

# boids flee behavior from target
# success when duration runs out
# fail if reached by target

@onready var t: Entity = null

# options: speed, target_distance, duration
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	# note: the `duration` option is equivalent to `timeout` on the base class.
	# convention is to call it `duration` when it's a success condition (like
	# here) and `timeout` when it's a failure condition (like in MoveAction).
	if options.has('duration'): options.timeout = options.duration
	super(monster, target.position, options)
	t = target
	name = 'approach'

func _timeout():
	exit(Status.SUCCESS)
