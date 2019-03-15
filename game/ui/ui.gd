extends CanvasLayer

enum Layer {
	BACKGROUND = 0
	HUD = 1
	MENU = 2
	POPUP = 3
}

const UI_PATH = "res://ui/"
const EXT = ".tscn"
const R = "{REF}" # placeholder string (R is for "replace")
const REFS = [
	R,
	R + EXT,
	UI_PATH + R,
	UI_PATH + R + EXT,
	R + "/" + R,
	R + "/" + R + EXT,
	UI_PATH + R + "/" + R,
	UI_PATH + R + "/" + R + EXT
]

const DEFAULT_MENU_PAGE = 'options'
# we can't count on our main_menu node always being
# instantiated, but we still want to remember the last open
# menu page, so we'll keep track of it here instead
var last_menu_page

# UI used to be a singleton, where `ui_node` held a reference
# to the instanced CanvasLayer that would hold the instances
# of the nodes in our stack. that was silly, since (a) we
# only have one instanced ui node, and (b) UI's primary
# function is to instantiate scenes anyway - but let's keep
# the variable around, just in case.
var ui_node = self

var stack = []

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	Dispatcher.connect('ui_open', self, 'open')
	Dispatcher.connect('ui_close', self, 'close')
	Dispatcher.connect('menu_open', self, 'open_menu')


# =========================================================== #
#                S I G N A L   H A N D L I N G                #
# ----------------------------------------------------------- #

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
	get_tree().paused = true
	Log.debug(self, ["(open) args: ", args])
	# set up vars
	var item_ref
	var open_type = null
	var restore_on_close = true
	if args is String:
		item_ref = args
	elif args is Array:
		item_ref = args[0]
		# optional arguments
		if args.size() > 1:
			open_type = args[1]
		if args.size() > 2:
			restore_on_close = args[2]

	var path = process_ref(item_ref)
	if !path:
		Log.error(self, ["(open) could not open '", item_ref,
				"': file not found."])
		return

	var layer_value = get_layer_value(open_type, path)

	var item = {
		'path': path,
		'layer': layer_value
	}
	if restore_on_close:
		item.restore = []

	Log.debug(self, ["(open) pushing to ui stack: ", item])
	return push(item)

# -----------------------------------------------------------

# TODO: here we should accept a node pointer (or maybe an
# item_ref) indicating that we want to close a specific node.
# we search the stack for this node, pop it (and everything
# above it) if we find it, or quit if we don't (meaning it
# was already removed). this will help with cases that can't
# be handled elegantly using layer values.
func close(arg = null):
	var item = _pop(arg) if typeof(arg) == TYPE_INT else _pop(find_item(arg))
	if item.has('restore') and item.restore:
		for stack_item in item.restore: push(stack_item)
	if stack.empty():
		get_tree().paused = false

# -----------------------------------------------------------

# executed when we hear a 'menu_open' signal. the main menu
# scene listens for the signal on its own, so if it's already
# loaded it will handle it - but if not, we need to add it to
# the ui stack and then call its open function manually.
# we also take this opportunity to update last_menu_page.
func open_menu(arg = null):
	# figure out which menu page we're opening
	var page = Utils.unpack(arg)
	var noarg = true if page == null else false
	if !page: page = last_menu_page
	if !page: page = DEFAULT_MENU_PAGE
	last_menu_page = page

	var menu_path = process_ref('main_menu')
	Log.debug(self, ["opening menu. stack: ", stack])

	var menu_index = find_item(menu_path, false)
	if menu_index != null:
		Log.debug(self, "menu already present in stack!")
		if noarg: close(menu_index)
		return

	var menu = open(menu_path)
	menu.open(page)

# -----------------------------------------------------------

func open_select(arg):
	var selected = Utils.unpack(arg)
	var select_ui = open(process_ref("garden/select_hud"))
	select_ui.initialize(selected)


# =========================================================== #
#               S T A C K   O P E R A T I O N S               #
# ----------------------------------------------------------- #

func push(item):
	var pop_from
	# look through the stack for items that match or exceed the
	# layer value of our current item. these would have layered
	# above our new item, so they need to be removed.
	for i in stack.size():
		if stack[i].layer < item.layer: continue
		if pop_from == null: pop_from = i
		if !item.has('restore'): break
		# we want everything but the noderef, since
		# the node will be deleted anyway.
		var restore_item = {
			layer = stack[i].layer,
			path = stack[i].path,
		}
		if stack[i].has('restore'):
			restore_item.restore = stack[i].restore
		Log.verbose(self, ["(push) adding item to our restore stack: ",
				restore_item])
		item.restore.push_back(restore_item)

	if pop_from != null:
		Log.verbose(self, ["(push) popping the stack at index: ",
				pop_from, " (stack size: ", stack.size() , ")"])
		_pop(pop_from)

	var node = load_node(item.path)
	item.node = node
	stack.push_back(item)
	ui_node.add_child(node)
	Log.verbose(self, ["pushed: ", item])
	Log.verbose(self, ["stack: ", stack])

	return node

# -----------------------------------------------------------

# currently only accepts an index to the stack. that's
# probably fine; in future we will want to handle a noderef
# argument for ui_close, so that nodes can close themselves,
# but this can be handled in close() instead of here.
# (int, bool) -> dict | undefined
#warning-ignore:unused_argument
func _pop(i = null, restore = true):
	if !stack or (i and i >= stack.size()):
		Log.warn(self, "stack is empty!")
		return

	# if we're trying to pop something that isn't at the top
	# of the stack, we have to pop everything above it first.
	# we throw away any restore data for those items (for now)
	if i != null:
		Log.verbose(self, ["(_pop) clearing items between our index (",
				i, ") and the top index (", stack.size() - 1, ")"])
		while stack.size() - 1 > i:
			_pop(null, false)

	var item = stack[-1]
	var node = item.node
	stack.pop_back()
	Log.verbose(self, ["popped: ", item])
	Log.verbose(self, ["stack: ", stack])
	node.queue_free()
	return item


# =========================================================== #
#            A U X I L I A R Y   F U N C T I O N S            #
# ----------------------------------------------------------- #

func process_ref(ref: String): # -> String | undefined
	# first we try the ref
	var file = File.new()
	for template in REFS:
		var path: String = template.replace(R, ref)
		if file.file_exists(path): return path
	Log.warn(self, ["could not find a valid .tscn file for: ", ref])

# -----------------------------------------------------------

func load_node(path: String) -> Node:
	return load(path).instance()

# -----------------------------------------------------------

# the "layer value" of a ui element determines which elements
# it will replace (those with an equal or greater value) and
# which it will overlay. here we look up the layer value for
# our new element based on the open_type property that was
# passed to open() by whoever emitted the signal (see above).
func get_layer_value(open_type, path):
	if open_type == null:
		var node = load_node(path)
		if 'layer' in node: return node.layer
		else: return get_next_layer()
	elif open_type == -1:
		return get_next_layer()
	else: return open_type

# -----------------------------------------------------------

func get_next_layer():
	var max_layer = 0
	if !stack.empty():
		for element in stack:
			if element.layer > max_layer:
				max_layer = element.layer
	return max_layer + 1

# -----------------------------------------------------------

# the `process` argument lets us skip processing the ref if
# we know it's been processed already (assuming the argument
# is an item_ref and not a node pointer)
func find_item(arg, process = true):
	if arg == null: return
	elif typeof(arg) == TYPE_STRING:
		return find_item_by_path(arg, process)
	elif typeof(arg) == TYPE_OBJECT:
		return find_item_by_node(arg)

# -----------------------------------------------------------

func find_item_by_path(ref, process = true):
	var path = process_ref(ref) if process else ref
	if !path: return
	for i in stack.size():
		if stack[i].path == path: return i

# -----------------------------------------------------------

func find_item_by_node(node):
	for i in stack.size():
		if stack[i].node == node: return i
