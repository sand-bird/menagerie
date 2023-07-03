extends Action
class_name MoveAction
"""
seek a position vector via boids steering behavior.

steering_force = truncate (steering_direction, max_force)
acceleration = steering_force / mass
velocity = truncate (velocity + acceleration, max_speed)
position = position + velocity
"""

# a magic number used to calculate desired velocity.
# input speed should be a 
const SPEED_MULTIPLIER: float = 3
# modifies the speed of the walk animation.
# walk animation FPS should be tuned around the "standard" input speed of 1.
# we then use the input speed to modify the speed of the animation, so if the
# speed is 2, the animation would play about twice as fast.
# that looks bad, so we use a <1 exponent to dampen the scaling - instead of
# twice as fast, the animation will play 1.5 times as fast with a speed of 2.
const FPS_COEFFICIENT = 0.6

# success when dest is reached
# fail on timeout

var dest: Vector2
var speed: float
var path: Array

var nav: NavigationAgent2D

func _init(_m, _dest: Vector2, _speed: float, _t = null):
	super(_m, _t)
	name = 'move'
	dest = _dest
	speed = _speed

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
	nav = m.nav
	nav.set_target_position(dest)
	# nav agent with object avoidance fires a signal when it's done calculating
	# the "safe" velocity.  this happens at the end of the physics process, so
	# we can call `move_and_slide` in the handler
	# nav.velocity_computed.connect(move)
	# TODO: include the vigor modifier here
	m.play_anim(Constants.Anim.WALK, speed ** FPS_COEFFICIENT)

# on tick, report the current path for debugging
func _tick():
	path = nav.get_current_navigation_path()
	m.garden.get_node('path').points = path
	return { energy = -1.0 * speed }

# on proc (physics process), do all the movement stuff
func _proc(_delta):
	if nav.is_navigation_finished():
		Log.debug(self, 'nav finished')
		m.velocity = Vector2(0, 0)
		exit(Status.SUCCESS)
		return
	
	var target = nav.get_next_path_position()
	# this initial desired velocity may be modified by the navigation agent if
	# it needs to alter our movement to avoid obstacles.  the actual desired
	# velocity is fired in the `velocity_computed` signal from the agent and
	# received by the `move` function below
	var desired_velocity = (
		(target - m.position).normalized()
		* speed * SPEED_MULTIPLIER
		* m.data.mass * m.data.size * m.attributes.vigor.lerp(0.8, 1.5)
	)
	# nav.set_velocity(desired_velocity)
	move(desired_velocity)

# --------------------------------------------------------------------------- #

func move(desired_velocity):
	# monster orientation is used to choose a sprite/animation set
	m.orientation = desired_velocity.normalized()
	
	m.velocity = desired_velocity
#	var steering = desired_velocity - m.velocity
#	var mass = m.data.size ** 1.5
#	var acceleration = steering / mass
#	m.desired_velocity = desired_velocity
#	m.velocity = m.velocity + acceleration
	# move_and_slide uses the monster's velocity value.  move_and_collide works
	# the same except it takes a velocity arg and multiplies it automatically.
	# we use move_and_slide mostly so we can specify our own multipliers.
#	m.move_and_collide(m.velocity)
	m.apply_central_force(m.velocity)
