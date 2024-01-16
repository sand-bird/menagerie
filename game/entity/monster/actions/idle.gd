extends Action
class_name IdleAction

const min_dur = int(0.5 * Clock.TICKS_IN_HOUR)
const max_dur = 3 * Clock.TICKS_IN_HOUR
const energy_per_tick := -0.5

func _init(_m, _t = null):
	super(_m)
	name = 'idle'
	if !_t: _t = randi_range(min_dur, max_dur)
	super._init(_m, t)


#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_energy() -> float: return float(t) * energy_per_tick


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _start():
	m.play_anim('idle')
	m.announce('is doing nothing!')

func _tick():
	return { energy = energy_per_tick }

func _timeout():
	exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

func calc_duration():
	var energy_needed = m.get_target_energy() - m.energy
	var dur_needed = energy_needed / energy_per_tick
	return clamp(dur_needed, min_dur, max_dur)
