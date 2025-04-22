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
	# load_target will be called from the base Action constructor since `target`
	# is in our _save_keys, but we need to load it manually first in order to
	# initialize params for the parent MoveAction.
	load_target(options.target)
	# add the target's size (the radius of its collision circle) to the target
	# distance.  since the target position is the _center_ of the target, this
	# will allow us to stop once we touch the target's side.
	options.target_distance = options.get('target_distance', monster.size) + target.size
	options.dest = target.position
	super(monster, options)
	require_target()


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# the main difference between `approach` and `move` is that approach repaths
# once per tick.
func _tick():
	if require_target() and dest.distance_squared_to(t.position) > target_distance ** 2:
		m.nav.target_position = t.position
		dest = t.position
	super._tick()
