class_name MoveAction
extends Action
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
const FORCE_MULTIPLIER: float = 3
# modifies the speed of the walk animation.
# walk animation FPS should be tuned around the "standard" input speed of 1.
# we then use the input speed to modify the speed of the animation, so if the
# speed is 2, the animation would play about twice as fast.
# that looks bad, so we use a <1 exponent to dampen the scaling - instead of
# twice as fast, the animation will play 1.5 times as fast with a speed of 2.
const FPS_COEFFICIENT = 0.6

var dest: Vector2
# a multiplier for how fast we should move, relative to "normal" speed (1).
var speed: float = 1
# how far from the target we want to approach to.
# typically we want to be right on top of the target, but for some advanced
# actions like games or "observe", we want to maintain some distance.
var target_distance: float
var path: Array

# the position of the monster when we last spent energy (ie, last tick).
# `spend_energy` calculates the energy cost to move from here to the monster's
# current position, then updates `last_pos`.
@onready var last_pos: Vector2 = m.position

# DEBUG DEBUG
var running_calories = 0
var estimated = 0

# options: speed, target_distance, timeout
func _init(monster: Monster, destination: Vector2, options: Dictionary = {}):
	super(monster, options.get('timeout'))
	last_pos = m.position
	name = 'move'
	dest = destination
	speed = options.get('speed', 1.0)
	assert(speed > 0, "move speed multiplier must be greater than 0")
	target_distance = options.get('target_distance', m.data.size)
	estimated = estimate_energy()


#                    u t i l i t y   c a l c u l a t i o n                    #
# --------------------------------------------------------------------------- #

func estimate_energy() -> float:
	# ask the navigation server for a path to the destination so we can estimate
	# how far we actually have to travel.  we can't use the monster's nav agent
	# because it's not actually performing the action yet, only considering it.
	var map = m.nav.get_navigation_map()
	var est_path = NavigationServer2D.map_get_path(map, m.position, dest, true)
	var distance = 0
	for i in est_path.size() - 1:
		distance += (est_path[i] as Vector2).distance_to(est_path[i + 1])
	return -calc_energy_cost(distance)


#                              e x e c u t i o n                              #
# --------------------------------------------------------------------------- #

func _start():
	m.nav.target_desired_distance = target_distance
	m.nav.set_target_position(dest)
	# nav agent with object avoidance fires a signal when it's done calculating
	# the "safe" velocity.  this happens at the end of the physics process, so
	# we can call `move_and_slide` in the handler
	# nav.velocity_computed.connect(move)
	# TODO: include the vigor modifier here
	m.play_anim(Monster.Anim.WALK, speed ** FPS_COEFFICIENT)

# --------------------------------------------------------------------------- #

func _exit(_status):
	spend_energy()
	m.play_anim(Monster.Anim.IDLE)

# --------------------------------------------------------------------------- #

func _tick(): spend_energy()

# --------------------------------------------------------------------------- #

# on proc (physics process), do all the movement stuff
func _proc(_delta):
	# note: this seems to work better with `target_desired_distance` than
	# `NavigationAgent2D.is_navigation_finished`
	if m.nav.is_target_reached():
		exit(Status.SUCCESS)
		Log.debug(self, [m.id,
			' total cal: ', String.num(running_calories, 2),
			' | estimated: ', String.num(estimated, 2),
			' | ratio: ', String.num(running_calories / estimated, 2)])
		return
	
	var target = m.nav.get_next_path_position()

	m.desired_velocity = (target - m.position).normalized() * calc_force()
	var steering = m.desired_velocity - m.velocity
	var acceleration: Vector2 = steering / m.mass
	m.velocity = m.velocity + acceleration
	
	# grabber and grabbee are treated as a single RigidBody, so we can apply the
	# force to either to create movement.  applying it to the grabbee causes the
	# attached bodies to align in the direction of movement with the grabbee in
	# front, provided that the force is sufficient to swing it around.
	if m.is_grabbing():
		m.grabbed.apply_central_force(m.velocity)
		m.orientation = m.vec_to_grabbed().normalized()
	else:
		m.apply_central_force(m.velocity)
		m.orientation = m.linear_velocity.normalized()


#                                  u t i l s                                  #
# --------------------------------------------------------------------------- #

# returns the amount of force required to move the monster at the desired speed.
# this is measured in "newtons" (kg * m/s²)
func calc_force() -> float:
	return (
		FORCE_MULTIPLIER
		* ProjectSettings.get_setting('physics/2d/default_linear_damp')
		* m.mass
		# "normal" speed actually varies based on the monster's size; larger
		# monsters move faster than smaller ones when walking at the same pace.
		* m.size
		# a monster's vigor attribute modifies its move speed;
		# we include it here so it will be applied consistently.
		* m.attributes.vigor.lerp(0.5, 2.0)
		# ^ the above is the force required to move the monster at its "normal"
		# speed (a relaxed walk).
		# finally, we add in the speed multiplier for this move action.
		* speed
	)

# --------------------------------------------------------------------------- #

# calculate work done in kcals to move the monster over a given distance at the
# current speed.
func calc_energy_cost(distance: float) -> float:
	var distance_in_meters = distance #/ Constants.PIXELS_PER_METER
	var work_in_joules = calc_force() * distance_in_meters
	return work_in_joules / Constants.JOULES_PER_KCAL

# --------------------------------------------------------------------------- #

# calculates the energy spent in moving from the last stored position to the
# current one, removes it from the monster, and updates the stored position for
# next time.  runs once per tick, and once on exit.
func spend_energy() -> void:
	if last_pos == null or last_pos == Vector2(0, 0):
		last_pos = m.position
		return
	var distance = m.position.distance_to(last_pos)
	var kcal_spent = calc_energy_cost(distance)
	last_pos = m.position
	# debug
	running_calories -= kcal_spent
	m.update_energy(-kcal_spent)
