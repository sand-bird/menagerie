class_name Decider
extends Node
const LNAME = 'Decider'
"""
logic to choose which action to perform next. here's how it should work:

1. poll sources in range.  sources are other monsters, items, objects, games,
   and self.  these tell us which specific, parameterized actions are available.
   eg, there are two different food items in range: each of these will advertise
   valid item actions like eat, pick up, move, bury, etc.  a monster will pick
   one action to perform on one item.
   
2. sources advertise drive updates according to a function that depends on the
   monster, the target, and the action.  all actions should implement this.
   for each possible action on each source, the decider calls the function with
   the monster and target.
   - eg, if the action involves moving to the target, estimate the energy cost.
   - take into account monster preferences for or against the action or target.
	 this should affect the advertised mood gain/loss.
   - attribute example: the mood gain from bullying another monster (eg, stealing an
	 item) depends on the monster's kindness attribute, their preference toward the
	 target, and their preference toward stealing.

3. now we have a list of drive updates associated with potential actions.
   a general function chooses one of those based on the monster's current drives
   and attributes.
   - eg, a monster is kind but starving.  there is one other monster and it has
	 the only food.  this function should weigh the mood hit from stealing
	 against the belly gain from eating the food.
   - the utility calculation should not be perfect.  eg, monsters may only
	 compare a subset of possible actions.
   - the utility of different drive updates should be modified by the monster's
	 attributes.  eg, a high pep monster should put greater weight on actions that
	 reduce energy.

4. when a monster is engaged in an action, it stops polling for sources, but it
   still listens for interrupts.  an interrupt is an event that advertises an
   action (an "active" source vs a passive source) - eg, another monster starts
   a game.  the monster compares the utility of the advertised action against
   its current action, and may decide to cancel or postpone the current action
   in favor of the advertised action.
"""

# actions advertised by the monster itself.  these are always available.
static func self_actions(m) -> Array[Action]:
	return [
		WanderAction.new(m), 
		SleepAction.new(m),
		IdleAction.new(m)
	]

# --------------------------------------------------------------------------- #

# polls the sources around the monster for possible actions.  returns a list of
# possible actions.
static func poll_sources(m: Monster) -> Array[Action]:
	var actions: Array[Action] = []

	# Area2D's list of overlapping bodies refreshes on physics frames,
	# so we need to await one to make sure it's up to date
	await m.get_tree().physics_frame
	var bodies: Array[Node2D] = m.perception.get_overlapping_bodies()
	var entities: Array[Entity] = []
	entities.assign(
		bodies.filter(func (b): return b != m and b is Entity)
	)
	for entity in entities:
		actions.append_array(entity.get_actions(m))
	
	actions.append_array(self_actions(m))
	return actions

# --------------------------------------------------------------------------- #

# calculates the utility of a delta value by computing the change it would
# cause to the "desired delta", the difference between the current value and
# target value.  deltas the reduce the "desired delta" have positive utility.
static func diff_efficiency(
	delta: float, target_value: float, current_value: float, capacity: float
) -> float:
	var desired_delta := target_value - current_value
	# alternately, new_desired_delta = target_value - (current_value + delta)
	var new_desired_delta := desired_delta - delta
	# improvement is the difference in length between the old and new desired
	# delta, regardless of direction.  if the new desired delta is longer,
	# improvement (thus utility) is negative, and vice versa.
	var improvement := absf(desired_delta) - absf(new_desired_delta)
	# length of the desired delta relative to total capacity represents the
	# urgency of the desire.  use this to scale the utility result so that
	# improvements to more urgent drives have relatively greater utility.
	var urgency := desired_delta / capacity
	var scale = 2 ** lerpf(-1, 1, urgency) # poor man's Attribute.modify
	# utility of a delta is relative to total capacity of the drive
	return (improvement / capacity) * scale

# --------------------------------------------------------------------------- #

# calculates the utility of an action for the given monster by comparing the
# result of the action's `calc_effect` against the monster's current drives.
# note: we don't explicitly prevent actions that would deplete more of a drive
# than the monster already has; the utility calculation should ensure those
# actions almost never get chosen.
static func calc_utility(m: Monster, action: Action, log: bool):
	var utility: float = 0
	if log: print(action.name, ' (', action.timer, ')')
	for drive in Action.DRIVES:
		var delta := action.estimate_drive(drive)
		var current: float = m.get(drive)
		var max: float = m.get(str(drive, '_capacity'))
		var target: float = m.get(str('target_', drive))
		var drive_utility := diff_efficiency(delta, target, current, max)
		if !is_zero_approx(delta):
			if log: print('\t', drive,
				' | delta: ', String.num(delta, 4),
				' | utility: ', String.num(drive_utility, 4)
			)
		utility += drive_utility
	
	# TODO: if the monster previously attempted the same action with the same
	# target and it failed, add a utility penalty (-0.5)
	
	if log: print('\tutility: ', String.num(utility, 4))
	return action.mod_utility(utility)

# --------------------------------------------------------------------------- #

static func choose_action(m: Monster, log: bool = false):
	var actions = await poll_sources(m)
	if log: print('\n===== (choose_action) ', m.id, ' ', m.monster_name, ' =====')
	if log: print('belly: ', String.num(m.belly, 2), ' / ', String.num(m.belly_capacity, 2),
		' (', String.num(100.0 * m.belly / m.belly_capacity, 1), '%)',
		' | energy: ', String.num(m.energy, 2), ' / ', String.num(m.energy_capacity, 2),
		' (', String.num(100.0 * m.energy / m.energy_capacity, 1), '%)',
		' t. ', String.num(100.0 * m.target_energy / m.energy_capacity, 1), '%'
	)
	var best_utility = -INF
	var best_action = actions[0]
	for action in actions:
		var utility = calc_utility(m, action, log)
		# if the monster has already attempted this action on the same target and
		# it failed, cut the action's utility so it's less likely to keep trying.
		var has_failed = m.past_actions.any(
			func(past_action: Dictionary): return (
				past_action.name == action.name
				# not all actions have targets, but if the name matches and the
				# prospective action has a target, the past action should also
				and (!action.t or past_action.target.uuid == action.t.uuid)
				and past_action.status == Action.Status.FAILED
		))
		if has_failed: utility /= 2.0

		if utility > best_utility:
			best_utility = utility
			best_action = action
		# exit early if we find a really good one
	
	if log: print('^^^^^^^^^ selected: ', best_action.name, ' ^^^^^^^^^\n')
	return best_action
