class_name Traits
"""
trait "manager". loads and validates traits.
"""

const BASE_DIR = "res://entity/traits/"
const valid_traits: Array[StringName] = ['edible', 'perishable']

static func load(t: StringName):
	assert(t in valid_traits)
	return load(BASE_DIR.path_join(t + '.gd'))
