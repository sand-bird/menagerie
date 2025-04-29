extends ControlState

var commanding: Monster

func _init(monster: Monster):
	commanding = monster
	super()
