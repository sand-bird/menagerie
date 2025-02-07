class_name IdleAction
extends Action

const min_dur = int(0.5 * Clock.TICKS_IN_HOUR)
const max_dur = 3 * Clock.TICKS_IN_HOUR

# options: duration
func _init(monster: Monster, options: Dictionary = {}):
	var duration = options.get('duration', randi_range(min_dur, max_dur))
	# pass `duration` to the base class as `timeout`.  the convention is to call
	# it `duration` when it's a success condition, and `timeout` otherwise.
	super(monster, { timeout = duration })


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _start():
	m.play_anim(Monster.Anim.IDLE)
	m.announce('is doing nothing!')

func _timeout(): exit(Status.SUCCESS)
