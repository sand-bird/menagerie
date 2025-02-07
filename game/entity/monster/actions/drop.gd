class_name DropAction
extends Action
"""
drop a grabbed entity.

should support optional parameters for more complex behavior:

- if nothing is passed, drop the grabbed entity at the current position.
  exits with success after dropping, or with failure if nothing was grabbed

- if `position` is given, move there and then drop the grabbed entity.
  exits with success after dropping.  exits with failure if nothing is grabbed,
  or if grabbed entity is lost en route.

- if `target` is passed, treat grabbing the target as a prerequisite, meaning
  we attempt to re-grab it if it's lost en route.  (note that it's possible to
  call this action with a target but no position, in which case the monster
  would approach the target, grab it, and immediately drop it.)
"""

var pos: Vector2
var t: Entity = null

# options: target, position, timeout
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options)
	pos = options.get('position', monster.position)
	t = options.get('target')

static func _save_keys(): return [&'t', &'pos']


# --------------------------------------------------------------------------- #

func require_grabbing_target() -> bool: return require(
	m.is_grabbing(t),
	func (): prereq = GrabAction.new(m, t)
)

func require_grabbing() -> bool: return require(
	m.is_grabbing(),
	func (): exit(Status.FAILED)
)

func require_at_position() -> bool: return require(
	# TODO: extract this to a standardized "is at position" function on Monster
	m.position.distance_squared_to(pos) < 100,
	func (): prereq = MoveAction.new(m, pos)
)


#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# +mood according to preference for grabbed
func estimate_mood() -> float: return 0
# +social if grabbed is a monster
func estimate_social() -> float: return 0


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _tick():
	var require_grabbing_fn = (
		require_grabbing_target if t else require_grabbing
	)
	if require_grabbing_fn.call() and require_at_position():
		m.release()
		exit(Status.SUCCESS)
