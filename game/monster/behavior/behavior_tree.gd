# class BehaviorTree

var id
var root = null

func _init():
	id = generate_uuid()

func tick(target, blackboard):
	var tick = new Tick(target, blackboard, self)
	root.execute(tick)
	
	var last_open_actions = blackboard.get('open_actions', self.id)
	var curr_open_actions = tick.open_actions.slice(0) # ?
	
	var start = 0
	while start < min(last_open_actions.length, curr_open_actions.length)
			and last_open_actions[start] == curr_open_actions[start]:
		start += 1

#	for i in min(last_open_actions.length, curr_open_actions.length):
#		start = i + 1
#		if last_open_actions[i] != curr_open_actions[i]: break
	
	# todo: make this count backwards if we can
	for i in range(start, last_open_actions.length - 1):
		last_open_actions[i].close(tick)
	
	blackboard.set('open_actions', curr_open_actions, id)
	blackboard.set('action_count', tick.action_count, id)