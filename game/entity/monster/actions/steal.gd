class_name StealAction
extends Action
"""
steal the target or steal from the target, depending on what kind of entity
the target is?  or maybe we should just have `steal` and `steal_from`...
"""

var t: Entity

# options: timeout
func _init(monster: Monster, target: Entity, options: Dictionary = {}):
	super(monster, options)
	t = target

static func _save_keys() -> Array[StringName]:
	return [&'t']

static func _deserialize(monster: Monster, input: Dictionary):
	return StealAction.new(monster, input.get('t'), input)


#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_social(): return 0
func estimate_mood(): return 0


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #
