extends Node

class_name Action

const energy_values = {
	sleep = 20,
	idle = 5,
	walk = -10,
	base = 0
}

# basic behavior tree style action. has two active methods, "proc" and "tick".
# the former runs on the physics clock, and the latter runs every in-game tick.
class Base:
	var action_id = 'base'
	var Status = Constants.ActionStatus
	var done = false

	var sleep_timer: int = 0
	var status = Status.NEW
	var monster
	var energy_value setget ,get_energy_value

	func get_energy_value():
		return energy_values[self.action_id]

	func _init(monster):
		self.monster = monster

	func open():
		status = Status.RUNNING
		_open()

	func proc(delta):
		if status == Status.NEW:
			open()
		if sleep_timer:
			sleep_timer -= 1
		else:
			_proc(delta)

	func tick():
		_tick()

	func exit(exit_status):
		status = exit_status
		done = true

	func _open(): pass
	func _proc(delta): pass
	func _tick(): pass

	# sleep for a certain number of ticks
	func sleep(duration):
		if duration > 0:
			sleep_timer = duration

# --------------------------------------------------------------------------- #

class Walk extends Base:
	var destination: Vector2
	var path: Array

	func _init(monster, destination).(monster):
		action_id = 'walk'
		self.destination = destination

	func _open():
		path = calc_path()
		monster.play_anim(Constants.Anim.WALK)
		# TODO: add speed scale to monster.play_anim api
		monster.get_node('sprite/anim').set_speed_scale(2.0)

	func _proc(_delta):
		#calc_path()
		if should_advance_path():
			if path.size() <= 1:
				return exit(Status.SUCCESS)
			path.pop_front()

		var steering = seek(path.front())
		var acceleration = steering / monster.mass
		monster.current_velocity = (
			monster.current_velocity + acceleration
		).clamped(monster.max_speed)

	func should_advance_path():
		return monster.get_position().distance_squared_to(
				path.front()) < 25

	func seek(target):
		var desired_velocity = (target - monster.get_position()
			).normalized() * monster.max_velocity
		monster.desired_velocity = desired_velocity
		monster.orientation = monster.current_velocity
		monster.position += monster.current_velocity

		var steering = desired_velocity - monster.current_velocity
		return steering

	# steering_force = truncate (steering_direction, max_force)
	# acceleration = steering_force / mass
	# velocity = truncate (velocity + acceleration, max_speed)
	# position = position + velocity

	func calc_path():
		return monster.garden.calc_path(
			monster.get_position(), destination
		)

# --------------------------------------------------------------------------- #

class Wander extends Base:
	var destination

	func _init(monster).(monster):
		action_id = 'wander'

	func _open():
		destination = pick_destination()

	func pick_destination():
		randomize()
		var direction = Vector2(
			rand_range(-1, 1),
			rand_range(-1, 1)
		)
		var distance = rand_range(80, 200)
		return (direction * distance) + monster.get_position()

# --------------------------------------------------------------------------- #

class Timed extends Base:
	# keep these both for now in case we need to look at total duration later.
	# (probably not actually necessary)
	var duration
	var duration_remaining

	func _init(monster, duration).(monster):
		self.duration = duration
		self.duration_remaining = duration

	func _tick():
		duration_remaining -= 1
		if duration_remaining <= 0:
			exit(Status.SUCCESS)

# --------------------------------------------------------------------------- #

class Sleep extends Timed:
	func _init(monster, duration).(monster, duration):
		action_id = 'sleep'

	func _open():
		monster.play_anim('lie_down')
		monster.queue_anim('sleep')

# --------------------------------------------------------------------------- #

class Idle extends Timed:
	func _init(monster, duration).(monster, duration):
		action_id = 'idle'

	func _open():
		monster.play_anim('idle')
