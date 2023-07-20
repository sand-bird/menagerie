extends GridContainer
class_name PagedList

signal page_changed(_page: int)
signal page_count_changed(_page_count: int)
signal selected_changed(_selected: int)

#                                 c o n f i g                                 #
# --------------------------------------------------------------------------- #

# determines how (or if) we select items by mouse interaction.
# hover selects on hover, click on click, and none does not select.
enum MouseMode { HOVER, CLICK, NONE }
@export var mouse_mode: MouseMode

# rows per page.
# page size is the product of rows and columns (inherited from GridContainer).
@export_range(1, 1024) var rows: int = 1:
	set(x): rows = maxi(x, 1)

# if this is false, we force `selected` to be a valid index of `items` unless
# `items` is empty.  if true, we can clear `selected` by setting it to -1.
@export var allow_unselected: bool = true

#                                  s t a t e                                  #
# --------------------------------------------------------------------------- #

# source data.  each element will be loaded into a grid item when we load the
# page it's on.  the size of this array determines the total number of pages.
var data: Array[Variant] = []:
	set(x):
		print('data changed!!')
		data = x
		# page count depends on data, rows, and columns.
		# we should emit this on all 3, but it should be ok to just use data
		# since we don't really expect rows or columns to change at runtime.
		page_count_changed.emit(page_count)

# current page, so we know which slice to load when changing pages
var page: int = 0:
	set(new):
		page = clampi(new, 0, page_count - 1)
		load_page(page)
		on_page_changed(page)
		page_changed.emit(page)

# children on the current page.  should be no larger than rows * columns.
# the selected item is the one whose index is `selected`.
var items: Array[Control] = []
# index of the selected item
var selected: int = -1: set = select

func select(new: int):
	# deselect the last item, if any
	if has_selected and selected < items.size(): on_deselect(items[selected])
	# set the new value, clamped to `items`.
	# a value of -1 means nothing is selected
	var min = -1 if allow_unselected or items.is_empty() else 0 
	selected = clampi(new, min, items.size() - 1)
	if has_selected: on_select(items[selected])
	selected_changed.emit(selected)

#                    c o m p u t e d   p r o p e r t i e s                    #
# --------------------------------------------------------------------------- #

var page_size: int:
	get: return rows * columns

var page_count: int:
	get: return 1 if data.is_empty() else U.ceil_div(data.size(), page_size)

var has_selected: bool:
	get: return selected > -1

# column (x) and row (y) of the current selected item
var column: int:
	get: return selected % columns
var row: int:
	get: return selected / columns

# get the last selectable row on the page.  should be no larger than rows - 1,
# but may be smaller if we don't have a full page of items.
var last_row: int:
	get: return 0 if items.is_empty() else items.size() - 1 / columns

# --------------------------------------------------------------------------- #
# abstract

# should take in a slice of data the same length as page_size, and return an
# array of Control nodes which we will then add as children.
func load_items(_data_slice: Array[Variant]) -> Array[Control]:
	return []

# should initialize `data`.
func initialize(): pass

# do whatever should be done when a child is selected.
func on_select(item: Control): item.grab_focus()

func on_deselect(item: Control): item.release_focus()

func on_page_changed(page: int): pass

# --------------------------------------------------------------------------- #

func _ready():
	Dispatcher.menu_next_page.connect(next)
	Dispatcher.menu_prev_page.connect(prev)
	initialize()
	page = 0
	if !allow_unselected: select(0)

# --------------------------------------------------------------------------- #

func load_page(index: int):
	for child in get_children(): child.queue_free()
	var start = page_size * index
	var end = start + page_size
	items = load_items(data.slice(start, end))
	for i in items.size():
		var item = items[i]
		connect_item(item, i)
		add_child(item)
	# since we just instantiated these items, we have to trigger `on_selected`
	# again.  setting `selected` also re-clamps it in case the page size shrunk.
	select(selected)

func connect_item(item: Control, i: int):
	match mouse_mode:
		MouseMode.HOVER: item.mouse_entered.connect(func(): select(i))
		MouseMode.CLICK: item.gui_input.connect(
			func(e): if e is InputEventMouseButton and e.pressed: select(i)
		)

# --------------------------------------------------------------------------- #

func next(wrap: bool):
	page += 1
	if wrap: select(columns * row)

func prev(wrap: bool):
	page -= 1
	if wrap: select((columns * row) + (columns - 1))


# =========================================================================== #
#                         I N P U T   H A N D L I N G                         #
# --------------------------------------------------------------------------- #

const EVENT_KEYS = [
	&'ui_left', &'ui_right', &'ui_up', &'ui_down',
	&'ui_focus_next', &'ui_focus_prev'
]

func _input(e: InputEvent):
	for key in EVENT_KEYS:
		if e.get_action_strength(key) == 1:
			call("_" + key)
			accept_event()
	if e.is_action_pressed(&'ui_cancel') and has_selected and allow_unselected:
		selected = -1
		accept_event()

# --------------------------------------------------------------------------- #

func _ui_left():
	if !has_selected: select(columns - 1) # top right
	elif column > 0: selected -= 1
	else: Dispatcher.menu_prev_page.emit(true)

func _ui_right():
	if !has_selected: select(0) # top left
	elif column < columns - 1: selected += 1
	else: Dispatcher.menu_next_page.emit(true)

func _ui_up():
	if !has_selected: select(items.size() - 1) # bottom right
	elif row > 0: selected -= columns

func _ui_down():
	if !has_selected: select(0) # top left
	elif row < last_row: selected += columns

func _ui_focus_next(): Dispatcher.menu_next_page.emit(false)
func _ui_focus_prev(): Dispatcher.menu_prev_page.emit(false)
