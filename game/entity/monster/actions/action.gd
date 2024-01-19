class_name Action
extends Node
"""
basic behavior tree style action.  has two active methods, "proc" and "tick".
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

signal exited(status, drive_diff)

enum Status {
	NEW = 0,
	RUNNING = 1,
	SUCCESS = 2,
	FAILED = 3,
	PAUSED = 4
}

static func get_status(status_code):
	return ['new', 'running', 'success', 'failed'][status_code]

# reference to the monster running the action
var m: Monster
var status := Status.NEW
# time remaining, decremented every tick. when this hits 0 we call _timeout().
var timer: int = Clock.TICKS_IN_HOUR * 3
# real milliseconds (not ticks) during which the action is paused, set with
# sleep(). not sure if we'll ever actually need this.
var sleep_timer: float = 0
# if this is nonnull, we delegate implementation to it
var prereq: Action = null:
	set(action):
		prereq = action
		if action is Action: action.exited.connect(_on_prereq_exit)

# --------------------------------------------------------------------------- #

func _init(monster, timeout = null):
	m = monster
	if timeout != null: timer = timeout

# --------------------------------------------------------------------------- #

func _on_prereq_exit(_status: Status):
	Log.debug(self, ['prereq `', prereq.name, '` exited | status', _status])
	clean_up_prereq()

# --------------------------------------------------------------------------- #

func clean_up_prereq():
	if !prereq: return
	prereq.queue_free()
	prereq = null

# --------------------------------------------------------------------------- #

# a convenience function for requirements, used to build `require_x` functions
# in actions with slightly less boilerplate.  calls the `on_failure` callback
# if the condition is false, then returns the condition, so that the function
# can be used as in `if require_whatever(): do_thing()`.  the callback performs
# some side effect, generally creating an action and assigning it to `prereq`.
static func require(condition: bool, on_failure: Callable) -> bool:
	if !condition: on_failure.call()
	return condition

# =========================================================================== #
#                                U T I L I T Y                                #
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
	Log.verbose(self, ['(start) timeout: ', timer])
	status = Status.RUNNING
	_start()

# --------------------------------------------------------------------------- #

func unpause() -> void:
	Log.verbose(self, ['(unpause) timeout: ', timer])
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
	timer -= 1
	if timer <= 0: _timeout()
	elif prereq: prereq.tick()
	else: _tick()

# --------------------------------------------------------------------------- #

func exit(exit_status: Status) -> void:
	status = exit_status
	_exit(status)
	clean_up_prereq()
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

# called from public method start() when the action should start running
func _start(): pass

func _unpause(): _start()

# called each ingame tick
func _tick() -> void: pass

# called each process update
func _proc(_delta): pass

# behavior when the timeout expires. all actions need a timeout to prevent
# infinite loops. by default the action fails, but this can be overridden by
# subclasses.
func _timeout(): exit(Status.FAILED)

# called on exit.  this allows actions to update drives (with changes since the
# last tick or with any changes that depend on the outcome of the action),
# and to perform any necessary cleanup (eg, resetting animations).
func _exit(_status: Status) -> void: pass
