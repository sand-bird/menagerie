class_name ApproachAction
extends MoveAction
"""
move action that targets an entity and repaths every tick.
"""

var target: Entity


static func _save_keys() -> Array[StringName]:
	return [&'target']

# required: target
# optional: speed, target_distance, timeout
func _init(monster: Monster, options: Dictionary = {}):
	# add the target's size (the radius of its collision circle) to the target
	# distance.  since the target position is the _center_ of the target, this
	# will allow us to stop once we touch the target's side.
	super(monster, options)
	require_target()
	target_distance += target.size
	dest = target.position


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# the main difference between `approach` and `move` is that approach repaths
# once per tick.
func _tick():
	if require_target() and dest.distance_squared_to(t.position) > target_distance ** 2:
		m.nav.target_position = t.position
		dest = t.position
	super._tick()
