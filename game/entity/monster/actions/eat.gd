class_name EatAction
extends Action
"""
action to eat an item.

prerequisites: target is grabbed (grab action, which has its own prerequisite
of approaching the target)
"""

# eat (item)
# prepend other actions targeting item if necessary (approach, steal)
# success when item is eaten
# fail if item is lost or if previous steps fail

var t: Entity = null

# options: timeout
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	super(monster, options)
	t = target
	require_target()
	require_grabbing()

static func _save_keys(): return [&'t']

static func _deserialize(monster: Monster, input: Dictionary):
	return EatAction.new(monster, input.t, input)


#                           r e q u i r e m e n t s                           #
# --------------------------------------------------------------------------- #

func require_target() -> bool:
	return require(!!t, func(): exit(Status.FAILED))

func require_grabbing() -> bool: return require(
	m.is_grabbing(t),
	func(): prereq = GrabAction.new(m, t)
)

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_belly() -> float: return t.mass

# monsters should know that eating will give them energy, even if the payoff is
# not immediate.  
func estimate_energy() -> float: return 0
	# note: these two functions do exactly the same thing.  this is ok for now
	# since we're probably gonna simplify energy sources _again_ to a single
	# `stored_energy` / `energy_density` property.
#	var energy_value =  t.traits.edible.calc_energy_value()
#	var available_energy = m.available_energy()
#	return minf(energy_value, m.target_energy)

# +mood based on preference for target
func estimate_mood() -> float: return 0


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# called once, when the action starts running
func _start():
	m.announce('wants to eat ' + t.get_display_name())

# TODO: multiple bites
func _tick():
	if require_target() and require_grabbing() and prereq == null:
		var edible: EdibleTrait = t.traits.edible
		m.update_belly(t.mass)
		for source in Monster.ENERGY_SOURCE_VALUES:
			if source in edible: m[source] += edible[source]
		t.tree_exited.connect(func(): exit(Status.SUCCESS))
		t.queue_free()
