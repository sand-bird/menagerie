extends Action
class_name EatAction

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
