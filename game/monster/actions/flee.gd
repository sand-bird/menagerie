extends Action

# boids flee behavior from target
# success when duration runs out
# fail if reached by target

func _init(m, target, speed = null, t = null).(m, t):
	pass

func _timeout():
	exit(Status.SUCCESS)
