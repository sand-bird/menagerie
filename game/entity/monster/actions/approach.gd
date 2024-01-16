extends MoveAction
class_name ApproachAction
"""
move action that targets an entity and repaths every tick.
"""

# maximum distance squared between the old target position and the new target
# position before we recalculate the path.
const MAX_DEST_DRIFT = 10

@onready var target: Entity

func _init(_m: Monster, _target: Entity, _distance: int = 0, _speed: float = 1, _t = null):
	super(_m, _target.position, _speed, _distance, _t)
	target = _target
	name = 'approach'

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# the main difference between `approach` and `move` is that approach repaths
# once per tick.
func _tick():
#	if dest.distance_squared_to(target.position) > MAX_DEST_DRIFT:
	m.nav.target_position = target.position
	super._tick()
