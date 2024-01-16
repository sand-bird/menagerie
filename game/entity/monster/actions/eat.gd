extends Action
class_name EatAction
"""
action to eat an item.

prerequisites: target is grabbed (grab action, which has its own prerequisite
of approaching the target)
"""
# eat (item)
# prepend other actions targeting item if necessary (approach, steal)
# success when item is eaten
# fail if item is lost or if previous steps fail

@onready var target: Entity = null

func _init(m, _target, timeout = null):
	target = _target
	super(m, timeout)
	name = 'eat'

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# +mood based on preference for target
func estimate_mood() -> float: return 0
# +belly based on mass of target
func estimate_belly() -> float: return target.mass
# +energy based on energy content of target
func estimate_energy() -> float: return 0
# note: may be social results if eating the item would involve grabbing it from
# another monster (determined by prerequisite actions).

# test test test
func mod_utility(utility: float): return 100


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# called once, when the action starts running
func _start():
	m.announce('wants to eat ' + target.get_display_name())
	pass

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
