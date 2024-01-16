extends Action

# bury(item, pos)
# prepend actions to get item if necessary
# dig(pos) -> put_item(item) -> 

@onready var pos: Vector2
@onready var target: Entity

func _init(_m, _target, _pos, _timeout = null):
	super(_m, _timeout)

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# result should be the amount by which the action is expected to increase or
# decrease the drive (negative for a decrease).
func estimate_mood() -> float: return 0
func estimate_belly() -> float: return 0
func estimate_energy() -> float: return 0
func estimate_social() -> float: return 0

# takes in the utility value generated by the Decider, based on the output of
# the `estimate_{drive}` functions above, and returns a new utility value.
# can be used to modify the calculated utility value or simply override it. 
func mod_utility(utility: float): return utility


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
