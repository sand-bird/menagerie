class_name ApproachAction
extends MoveAction
"""
move action that targets an entity and repaths every tick.
"""

@onready var t: Entity

# options (inherited from MoveAction): speed, target_distance, timeout
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	# add the target's size (the radius of its collision circle) to the target
	# distance.  since the target position is the _center_ of the target, this
	# will allow us to stop once we touch the target's side.
	options.target_distance = options.get('target_distance', monster.size) + target.size
	super(monster, target.position, options)
	t = target
	name = 'approach'
	require_target()

#                           r e q u i r e m e n t s                           #
# --------------------------------------------------------------------------- #

func require_target() -> bool:
	return require(!!t, func(): exit(Status.FAILED))


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# the main difference between `approach` and `move` is that approach repaths
# once per tick.
func _tick():
	if require_target() and dest.distance_squared_to(t.position) > target_distance ** 2:
		m.nav.target_position = t.position
	super._tick()
