# class Action

# executes children sequentially until one fails
class Sequence extends BaseAction:
	func _init(args):
		initialize(args)
	
	func tick(tick):
		for child in children:
			var status = child.execute(tick)
			if status != Status.SUCCESS: return status
		
		return Status.SUCCESS

# tries children in sequence (representing priority) until one succeeds
class Priority extends BaseAction:
	func _init(args):
		initialize(args)
	
	func tick(tick):
		for child in children:
			var status = child.execute(tick)
			if status != Status.FAILURE: return status
		
		return Status.FAILURE

# saves running children to blackboard so they can be called directly next tick
class MemSequence extends BaseAction:
	func _init(args):
		initialize(args)
	
	func open(tick):
		set(tick, 'running_child', 0)
	
	func tick(tick):
		var curr_child = get(tick, 'running_child')
		for i in range(curr_child, children.length):
			var status = children[i].execute(tick)
			if status != Status.SUCCESS:
				if status == Status.RUNNING:
					set(tick, 'running_child', i)
				return status
		return Status.SUCCESS

class MemPriority extends BaseAction:
	func _init(args):
		initialize(args)
	
	func open(tick):
		set(tick, 'running_child', 0)
	
	func tick(tick):
		var curr_child = get(tick, 'running_child')
		for i in range(curr_child, children.length):
			var status = children[i].execute(tick)
			if status != Status.FAILURE:
				if status == Status.RUNNING:
					set(tick, 'running_child', i)
			return status
		return Status.FAILURE

# changes a child's success to failure and failure to success
class Inverter extends BaseAction:
	func _init(args):
		initialize(args)
	
	func tick(tick):
		var child = children[0]
		if !child: return Status.ERROR
		
		var status = child.execute(tick)
		
		if status == Status.SUCCESS:
			status = Status.FAILURE
		elsif status == Status.FAILURE:
			status = Status.SUCCESS
		
		return status


class Wait extends BaseAction:
	
	var end_time
	
	func _init(ms):
		end_time = ms
		initialize()
	
	func open(tick):
		var start_time = new Date().get_time()
		set(tick, 'start_time', start_time)
	
	func tick(tick):
		var current_time = new Date().get_time()
		var start_time = get(tick, 'start_time')
		
		if (curr_time - start_time > 0): return Status.SUCCESS
		
		return Status.RUNNING


class ChangeColor extends BaseAction:

	var color
	
	func _init(color):
		self.color = color
		initialize()
	
	func tick(tick):
		tick.target.graphics.clear()
		tick.target.graphics.beingFill(color)
		tick.target.graphics.draw_rect(0, 0, 100, 100)
		
		return Status.SUCCESS


class ChangePosition extends BaseAction:
	func _init():
		initialize()
	
	func tick(tick):
		tick.target.x = rand()
		tick.target.y = rand()
		return Status.SUCCESS

class IsMouseOver extends BaseAction:
	func _init():
		initialize()
	
	func tick(tick):
		var point = tick.target.get_global_mouse_pos()
		# if it's over us return success if not failure

