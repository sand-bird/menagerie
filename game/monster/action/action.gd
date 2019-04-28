extends Node

class_name Action

class Base:
	const Status = Constants.ActionStatus

	var sleep_timer: int = 0
	var status = Status.NEW
	var monster

	func _init(monster):
		self.monster = monster

	func tick():
		if status == Status.NEW:
			_open()
		if sleep_timer:
			sleep_timer -= 1
		else:
			return _tick()

	func exit(exit_status):
		status = exit_status
		return status

	func _open(): pass
	func _tick(): pass

	# sleep for a certain number of ticks
	func sleep(duration):
		if duration > 0:
			sleep_timer = duration

# -----------------------------------------------------------

class Walk extends Base:
	var destination: Vector2
	var path: Array

	func _init(monster, destination).(monster):
		self.destination = destination

	func _open():
		calc_path()

	func _tick():
		calc_path()
		if should_advance_path():
			if path.size() <= 1:
				return exit(Status.SUCCESS)
			path.pop_front()
		seek(path.front())

	func should_advance_path():
		return monster.get_pos().distance_squared_to(
				path.front()) < 16

	func seek(target: Vector2):
		var desired_velocity = (monster.get_pos() - target
				).normalized() * monster.max_speed
		var steering = desired_velocity - monster.velocity
		return steering

	func calc_path():
		path = monster.garden.calc_path(
			monster.get_pos(), destination
		)

# -----------------------------------------------------------

class Wander extends Base:
	func _open():
		pick_destination()

	func pick_destination():
		randomize()
		var direction = Vector2(
			rand_range(-1, 1),
			rand_range(-1, 1)
		)
		var distance = rand_range(80, 200)
		var dest = (direction * distance) + monster.get_pos()
		return dest
