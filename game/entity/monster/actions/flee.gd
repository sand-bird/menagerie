class_name FleeAction
extends MoveAction

# boids flee behavior from target
# success when timeout is reached
# fail if reached by target

var target: Entity = null

static func _save_keys(): return [&'target']

# required: target
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options)
	t = target

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _timeout():
	exit(Status.SUCCESS)
