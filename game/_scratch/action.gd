# class Action

signal done

var monster

var target
var time
var time_left

enum { WALK, WAIT }
enum State { RUNNING, FINISHED, INTERRUPTED }

func _init(duration):
	time = 0
	time_left = duration
#	print("started waiting with t=", duration)

func execute():
	time += 1
#	if (time % 100 == 0): print(time)
	if time == time_left:
#		print("finished waiting!")
		return State.FINISHED
		emit_signal("done")
	else: return State.RUNNING