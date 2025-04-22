#class_name BuryAction
extends Action

# bury(item, pos)
# prepend actions to get item if necessary
# dig(pos) -> put_item(item) -> 

var dest: Vector2
var target: Entity

# required: target, dest
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options)

static func _save_keys(): return [ &'dest', &'t']
