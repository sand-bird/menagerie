tool
extends BaseButton

func _pressed():
	print("pressed: ", name)
	EventManager.emit_signal(name)
