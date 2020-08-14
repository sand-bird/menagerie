extends Node

class_name Action

class Base:
	var action_id = 'base'
	var Status = Constants.ActionStatus

	var sleep_timer: int = 0
	var status = Status.NEW
	var monster

	func _init(monster):
		self.monster = monster

	func tick():
		if status == Status.NEW:
			open()
		if sleep_timer:
			sleep_timer -= 1
		else:
			_tick()
			return status

	func open():
		status = Status.RUNNING
		_open()

	func exit(exit_status):
		status = exit_status
		return status

	func _open(): pass
	func _tick(): pass

	# sleep for a certain number of ticks
	func sleep(duration):
		if duration > 0:
			sleep_timer = duration

# --------------------------------------------------------------------------- #

class Walk extends Base:
	var destination: Vector2
	var path: Array
	var energy_cost = -0.05

	func _init(monster, destination).(monster):
		action_id = 'walk'
		self.destination = destination

	func _open():
		path = calc_path()
		monster.play_anim(Constants.Anim.WALK)
		monster.get_node('sprite/anim').set_speed_scale(2.0)

	func _tick():
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
		monster.orientation = monster.current_velocity
		monster.position += monster.current_velocity

	func should_advance_path():
		return monster.get_position().distance_squared_to(
				path.front()) < 25

	func seek(target):
		var desired_velocity = (target - monster.get_position()
			).normalized() * monster.max_velocity
		monster.desired_velocity = desired_velocity

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
		pass

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

class Sleep extends Base:
	var duration
	var duration_remaining
	var energy_cost = 0.1

	func _init(monster, duration).(monster):
		action_id = 'sleep'
		self.duration = duration
		self.duration_remaining = duration

	func _open():
		monster.play_anim('lie_down')
		monster.queue_anim('sleep')
		pass

	func _tick():
		duration_remaining -= 1
		if duration_remaining <= 0:
			return exit(Status.SUCCESS)
		else:
			return Status.RUNNING
