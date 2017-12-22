# class Action
const BaseAction = preload("base_action.gd")

# ===========================================================
#                     C O M P O S I T E S
# -----------------------------------------------------------

class CompositeAction extends BaseAction:
	var children = []
	
	func _init(children):
		initialize(children)
	
	func initialize(children):
		.initialize()
		if (children):
			for child in children:
				self.children.push(child)
				# todo: test if loops by key or val

# -----------------------------------------------------------

class Sequence extends CompositeAction:
	func _init(args):
		initialize(args)
	
	func tick(tick):
		for child in children:
			var status = child.execute(tick)
			if status != Status.SUCCESS: return status
		
		return Status.SUCCESS

# -----------------------------------------------------------

class Priority extends CompositeAction:
	func _init(args):
		initialize(args)
	
	func tick(tick):
		for child in children:
			var status = child.execute(tick)
			if status != Status.FAILURE: return status
		
		return Status.FAILURE

# -----------------------------------------------------------

class MemSequence extends CompositeAction:
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

# -----------------------------------------------------------

class MemPriority extends CompositeAction:
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

# ===========================================================
#                     D E C O R A T O R S
# -----------------------------------------------------------

class Decorator extends BaseAction:
	var child

	func _init(child):
		initialize(child)
	
	func initialize(child):
		.initialize()
		if (child): self.child = child

# -----------------------------------------------------------

class Inverter extends Decorator:
	func _init(args):
		initialize(args)
	
	func tick(tick):
		var status = child.execute(tick)
		
		if status == Status.SUCCESS:
			status = Status.FAILURE
		elsif status == Status.FAILURE:
			status = Status.SUCCESS
		
		return status

# ===========================================================
#                      M U T A T I O N S
# -----------------------------------------------------------

class Wait extends BaseAction:
	var end_time
	
	func _init(ms):
		end_time = ms
		initialize()
	
	func open(tick):
		var start_time = Time.get_time()
		set(tick, 'start_time', start_time)
	
	func tick(tick): # todo: set this to use game ticks??
		var current_time = Time.get_time()
		var start_time = get(tick, 'start_time')
		if (curr_time - start_time > 0): return Status.SUCCESS
		return Status.RUNNING

# -----------------------------------------------------------

# since we will have to path, it's probably better to
# delegate the computation to the monster object itself.

# option one:
# create our own path object and save it when we decide to move. 
# the generation could succeed or fail, possibly in multiple ways

# option two:
# re-run path each tick, which will update if something changes and
# and the monster becomes stuck. questionably necessary? but since
# we want monsters to path around each other, this is probably a good
# idea. ALSO if the path status changes from ok to impossible, we can
# have the monster get mad that it was blocked, which is a feature
# worth implementing
# (note: when we have the ability to place objects, we cannot 
# reasonably restrict the player from dropping them onto a monster's 
# path, so this will have to be handled regardless)

class Move extends BaseAction:
	var target
	var speed
	# path status?
	# saved path (if we're doing that?)
	
	func _init(tgt, spd):
		target = tgt
		speed = spd
		initialize()
	
	func open(tick): pass
		# (call on the monster to) set the path, if we're doing that
	
	func tick(tick):
		# call on monster to update path
		# maybe we can check if anything is suddenly blocking our
		# path before we recalculate? would prob save a lot of cycles

# -----------------------------------------------------------

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

# -----------------------------------------------------------

class ChangePosition extends BaseAction:
	func _init():
		initialize()
	
	func tick(tick):
		tick.target.x = rand()
		tick.target.y = rand()
		return Status.SUCCESS

# ===========================================================
#                     C O N D I T I O N S
# -----------------------------------------------------------
		
class IsMouseOver extends BaseAction:
	func _init():
		initialize()
	
	func tick(tick):
		var point = tick.target.get_global_mouse_pos()
		# if it's over us return success if not failure