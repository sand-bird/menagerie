extends Action

# bury(item, pos)
# prepend actions to get item if necessary
# dig(pos) -> put_item(item) -> 

@onready var dest: Vector2
@onready var t: Entity

# options: timeout
func _init(monster: Monster, target: Entity, dest_: Vector2, options: Dictionary = {}):
	super(monster, options.get('timeout'))
	t = target
	dest = dest_
	name = 'bury'

func require_grabbing() -> bool:
	var is_grabbing = m.grabbed == t
	if !is_grabbing: prereq = GrabAction.new(m, t)
	return is_grabbing
