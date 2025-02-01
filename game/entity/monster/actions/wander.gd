class_name WanderAction
extends Action
"""
repeatedly picks and moves to a destination a short distance away until the
duration runs out.
"""

const min_dur = 1 * Clock.TICKS_IN_HOUR
const max_dur = 6 * Clock.TICKS_IN_HOUR

var move_action: MoveAction
var move_speed: float
# ticks to wait between move actions
var wait_counter = 0

# options: duration, speed
func _init(monster: Monster, options: Dictionary = {}):
	super(monster, options.get('duration', randi_range(min_dur, max_dur)))
	move_speed = options.get('speed', 0.6)
	name = 'wander'


#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

# TODO: improve this calculation based on energy calcs in MoveAction (need to
# estimate roughly how far the monster will be moving based on duration)
func estimate_energy() -> float: return -0.2 * timer


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _start():
	m.announce('is wandering around.')
	new_move()

func _tick():
	if move_action: move_action.tick()
	elif wait_counter > 0: wait_counter -= 1
	else: new_move()

func _proc(delta):
	if move_action: move_action.proc(delta)

func _timeout():
	if move_action: cleanup_move()
	exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

func new_move():
	var dest = pick_dest()
	move_action = MoveAction.new(m, dest, {
		speed = move_speed, timeout = min_dur
	})
	move_action.exited.connect(_on_move_exit)

# --------------------------------------------------------------------------- #

func pick_dest():
	randomize()
	var direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	)
	var distance = randf_range(40, 60)
	return (direction * distance) + m.position

# --------------------------------------------------------------------------- #

func cleanup_move():
	move_action.exited.disconnect(_on_move_exit)
	move_action.queue_free()
	move_action = null
	m.play_anim(Monster.Anim.IDLE)

func _on_move_exit(_status):
	cleanup_move()
	wait_counter = randi_range(0, 5)
