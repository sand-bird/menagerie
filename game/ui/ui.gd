extends CanvasLayer

# ***** TODO ***** : saving the following for if/when it's 
# relevant, but the ui_layer system needs more refinement 
# before it's ready for implementation.
# (from _open_menu:)
# 1: ui_layer (int), optional - if given, indicates that the
#    new ui element will REPLACE existing ui elements at or
#    above the given layer, while leaving those below intact.
#    if not given, the new element will be assigned a layer
#    value equal to the larger of: the element below it, or
#    the default value (2). see the Layer enum above.
enum Layer {
	BACKGROUND = 0
	HUD = 1
	MENU = 2
	POPUP = 3
}

var stack = []

func _ready():
	EventManager.connect("open_menu", self, "_open_menu")
	EventManager.connect("close_menu", self, "_close_menu")

# -----------------------------------------------------------

# OPEN MENU
# ---------
# can happen in a few different ways, depending on values 
# passed by the caller when it triggers the signal.
# accepts a single argument: either a STRING representing
# the item_ref of the ui element to open (implying default
# for the others), or an ARRAY with the following elements:
# 0: item_ref (string), required
# 1: replace (boolean), optional - if given, indicates that 
#    the new element will REPLACE ALL existing ui elements.
#    defaults to false.
# 2: restore_on_close (boolean), optional - indicates whether
#    the replaced elements should be restored when this
#    element is closed. defaults to true.
func _open_menu(args):
	# set up vars
	var item_ref
	var replace = false
	var restore_on_close = true
	if typeof(args) == TYPE_STRING:
		item_ref = args
	elif typeof(args) == TYPE_ARRAY:
		item_ref = args[0]
		if args.size() > 1:
			replace = args[1]
		if args.size() > 2:
			restore_on_close = args[2]
	var item = {
		"ref": item_ref
	}
	# replace if necesary
	if replace:
		if restore_on_close: item.restore = stack
		replace(item)
	else:
		push(item)

# CLOSE MENU
# ----------
# arg is optional; we are assuming that we want to close the
# topmost item. in the future, we may want to allow for an
# identifier to be passed, and additionally close all items 
# above it in the stack.
func _close_menu(arg = null):
	var item = pop()
	if item.has("restore"):
		for stack_item in item.restore: push(stack_item)

# -----------------------------------------------------------

func push(item):
	var node = load_node(item.ref)
	item.node = node
	stack.push_back(item)
	add_child(node)
	print("pushed: ", item, " | stack: ", stack)

func pop():
	var item = stack.pop_back()
	var node = item.node
	print("popped: ", item, " | stack: ", stack)
	node.queue_free()
	return item

func replace(item):
	for i in stack: pop()
	push(item)

# -----------------------------------------------------------

func load_node(path):
	load("res://ui/" + path + ".tscn").instance()