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

const SPEED_MULTIPLIER = 0.1

var dest: Vector2
var speed: float
var path: Array

var nav: NavigationAgent2D

func _init(m, d: Vector2, s: float, t = null):
	super(m, t)
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
	nav = m.get_node('nav')
	nav.set_target_position(dest)
	# nav agent with object avoidance fires a signal when it's done calculating
	# the "safe" velocity.  this happens at the end of the physics process, so
	# we can call `move_and_slide` in the handler
	nav.velocity_computed.connect(move)
#	m.play_anim(Constants.Anim.WALK, speed)

# on tick, report the current path for debugging
func _tick():
	path = nav.get_current_navigation_path()
	m.garden.get_node('path').points = path
	return { energy = -1.0 * speed }

# on proc (physics process), do all the movement stuff
func _proc(delta):
	if nav.is_navigation_finished():
		print('nav finished')
		m.velocity = Vector2(0, 0)
		exit(Status.SUCCESS)
		return
	
	var target = nav.get_next_path_position()
	# this initial desired velocity may be modified by the navigation agent if
	# it needs to alter our movement to avoid obstacles.  the actual desired
	# velocity is fired in the `velocity_computed` signal from the agent and
	# received by the `move` function below
	var desired_velocity = (target - m.position).normalized() * speed * SPEED_MULTIPLIER
	nav.set_velocity(desired_velocity)

# --------------------------------------------------------------------------- #

func move(desired_velocity):
	# monster orientation is used to choose a sprite/animation set
	m.orientation = desired_velocity.normalized()
	
#	m.velocity = desired_velocity
	var steering = desired_velocity - m.velocity
	var acceleration = steering / m.mass
	m.velocity = m.velocity + acceleration
	m.move_and_collide(m.velocity)
