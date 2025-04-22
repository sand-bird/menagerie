class_name GrabAction
extends Action
"""
action to grab an entity.
exits with success when the entity is grabbed.

prerequisites: in range (approach)
"""

var target: Entity

static func _save_keys(): return [&'target']

# required: target
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options)
	require_target()
	require_in_range()

#                           r e q u i r e m e n t s                           #
# --------------------------------------------------------------------------- #

func require_in_range() -> bool: return require(
	m.grabbed == t or t in m.get_colliding_bodies(),
	func (): prereq = ApproachAction.new(m, { target = t })
)

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# +mood according to preference for grabbed
func estimate_mood() -> float: return 0
# +social if grabbed is a monster
func estimate_social() -> float: return 0

func mod_utility(_utility): return -1

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _proc(_delta):
	if require_target() and require_in_range() and m.grabbed != t: m.grab(t)
	if m.grabbed == t: exit(Status.SUCCESS)

func _timeout():
	exit(Status.SUCCESS if m.is_grabbing(t) else Status.FAILED)
