extends MenuSection
"""
the encyclopedia contains information about all the different entities, grouped
by type (monsters, objects, items, etc).

entities that have been "discovered" (whose keys are in `Player.discovered`) are
viewable in greater detail than those that are not, but undiscovered entities
should still be listed in the encyclopedia.
"""

# TODO: use a constant or something for this
var categories = {
	monster = "Monster",
	object = "Object"
}

func _ready():
	title = "Encyclopedia"
