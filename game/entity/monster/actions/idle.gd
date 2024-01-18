extends Action
class_name IdleAction

const min_dur = int(0.5 * Clock.TICKS_IN_HOUR)
const max_dur = 3 * Clock.TICKS_IN_HOUR

func _init(_m, _t = null):
	super(_m)
	name = 'idle'
	if !_t: _t = randi_range(min_dur, max_dur)
	super._init(_m, t)

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _start():
	m.play_anim('idle')
	m.announce('is doing nothing!')

func _timeout(): exit(Status.SUCCESS)
