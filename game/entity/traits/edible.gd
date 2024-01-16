extends Trait
"""
trait for entities that can be eaten and provide nutrition.

also relevant are type tags: fruit, vegetable, meat, mineral, candy, etc.
these are not specific to edibles so they should be generic entity tags instead
of trait config, but they will determine whether the food is edible for a given
monster (whether we should advertise an 'eat' action to it), and affect the
monster's preference for the food.
"""

# mapping of flavor keys to display context - for now just translatable text
# labels, but later we can expand this to include colors or whatever else.
#
# here we define t-text for flavors in code, meaning flavors are not extensble;
# the list of valid flavor keys is hardcoded in `data/system/entity.schema`.
# it would be neat to make these another data type though.  we'd have to:
# 1. define a `flavor` data type with its own schema (at minimum this would have
#    a `name` property as translatable text)
# 2. update the `items` subschema for traits/edible/flavors (in `entity.schema`)
#    to validate that the item is a flavor key. this can't be done dynamically
#    in pure json-schema afaik; we either need to add a schema definition for
#    valid flavor keys and force anyone who adds a flavor to update it, or make
#    flavor a format and implement a special handler for it in the validator.
const FLAVORS = {
	&'sweet': T.SWEET,
	&'sour': T.SOUR,
	&'salty': T.SALTY,
	&'bitter': T.BITTER,
	&'spicy': T.SPICY,
	&'savory': T.SAVORY,
	&'tart': T.TART
}

#                                 c o n f i g                                 #
# --------------------------------------------------------------------------- #
func config_keys() -> Array[StringName]: return [
		&'flavors', &'protein', &'fat', &'carbs', &'fiber'
	] as Array[StringName]

var flavors: Array[StringName] = []

# energy sources
var protein: float = 0
var fat: float = 0
var carbs: float = 0
var fiber: float = 0

#                                  s t a t e                                  #
# --------------------------------------------------------------------------- #
func save_keys() -> Array[StringName]:
	return [&'amount_remaining'] as Array[StringName]

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

func load_flavors(_flavors):
	for flavor in _flavors:
		if FLAVORS.has(flavor): flavors.push_back(StringName(flavor))

#                                a c t i o n s                                #
# --------------------------------------------------------------------------- #

func get_actions(m: Monster) -> Array[Action]:
	return [EatAction.new(m, parent)]
