extends Action
class_name SleepAction

# must sleep at least an hour
const min_dur = 2 * Clock.TICKS_IN_HOUR
const max_dur = 24 * Clock.TICKS_IN_HOUR
const energy_per_tick = 2.0

# require a duration
func _init(_m, _t = null):
	super(_m, _t)
	name = 'sleep'
	if !t: t = calc_duration()
	super._init(_m, _t)

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# TODO: fix this calculation.  sleeping doesn't "restore" energy, but it does
# slow down the monster's metabolism and cause it to consume less energy
# relative to being awake.  this should return the energy saved by spending
# the duration sleeping vs idling (determined by the monster's BMR)
func estimate_energy() -> float: return float(t) * energy_per_tick

func mod_utility(u):
	match Clock.hour:
		23, 0: return u * 1.4
		22, 1: return u * 1.3
		21, 2: return u * 1.2
		20, 3: return u * 1.1
		_: return u

#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _start():
	m.play_anim('lie_down')
	m.queue_anim('sleep')
	m.announce('is going to sleep!')

func _unpause():
	exit(Status.FAILED)

# it'd be cute to make it snore occasionally
func _tick(): pass

func _timeout():
	exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

# TODO: fix this too.  i'm not really sure how we should actually decide how
# long to sleep, but "energy needed" ain't it
func calc_duration():
	var energy_needed = m.get_target_energy() - m.energy
	var dur_needed = energy_needed / energy_per_tick
	return clamp(dur_needed, min_dur, max_dur)
