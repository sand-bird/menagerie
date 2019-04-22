class_name Action

class Base:
	var monster: Monster

	func _init(monster):
		self.monster = monster

class Wander:
	func _init(monster, args):
		._init()

class Walk extends Base:
	var target

	func _init(monster).(target):
		self.target = target

	func open():
		pass
