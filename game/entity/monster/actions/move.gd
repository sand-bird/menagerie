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
# input speed should be a float where 1 is a "normal" walking speed.
# this multipler allows us to tune the speed calculation to achieve this result.
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
	speed = _speed * m.attributes.vigor.lerp(0.5, 2.0)

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

func _tick():
	return { energy = -1.0 * speed }

# on proc (physics process), do all the movement stuff
func _proc(_delta):
	if nav.is_navigation_finished():
		Log.debug(self, 'nav finished')
		m.velocity = Vector2(0, 0)
		exit(Status.SUCCESS)
		return
	
	var target = nav.get_next_path_position()

	m.desired_velocity = (
		(target - m.position).normalized()
		* speed * MoveAction.calc_magnitude(m)
	)
	#m.velocity = m.desired_velocity
	var steering = m.desired_velocity - m.velocity
	var acceleration: Vector2 = steering / m.mass
	m.velocity = m.velocity + acceleration
	
#	m.apply_central_force(m.velocity)
	m.desired_orientation = m.linear_velocity.normalized()
#	m.joint.position = m.desired_orientation * (m.data.size)
#	m.joint.rotation = m.desired_orientation.angle() - (PI/2) # orientation.angle()
#	m.rotation = m.desired_orientation.angle() - (PI/2)
	
	if m.is_grabbing():
		m.grabbed.apply_central_force(m.velocity)
#		var curr_orientation = m.vec_to_grabbed().normalized()
#		m.drag = (m.desired_orientation - curr_orientation) / m.mass
#		m.grabbed.apply_force(m.drag)

		m.orientation = m.vec_to_grabbed().normalized()
	else:
		m.apply_central_force(m.velocity)
		m.orientation = m.desired_orientation

# --------------------------------------------------------------------------- #

# used for drawing debug raycasts in the monster script
static func calc_magnitude(monster: Monster) -> float:
	return (
		SPEED_MULTIPLIER
		* ProjectSettings.get_setting('physics/2d/default_linear_damp')
		* monster.data.mass * monster.data.size
	)
