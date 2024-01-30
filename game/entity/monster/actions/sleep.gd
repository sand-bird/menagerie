class_name SleepAction
extends Action
"""
sleep and recover energy.

this action calls `update_energy` on the monster every tick to restore a flat
percentage of the monster's energy (currently 1/200), modified by vigor.

monsters can also recover energy without sleeping by catabolizing food energy
(see `Monster.metabolize`).  currently, sleep energy recovery works separately
from and in addition to natural recovery, to ensure that sleeping can always
recover some energy so the monster is not trapped in a death loop.
"""

# must sleep at least an hour
const min_dur: int = 2 * Clock.TICKS_IN_HOUR
const max_dur: int = 24 * Clock.TICKS_IN_HOUR

# options: duration
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options.get('duration', calc_duration(monster)))
	name = 'sleep'

#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_energy() -> float:
	return float(timer) * energy_per_tick(m)

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
func _tick():
	m.update_energy(energy_per_tick(m))

func _timeout():
	exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

# TODO: take catabolism bonus into account; decide whether sleep energy recovery
# is handled in the sleep action or in the monster (via checking is_asleep)
static func energy_per_tick(monster: Monster) -> float:
	# same as `base_energy_recovery` in `Monster.metabolize`
	return monster.energy_capacity / 200.0

static func calc_duration(monster: Monster) -> int:
	var energy_needed := monster.target_energy - monster.energy
	var dur_needed := energy_needed / energy_per_tick(monster)
	return clampi(dur_needed, min_dur, max_dur)
