extends Action
class_name IdleAction

const min_dur = int(0.5 * Clock.TICKS_IN_HOUR)
const max_dur = 3 * Clock.TICKS_IN_HOUR
const energy_per_tick := 0.05

func _init(m, t = null).(m):
	name = 'idle'
	if !t: t = Utils.randi_range(min_dur, max_dur)
	._init(m, t)

func estimate_result():
	return { energy = float(t) * energy_per_tick }

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
