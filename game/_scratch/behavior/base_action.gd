# class BaseAction

var Status = Constants.ActionStatus

# todo: see if this works
var id setget , 'get_instance_ID'

func _init():
	initialize()

func initialize(): pass
	# todo: see if we can call parent initialize in subclasses 
	# or if we have to put uuid generation in a new function
	# id = get_instance_ID()

func execute(tick):
	_enter(tick)
	
	if !tick.blackboard.get('is_open', tick.tree.id, id):
		_open(tick)
	
	var status = _tick(tick)
	
	if status != Status.RUNNING:
		_close(tick)
	
	_exit(tick)
	return status

func _enter(tick):
	tick.enter_action(self)
	enter(tick)

func _open(tick):
	tick.open_action(self)
	open(tick)

func _tick(tick): 
	tick.tick_action(self)
	tick(tick)

func _close(tick): 
	tick.close_action(self)
	close(tick)

func _exit(tick): 
	tick.exit_action(self)
	exit(tick)

# override these in action impls
func enter(): pass
func open(): pass
func tick(): pass
func close(): pass
func exit(): pass

func set(tick, key, val):
	tick.set(key, val, self.id)

func get(tick, key):
	return tick.get(key, self.id)