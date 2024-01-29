class_name Constants
"""
This file is for truly global constants that don't make sense as part of any
single class.  Most constants and enums should be declared where they are
relevant - eg, Monster.Anim, Action.Status, etc.
"""

const JOULES_PER_KCAL = 4184
# we need distance in "meters" to calculate the work in "joules" that a monster
# performs when it moves.  we abitrarily decide that a grid tile (16x16) is a
# meter across.
const PIXELS_PER_METER = 5

const UI_ELEMENT_PATH = "res://assets/ui/elements"
const UI_ICON_PATH = "res://assets/ui/icons"
