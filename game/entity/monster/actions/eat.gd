extends Action
class_name EatAction
"""
action to eat an item.

prerequisites: target is grabbed (grab action, which has its own prerequisite
of approaching the target)
"""

const KCAL_PER_GRAM = {
	protein = 4,
	carbs = 4,
	fat = 9,
	fiber = 2
}

# eat (item)
# prepend other actions targeting item if necessary (approach, steal)
# success when item is eaten
# fail if item is lost or if previous steps fail

@onready var t: Entity = null

# options: timeout
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	super(monster, options.get('timeout'))
	t = target
	name = 'eat'
	require_grabbing()

# --------------------------------------------------------------------------- #

func require_grabbing() -> bool: return require(
	m.is_grabbing(t),
	func(): prereq = GrabAction.new(m, t)
)

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# +mood based on preference for target
func estimate_mood() -> float: return 0
# +belly based on mass of target
func estimate_belly() -> float: return t.mass
# +energy based on energy content of target
func estimate_energy() -> float: return calc_energy_density()
# note: may be social results if eating the item would involve grabbing it from
# another monster (determined by prerequisite actions).

# test test test
func mod_utility(utility: float): return 100


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# called once, when the action starts running
func _start():
	m.announce('wants to eat ' + t.get_display_name())

func _tick(): pass

func _proc(_delta): pass

# --------------------------------------------------------------------------- #

# TODO: this should be an enum
const ENERGY_SOURCES = [&'protein', &'fat', &'fiber', &'carbs']

func calc_energy_density():
	var efficiency = m.get_energy_source_efficiency()
	var edible: EdibleTrait = t.traits.edible
	var total_kcal: float = 0.0
	for source in ENERGY_SOURCES:
		var source_grams = edible[source]
		var kcal = source_grams * KCAL_PER_GRAM[source] * efficiency[source]
		total_kcal += kcal
	return total_kcal / t.mass
