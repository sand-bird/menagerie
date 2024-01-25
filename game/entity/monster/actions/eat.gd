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
func estimate_energy() -> float: return calc_energy_value()
# note: may be social results if eating the item would involve grabbing it from
# another monster (determined by prerequisite actions).



#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

# called once, when the action starts running
func _start():
	m.announce('wants to eat ' + t.get_display_name())

# TODO: multiple bites
func _tick():
	if require_grabbing() and prereq == null:
		var edible: EdibleTrait = t.traits.edible
		m.update_belly(t.mass)
		for source in Monster.energy_source_values:
			if source in edible: m[source] += edible[source]
		t.tree_exited.connect(func(): exit(Status.SUCCESS))
		t.queue_free()


# --------------------------------------------------------------------------- #

func calc_energy_value() -> float:
	var energy_value: float = 0
	var edible: EdibleTrait = t.traits.edible
	for source in Monster.energy_source_values:
		var source_qty: float = edible[source] if source in edible else 0
		var kcal: float = source_qty * Monster.energy_source_values[source]
		energy_value += kcal
	return minf(energy_value, m.target_energy)
