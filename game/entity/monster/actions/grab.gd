extends Action
class_name GrabAction
"""
action to grab an entity.

prerequisites: in range (approach)
"""

@onready var target: Entity

func _init(_m, _target, _t):
	super(_m, _t)
	target = _target
	name = 'grab'

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# +mood according to preference for grabbed
func estimate_mood() -> float: return 0
# +social if grabbed is a monster
func estimate_social() -> float: return 0


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# called once, when the action starts running
func _start(): pass

func _unpause(): _start()

# called each ingame tick
func _tick(): pass

# called each process update
func _proc(_delta): pass

# behavior when the timeout expires. all actions need a timeout to prevent
# infinite loops. by default the action fails, but this can be overridden by
# subclasses.
func _timeout():
	exit(Status.FAILED)
