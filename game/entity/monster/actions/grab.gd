extends Action
class_name GrabAction
"""
action to grab an entity.
currently this attempts to grab the target until timeout, then succeeds if we
are grabbing the target and fails if not, and releases the target on exit.
we also want to support a mode where the action succeeds as soon as the target
is grabbed, and does _not_ release the target on exit (so we can use grabbing
as a prerequisite for other actions, eg eating.)

prerequisites: in range (approach)
"""

@onready var target: Entity

func _init(_m, _target, _t = null):
	super(_m, _t)
	prints('init grab action | timeout:', t)
	target = _target
	name = 'grab'
	require_in_range()

# require the monster to be in "grab range" of the target (or already grabbing
# it), else we queue an `approach` action as a prerequisite.
func require_in_range() -> bool:
	if m.grabbed == target: return true
	var grabbing_range = pow(m.data.size + target.data.size, 2)
	var in_range = m.position.distance_squared_to(target.position) < grabbing_range
	if !in_range: prereq = ApproachAction.new(m, target, grabbing_range)
	return in_range

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# +mood according to preference for grabbed
func estimate_mood() -> float: return 0
# +social if grabbed is a monster
func estimate_social() -> float: return 0


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _tick():
	if require_in_range() and m.grabbed != target:
		prints(t, 'ticks remaining on grab')
		m.grab(target)

func _timeout():
	if m.grabbed == target: exit(Status.SUCCESS)
	else: exit(Status.FAILED)

func _exit(_status):
	m.release()
