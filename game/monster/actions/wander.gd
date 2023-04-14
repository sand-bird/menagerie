extends Action
class_name WanderAction
"""
repeatedly picks and moves to a destination a short distance away until the
duration runs out.
"""

const min_dur = 1 * Clock.TICKS_IN_HOUR
const max_dur = 6 * Clock.TICKS_IN_HOUR

var move_action: MoveAction
# ticks to wait between move actions
var wait_counter = 0

# TODO: allow speed to be passed in here
func _init(m, t = null):
	super(m)
	name = 'wander'
	if !t: t = Utils.randi_range(min_dur, max_dur)
	super._init(m, t)

func estimate_result():
	return { energy = -0.2 * t }

func _start():
	m.announce('is wandering around.')
	new_move()

func _tick():
	if move_action:
		return move_action.tick()
	elif wait_counter > 0:
		wait_counter -= 1
	else:
		new_move()

func _proc(delta):
	if move_action: move_action.proc(delta)

func _timeout():
	if move_action: cleanup_move()
	exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

func new_move():
	var dest = pick_dest()
	move_action = MoveAction.new(m, dest, 0.6, min_dur)
	move_action.connect('exit', Callable(self, '_on_move_exit'))

func pick_dest():
	randomize()
	var direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	)
	var distance = randf_range(40, 60)
	return (direction * distance) + m.get_pos()

func cleanup_move():
	move_action.disconnect('exit', Callable(self, '_on_move_exit'))
	move_action.queue_free()
	move_action = null
	m.play_anim('idle')

func _on_move_exit(status):
	cleanup_move()
	wait_counter = Utils.randi_range(0, 5)
