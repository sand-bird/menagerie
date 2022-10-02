extends Action
class_name MoveAction

"""
seek a position vector via boids steering behavior.

steering_force = truncate (steering_direction, max_force)
acceleration = steering_force / mass
velocity = truncate (velocity + acceleration, max_speed)
position = position + velocity

"""

# success when dest is reached
# fail on timeout

var dest: Vector2
var speed: float
var path: Array


func _init(m, d: Vector2, s: float, t = null).(m, t):
	name = 'move'
	dest = d
	speed = s

# moving costs a variable amount of energy per tick depending on speed;
# it costs more energy to move faster over the same amount of ground.
#
# when we estimate the cost of the action, our information is incomplete:
# we do not know how many ticks it will take, or even how much distance the
# actual path will cover; we only know the distance to the destination as the
# crow flies.
#
# we can figure this out later. for now just return a flat number.
func estimate_result():
	return { energy = -10.0 }

# --------------------------------------------------------------------------- #

func _start():
	path = calc_path()
	m.play_anim(Constants.Anim.WALK, speed)

func _tick():
	return { energy = -1.0 * speed }


func _proc(delta):
	path = calc_path()
	if reached_dest():
		exit(Status.SUCCESS)
		return
	if should_advance_path():
		path.pop_front()

	var steering = seek(path.front())
	var acceleration = steering / m.mass
	m.current_velocity = (m.current_velocity + acceleration)
	var _collision = m.move_and_slide(m.current_velocity / delta)

# --------------------------------------------------------------------------- #

func should_advance_path():
	return m.position.distance_squared_to(path.front()) < 5


func reached_dest():
	return !path.back() or m.position.distance_squared_to(path.back()) < 5


func seek(target):
	var desired_velocity = (target - m.position).normalized() * speed
	m.desired_velocity = desired_velocity
	m.orientation = m.current_velocity.normalized()

	var steering = desired_velocity - m.current_velocity
	return steering


func calc_path():
	return m.garden.calc_path(m.position, dest)
