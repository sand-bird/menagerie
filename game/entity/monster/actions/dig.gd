class_name DigAction
extends Action
"""
dig a hole at a certain position.  can specify a position and have the monster
navigate there, or use the monster's current position by default.
"""

var pos: Vector2

# options: position, timeout
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options.get('timeout'))
	pos = options.get('position', m.position)
	name = "dig"
	require_at_position()

func require_at_position() -> bool: return require(
	# TODO: extract this to a standardized "is at position" function on Monster
	m.position.distance_squared_to(pos) < 100,
	func (): prereq = MoveAction.new(m, pos)
)
