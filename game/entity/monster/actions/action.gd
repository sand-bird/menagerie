class_name Action
extends RefCounted
"""
basic behavior tree style action.  has two active methods, `proc` and `tick`.
the former runs on the physics clock, and the latter runs every in-game tick.

all actions have, at minimum, a reference to the monster performing the action
and a timeout value (to avoid infinite loops).  action subclasses often take in
addition parameters like a target.

many actions have prerequisites - eg, for a monster to eat an item it must be
grabbing that item, and for it to grab an item it must be in close proximity to
it.  each prerequisite is associated with another action that can accomplish it;
if the prerequisite is not met, we initialize that action as our `prereq` and
delegate execution to it until it succeeds.
"""

signal exited(status)

enum Status {
	NEW = 0,
	RUNNING = 1,
	SUCCESS = 2,
	FAILED = 3,
	PAUSED = 4
}

# directory for action scripts, used in `Action.deserialize` to dynamically
# determine which Action subclass to use when deserializing an action.
# this should be equivalent to `get_script().resource_path.get_base_dir()`,
# but it needs to behardcoded because `Action.deserialize` is a static method.
const SCRIPT_PATH = "res://entity/monster/actions"
# set on `_init` in the base Action (ie here) to the action's script's filename.
# this determines which script to use when deserializing a saved action.
var name: StringName = &'action'

# reference to the monster running the action
var m: Monster

# sugar for `target`, which is declared on subclasses which use a target.
# all targets should be of type Entity, but some actions target a specific
# subclass of Entity (eg Monster).
var t: Entity = null:
	set(new): if &'target' in self: self.target = new
	get(): return self.get(&'target')

var status := Status.NEW
# time remaining, decremented every tick. when this hits 0 we call _timeout().
var timeout: int = Clock.TICKS_IN_HOUR * 3
# real milliseconds (not ticks) during which the action is paused, set with
# sleep(). not sure if we'll ever actually need this.
var sleep_timer: float = 0
# another action which must succeed before this action can continue running.
# if this is nonnull, we delegate execution to it in `tick` and `proc`.
var prereq: Action = null:
	set(action):
		prereq = action
		if action is Action: action.exited.connect(func(_status):
			var _name = str(prereq.name) if prereq else '(none)'
			Log.debug(self, [
				'prereq exited: ', _name, ' | status: ', _status])
			_on_prereq_exit(_status, _name)
			prereq = null
		)


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

# keys to save & load for *all* actions.
# calling `save_keys` (no leading underscore) on an Action subclass combines
# its own `_save_keys`, if any, with those of its parent class(es).
static func _save_keys() -> Array[StringName]:
	return [&'name', &'status', &'timeout', &'sleep_timer', &'prereq']

func _init(monster, options = {}):
	m = monster
	name = get_script().resource_path.get_basename().get_file()
	for key in save_keys():
		U.deserialize_value(self, options.get(key), key)

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

func load_prereq(input):
	if input: prereq = Action.deserialize(m, input)

# not all actions have targets, but enough of them do that we implement the
# loader here so we don't have to repeat it in a bunch of different actions
func load_target(input):
	if !input or !input.uuid: return
	if input is Entity: t = input
	elif input is Dictionary:
		t = m.garden.get_node('entities'.path_join(input.uuid))


# =========================================================================== #
#                           R E Q U I R E M E N T S                           #
# --------------------------------------------------------------------------- #

# a convenience function for requirements, used to build `require_x` functions
# in actions with slightly less boilerplate.  calls the `on_failure` callback
# if the condition is false, then returns the condition, so that the function
# can be used as in `if require_whatever(): do_thing()`.  the callback performs
# some side effect, generally creating an action and assigning it to `prereq`.
static func require(condition: bool, on_failure: Callable) -> bool:
	if !condition: on_failure.call()
	return condition

# --------------------------------------------------------------------------- #

func require_target() -> bool:
	return require(!!t, func(): exit(Status.FAILED))


# =========================================================================== #
#                    U T I L I T Y   C A L C U L A T I O N                    #
# --------------------------------------------------------------------------- #
# methods to help a monster figure out the utility value of the action, via the
# static Decider class. called after an action is instantiated but before it is
# run. these are implemented by the base action with default values, and can be
# reimplemented by subclasses as needed.

const DRIVES = [&'belly', &'energy', &'social', &'mood']

# public method called by the Decider.  combines intrinsic drive estimates with
# those of the prerequisite action, if one is set.
func estimate_drive(drive: StringName) -> float:
	if not drive in DRIVES:
		Log.error(self, ['called `estimate_drive` with an invalid drive: ', drive])
		return 0
	return call(str('estimate_', drive)) + (
		prereq.estimate_drive(drive) if prereq is Action else 0.0
	)

#                               a b s t r a c t                               #
# --------------------------------------------------------------------------- #

# methods to return an estimate of the action's effect on each of the monster's
# drives, to be overridden by action subclasses as needed.
# should return the amount by which the action is expected to change the drive
# (positive for an increase, negative for a decrease).
func estimate_mood() -> float: return 0
func estimate_belly() -> float: return 0
func estimate_energy() -> float: return 0
func estimate_social() -> float: return 0

# takes in the utility value calculated by the Decider based on the output of
# the `estimate_{drive}` functions above, and returns a new utility value.
# can be used to modify the calculated utility value or simply override it. 
func mod_utility(utility: float): return utility


# =========================================================================== #
#                              E X E C U T I O N                              #
# --------------------------------------------------------------------------- #
# lifecycle methods shared by all actions.
# these are the public methods and should NOT overridden by action subclasses.

func start() -> void:
	Log.verbose(self, ['(start) timeout: ', timeout])
	status = Status.RUNNING
	_start()

# --------------------------------------------------------------------------- #

func unpause() -> void:
	Log.verbose(self, ['(unpause) timeout: ', timeout])
	status = Status.RUNNING
	_unpause()

# --------------------------------------------------------------------------- #

func proc(delta: float) -> void:
	# handle sleep first
	if sleep_timer > 0:
		sleep_timer -= delta
		return
	
	if status == Status.NEW: start()
	if status == Status.PAUSED: unpause()
	if status != Status.RUNNING: return
	# if we have a prerequisite, run that instead
	if prereq: prereq.proc(delta)
	else: _proc(delta)

# --------------------------------------------------------------------------- #

func tick() -> void:
	if status == Status.NEW: start()
	if status == Status.PAUSED: unpause()
	if status != Status.RUNNING: return
	# count down the timer while running (even if we're running a prereq).
	timeout -= 1
	if timeout <= 0: _timeout()
	elif prereq: prereq.tick()
	else: _tick()

# --------------------------------------------------------------------------- #

func exit(exit_status: Status) -> void:
	status = exit_status
	_exit(status)
	prereq = null
	Log.verbose(self, ['(exit) status: ', status])
	exited.emit(status)

# --------------------------------------------------------------------------- #

# sleep for a certain number of ticks
func sleep(duration) -> void:
	if duration > 0:
		sleep_timer = duration


#                               a b s t r a c t                               #
# --------------------------------------------------------------------------- #
# internal methods called by top-level execution above.
# these should be implemented by subclasses.

func _start(): pass
func _unpause(): _start()
func _tick() -> void: pass
func _proc(_delta): pass

# behavior when the timeout expires. all actions need a timeout to prevent
# infinite loops. by default the action fails, but this can be overridden by
# subclasses.
func _timeout(): exit(Status.FAILED)

# called on exit.  this allows actions to update drives (with changes since the
# last tick or with any changes that depend on the outcome of the action),
# and to perform any necessary cleanup (eg, resetting animations).
func _exit(_status: Status) -> void: pass

func _on_prereq_exit(_status: Status, _name: StringName) -> void: pass

# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

# generate the full list of save keys for an action by recursively calling
# the static `_save_keys` function for every class in our inheritance hierarchy.
# eg, for an ApproachAction, it will append `ApproachAction._save_keys`, then
# `MoveAction._save_keys`, then `Action._save_keys` to the returned array.
func save_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	var script = get_script()
	while script != null:
		# `Script.has_method` only returns true if the method is defined in that
		# specific script, not in any superclasses, whereas `'method' in Object`
		# also returns true if the method comes from a superclass.  we need the
		# former for this since we're iterating up a class tree, so let's hope
		# future godot versions don't break it.
		if script.has_method(&'_save_keys'):
			keys.append_array(script._save_keys())
		script = script.get_base_script()
	return keys

# --------------------------------------------------------------------------- #

func serialize() -> Dictionary:
	var serialized = {}
	for key in save_keys():
		serialized[key] = U.serialize_value(get(key), key)
	return serialized

# --------------------------------------------------------------------------- #

# action deserialization is somewhat unusual because we must identify the right
# Action subclass from the `name` property in `input` before we can initialize
# the action.  thus this is a static function that returns a new Action, rather
# than a class method like other `deserialize` functions.
# (TODO: maybe come up with a different name for this?? the discrepancy is gonna
# be hella confusing like 2 years from now)
static func deserialize(monster: Monster, input: Dictionary) -> Action:
	assert(&'name' in input, str("cannot load an action without a name: ", input))
	var action_path = SCRIPT_PATH.path_join(input.name + ".gd")
	var script = load(action_path)
	# old method: subclasses with required params had to implement a static
	# `_deserialize` function which takes (monster, input) and returns a new
	# instance of that class. this required `parse_x` methods to deserialize
	# constructor params, eg target. 
#	for key in input:
#		var parse_fn = str('parse_', key)
#		if parse_fn in script:
#			input[key] = script.call(parse_fn, input[key], monster)
#	var action: Action = (
#		script._deserialize(monster, input) if &'_deserialize' in script
#		else script.new(monster, input)
#	)
#	for key in action.save_keys():
#		U.deserialize_value(action, input.get(key), key)
#	return action
	return script.new(monster, input)
