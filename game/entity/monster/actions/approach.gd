class_name ApproachAction
extends MoveAction
"""
move action that targets an entity and repaths every tick.
"""

@onready var t: Entity

# options (inherited from MoveAction): speed, target_distance, timeout
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	super(monster, target.position, options)
	t = target
	name = 'approach'

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# the main difference between `approach` and `move` is that approach repaths
# once per tick.
func _tick():
#	if dest.distance_squared_to(target.position) > MAX_DEST_DRIFT:
	m.nav.target_position = t.position
	super._tick()
