class_name Action

class Base:
	var monster: Monster

	func _init(monster):
		self.monster = monster

class Wander:
	func _init(monster):
		._init()

class Walk extends Base:
	func _init(monster):
		# Called every time the node is added to the scene.
		# Initialization here
		._init()

	func open():
		pass
