class_name BuryAction
extends Action

# bury(item, pos)
# prepend actions to get item if necessary
# dig(pos) -> put_item(item) -> 

var dest: Vector2
var t: Entity

# options: timeout
func _init(monster: Monster, target: Entity, dest_: Vector2, options: Dictionary = {}):
	super(monster, options)
	t = target
	dest = dest_

static func _save_keys(): return [ &'dest', &'t']

static func _deserialize(monster: Monster, input: Dictionary):
	return BuryAction.new(monster, input.t, input.dest, input)

func require_grabbing() -> bool:
	var is_grabbing = m.grabbed == t
	if !is_grabbing: prereq = GrabAction.new(m, t)
	return is_grabbing
