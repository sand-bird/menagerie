extends "res://ui/main_menu/menu_chapter.gd"
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
	initialize()

func initialize(arg = null):
	super.initialize(arg)
	# specific stuff goes here
