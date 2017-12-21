# class BaseAction

var id
var children = []

func _init(children):
	initialize(children)

func initialize(children):
	id = generate_uuid()
	if (children):
		for child in children:
			self.children.push(child)
			# todo: test if loops by key or val

func execute(tick):
	_enter(tick)
	
	if !tick.blackboard.get('is_open', tick.tree.id, id):
		_open(tick)
	
	var status = _tick(tick)
	
	if status != Status.RUNNING: # todo: make and import Status
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