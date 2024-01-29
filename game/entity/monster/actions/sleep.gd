class_name SleepAction
extends Action

# must sleep at least an hour
const min_dur = 2 * Clock.TICKS_IN_HOUR
const max_dur = 24 * Clock.TICKS_IN_HOUR

# options: duration
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options.get('duration', calc_duration(monster)))
	name = 'sleep'

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_energy() -> float:
	var available_energy =  m.available_energy(true)
	return minf(float(timer) * energy_per_tick(m), available_energy)

# TODO: make this a modifier like Attribute.modify, where it's a positive
# multiplier on positive utility, and an inverse multiplier on negative utility
# at night, and vice versa during the day 
#func mod_utility(u):
#	match Clock.hour:
#		23, 0: return u * 1.4
#		22, 1: return u * 1.3
#		21, 2: return u * 1.2
#		20, 3: return u * 1.1
#		_: return u

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

# returns the difference in energy gained per tick between when the monster is
# asleep and awake.
static func energy_per_tick(monster: Monster):
	const TICKS_PER_DAY = Clock.TICKS_IN_HOUR * Clock.HOURS_IN_DAY # 288
	var metabolic_rate: = U.div(monster.get_bmr(), TICKS_PER_DAY)
	# TODO: centralize this data, it's duplicated in `Monster.metabolize`
	var base = 1.1 - 1.0
	var asleep = 3.0 - 0.8
	return metabolic_rate * (asleep - base)

static func calc_duration(monster: Monster):
	var energy_needed = minf(
		monster.target_energy - monster.energy,
		monster.available_energy(true)
	)
	var dur_needed = energy_needed / energy_per_tick(monster)
	return clamp(dur_needed, min_dur, max_dur)
