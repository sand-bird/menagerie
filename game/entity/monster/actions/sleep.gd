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

func _tick():
	return { energy = energy_per_tick }

func _timeout():
	exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

func calc_duration():
	var energy_needed = m.get_target_energy() - m.energy
	var dur_needed = energy_needed / energy_per_tick
	return clamp(dur_needed, min_dur, max_dur)
