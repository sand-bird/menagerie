# class Tick

var tree = null
var open_actions = []
var action_count = 0
var debug = null
var target = null
var blackboard = null

func _init(target, blackboard, tree):
	self.target = target
	self.blackboard = blackboard
	self.tree = tree

func enter_action(action):
	action_count++
	open_actions.push(action)
	print("action entered: ", action)

func open_action(action):
	print("action opened: ", action)

func tick_action(action):
	print("action ticked: ", action)

func clode_action(action):
	print("action closed: ", action)
	openActions.pop()

func exit_action(action):
	print("action exited: ", action)

# for setting and getting from action nodes, so they don't
# have to reach through the tick to get to the blackboard

func set(key, value, action_id = null):
	blackboard.set(key, value, tree.id, action_id)

func get(key, action_id = null):
	return blackboard.get(key, tree.id, action_id)