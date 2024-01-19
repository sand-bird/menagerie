extends Action
class_name StealAction
"""
steal the target or steal from the target, depending on what kind of entity
the target is?  or maybe we should just have `steal` and `steal_from`...
"""

var t: Entity

# options: timeout
func _init(m: Monster, target: Entity, options: Dictionary = {}):
	super(m, options.get('timeout'))
	t = target
	name = 'steal'


#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_social(): return 0
func estimate_mood(): return 0


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #
