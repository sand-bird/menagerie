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

const DEFAULT_MENU_PAGE = "options"
# we can't count on our main_menu node always being
# instantiated, but we still want to remember the last
# open menu page, so we'll keep track of it here instead
var last_menu_page

var stack = []

func _ready():
	Dispatcher.connect("ui_open", self, "open")
	Dispatcher.connect("ui_close", self, "close")
	Dispatcher.connect("menu_open", self, "open_menu")
	# set_process_unhandled_input(true)

# -----------------------------------------------------------


# OPEN
# ----
# can happen in a few different ways, depending on values 
# passed by the caller when it triggers the signal.
# accepts a single argument: either a STRING representing
# the item_ref of the ui element to open (implying default
# for the others), or an ARRAY with the following elements:
# 0: item_ref (string), required
# 1: open_type (enum), optional - determines how the element
#    will interact with existing elements:
#    DEFAULT (null) - uses the "layer" variable specified in 
#      the element, if it exists, else falls back to OVERLAY
#    OVERLAY (-1) - uses the current highest layer value plus 
#      one, making restore_on_close meaningless
#    CUSTOM (any other int) - uses the given number as the
#      new element's layer value
# 2: restore_on_close (boolean), optional - indicates whether
#    the replaced elements, if there are any, should be 
#    restored when this element is closed. defaults to true.
func open(args):
	print("ui.open: ", args)
	# set up vars
	var item_ref
	var open_type = null
	var restore_on_close = true
	if typeof(args) == TYPE_STRING:
		item_ref = args
	elif typeof(args) == TYPE_ARRAY:
		item_ref = args[0]
		# optional arguments
		if args.size() > 1:
			open_type = args[1]
		if args.size() > 2:
			restore_on_close = args[2]
	
	var layer_value = get_layer_value(open_type, item_ref)
	
	var item = {
		"ref": item_ref,
		"layer": layer_value
	}
	if restore_on_close:
		item.restore = []
	
	print("pushing: ", item)
	return push(item)

# -----------------------------------------------------------

# the "layer value" of a ui element determines which elements
# it will replace (those with an equal or greater value) and
# which it will overlay. here we look up the layer value for
# our new element based on the open_type property that was 
# passed to open() by whoever emitted the signal (see above).
func get_layer_value(open_type, item_ref):
	if open_type == null:
		var node = load_node(item_ref)
		if "layer" in node: return node.layer
		else: return get_next_layer()
	elif open_type == -1:
		return get_next_layer()
	else: return open_type

# -----------------------------------------------------------

func open_menu(arg = null):
	# figure out which menu page we're opening
	var page = Utils.unpack(arg)
	if !page: page = last_menu_page
	if !page: page = DEFAULT_MENU_PAGE
	
	last_menu_page = page
	
	print("UI: open menu '", page, "'")
	match stack:
		[{"ref": "main_menu/main_menu", ..}, ..]:
			print("UI: main menu already open, we're good")
			return
	
	var menu = open("main_menu/main_menu")
	menu.open(page)

# CLOSE
# -----
# arg is optional; we are assuming that we want to close the
# topmost item. in the future, we may want to allow for an
# identifier to be passed, and additionally close all items 
# above it in the stack.
func close(arg = null):
	var item = pop()
	if item.has("restore"):
		for stack_item in item.restore: push(stack_item)

# -----------------------------------------------------------

func push(item):
	for i in stack.size():
		if stack[i].layer >= item.layer:
			if item.has("restore"): item.restore.push_back(stack[i])
			pop(i) # todo: test if we can remove while iterating
	
	var node = load_node(item.ref)
	item.node = node
	stack.push_back(item)
	add_child(node)
	print("pushed: ", item, " | stack: ", stack)
	return node

func pop(i = null):
	var item
	if i:
		item = stack[i]
		stack.remove(i)
	else: item = stack.pop_back()
	
	var node = item.node
	print("popped: ", item, " | stack: ", stack)
	node.queue_free()
	return item

func replace(item):
	for i in stack: pop()
	push(item)

# -----------------------------------------------------------

func load_node(path):
	return load("res://ui/" + path + ".tscn").instance()

func get_next_layer():
	var max_layer = 0
	if !stack.empty():
		for element in stack:
			if element.layer > max_layer: 
				max_layer = element.layer
	return max_layer
