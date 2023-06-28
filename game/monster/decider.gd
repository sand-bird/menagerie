extends Node
class_name Decider
const log_name = 'Decider'
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
   - trait example: the mood gain from bullying another monster (eg, stealing an
	 item) depends on the monster's kindness trait, their preference toward the
	 target, and their preference toward stealing.

3. now we have a list of drive updates associated with potential actions.
   a general function chooses one of those based on the monster's current drives
   and traits.
   - eg, a monster is kind but starving.  there is one other monster and it has
	 the only food.  this function should weigh the mood hit from stealing
	 against the belly gain from eating the food.
   - the utility calculation should not be perfect.  eg, monsters may only
	 compare a subset of possible actions.
   - the utility of different drive updates should be modified by the monster's
	 traits.  eg, a high pep monster should put greater weight on actions that
	 reduce energy.

4. when a monster is engaged in an action, it stops polling for sources, but it
   still listens for interrupts.  an interrupt is an event that advertises an
   action (an "active" source vs a passive source) - eg, another monster starts
   a game.  the monster compares the utility of the advertised action against
   its current action, and may decide to cancel or postpone the current action
   in favor of the advertised action.
"""

# actions advertised by the monster itself.  these are always available.
static func self_actions(m):
	return [
		WanderAction.new(m), 
#		SleepAction.new(m),
		IdleAction.new(m)
	]

# --------------------------------------------------------------------------- #

# polls the sources around the monster for possible actions.  returns a list of
# possible actions.
static func poll_sources(m):
	var actions = []
	# access the garden through the monster reference and get all sources within
	# a radius of the monster.
	# a source is, i guess, anything that implements `get_actions(monster)`.
	
	actions.append_array(self_actions(m))
	return actions

static func diff_efficiency(desired, delta, total):
	return 1.0 - (abs(desired - delta) / total)

# --------------------------------------------------------------------------- #

# calculates the utility of an action for the given monster by comparing the
# result of the action's `calc_effect` against the monster's current drives.
static func calc_utility(m, action):
	var effect = action.estimate_result()
	var desired_energy = m.get_target_energy() - m.energy
	var utility = diff_efficiency(desired_energy, effect.get('energy', 0.0), m.MAX_ENERGY)
	Log.info(log_name, ['(calc_utility) action: ', action, ' for ', action.t, ' ticks | monster: ', m, ' | utility: ', utility])
	return action.mod_utility(utility)

# --------------------------------------------------------------------------- #

static func choose_action(m):
	var actions = poll_sources(m)
	print('actions: ', actions)
	
	var best_utility = 0
	var best_action = actions[0]
	for action in actions:
		var utility = calc_utility(m, action)
		if utility > best_utility:
			best_utility = utility
			best_action = action
		# exit early if we find a really good one
	
	return best_action

# --------------------------------------------------------------------------- #
"""
func old_calc(m):
	randomize()
	var target_energy = m.get_target_energy()

	if m.energy < target_energy and randf() > m.energy / 100.0:
		var energy_per_tick = float(Action.energy_values.sleep) / float(Clock.TICKS_IN_HOUR)
		var energy_to_recover = Utils.randi_range(target_energy, 100) - m.energy
		var sleep_time = energy_to_recover / energy_per_tick
		
		Log.debug(m, ['going to sleep! energy to recover: ', energy_to_recover,
			' | sleep time: ', sleep_time])
		m.current_action = Action.Sleep.new(m,
			clamp(sleep_time, Clock.TICKS_IN_HOUR, Clock.TICKS_IN_HOUR * 8))
	
	elif randf() > m.traits.pep:
		m.current_action = Action.Idle.new(m, Utils.randi_range(2, 8))
	else:
		m.current_action = Action.Walk.new(m, # so ugly :(
			m.position + Vector2(randf_range(-80, 80), randf_range(-80, 80)))

	Log.debug(m, ["chose action: ", m.current_action.action_id])
"""
