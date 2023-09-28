extends Trait
"""
trait for entities that can be eaten and provide nutrition.

config:
	- flavors (affects preference)
	- nutritional value
	- volume?

state:
	- amount_remaining

also relevant are type tags: fruit, vegetable, meat, mineral, candy, etc.
these are not specific to edibles so they should be generic entity tags instead
of trait config, but they will determine whether the food is edible for a given
monster (whether we should advertise an 'eat' action to it), and affect the
monster's preference for the food.
"""

const FLAVORS = {
	"sweet": T.SWEET,
	"sour": T.SOUR,
	"salty": T.SALTY,
	"bitter": T.BITTER,
	"spicy": T.SPICY,
	"savory": T.SAVORY,
	"tart": T.TART
}
