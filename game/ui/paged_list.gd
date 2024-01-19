class_name PagedList
extends GridContainer
"""
Paginated GridContainer with automatic focus/selection handling.  Captures the
focus inputs (ui_up, ui_focus_next, etc) and uses them to control selection
state instead, which then calls `grab_focus` on the selected child node.
(This can be changed on subclasses by overriding `on_select`/`on_deselect`.)
This allows us to:

1. automatically paginate on left/right inputs when the selected item is on the
   corresponding edge of the grid (this also wraps the selector)
2. automatically select/focus an item when a directional input is pressed while
   nothing is selected
3. configurably allow `ui_cancel` to clear the selection (see `allow_unselected`)
4. configurably update the selection based on mouse interaction: hover, click,
   or none (see `mouse_mode`)

Note: this component relies on `_input` to capture focus inputs before they can
do anything.  As a result, it doesn't play well with other UI components, eg
text inputs (where ui direction inputs move the cursor), or other PagedLists.
this is okay for now, but we may have to rethink this when it's time to develop
more complex uis, like shop pages.  in that case, we can try updating `selected`
to respond to focus changes instead of the other way around, and paginate if
`find_valid_focus_neighbor` (new in godot 4.2) returns nothing.

USAGE
-----
Configure `rows`, `columns`, `mouse_mode` and `allow_unselected` in the editor,
or in code.

Subclasses should implement `load_items` at minimum: this takes in the current
page of data, and should return an array of Control nodes which PagedList will
then add as children.

Set `data` to initialize state.  Set `page` to update the current page and set
`selected` (or call `select`) to update the current selected item.  These are
clamped, so they're forgiving of values out of bounds.

Other nodes can respond to state changes in two ways:
1. parents can connect to the various `changed` signals
2. subclasses can implement the various `on_` functions
"""

signal page_changed(page: int)
signal page_count_changed(page_count: int)
signal selected_changed(selected: int, data: Variant)

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

# source data.  the size of this array determines the total number of pages.
# each element will be loaded into a grid item when we load the page it's on.  
var data: Array[Variant] = []:
	set(x):
		data = x
		# reload the page when data changes
		page = page
		# page count depends on data, rows, and columns.
		# we should emit this on all 3, but it should be ok to just use data
		# since we don't really expect rows or columns to change at runtime.
		page_count_changed.emit(page_count)

# current page, so we know which slice to load when changing pages
var page: int = 0:
	set(new):
		page = clampi(new, 0, page_count - 1)
		load_page()
		on_page_changed()
		page_changed.emit(page)

# children on the current page.  should be no larger than rows * columns.
# the selected item is the one whose index is `selected`.
var items: Array[Control] = []
# index of the selected item
var selected: int = -1: set = select
# items can lose focus for two reasons:
#  1. because of a change in selection, or
#  2. because we clicked outside the item.
# when the selection changes, we manage focus via `on_select` & `on_deselect`,
# so we don't have to do anything extra.
# when clicking outside the item though, we need to either clear the selection
# (if allow_unselected is true) or re-focus the item by selecting it again,
# to ensure that focus always matches the selected item.  this is handled in a
# `focus_exited` listener on each item, which we set up in `connect_item`.
# this boolean tells the `focus_exited` handler not to do anything, since the
# item is losing focus due to a selection change.
var ignore_unfocus: bool = false

func select(new: int):
	ignore_unfocus = true
	# deselect the last selected item if necessary
	if has_selected and selected < items.size() and selected != new:
		on_deselect(items[selected])
	# set the new value, clamped to `items`.
	# a value of -1 means nothing is selected
	var min = -1 if allow_unselected or items.is_empty() else 0
	selected = clampi(new, min, items.size() - 1)
	if has_selected: on_select(items[selected])
	var selected_data = data[(page * page_size) + selected] if has_selected else null
	selected_changed.emit(selected, selected_data)
	ignore_unfocus = false


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
	get: return 0 if items.is_empty() else (items.size() - 1) / columns


# =========================================================================== #

func _ready():
	Dispatcher.menu_next_page.connect(next)
	Dispatcher.menu_prev_page.connect(prev)
	initialize()
	page = 0
	if !allow_unselected: select(0)


# =========================================================================== #
#                               A B S T R A C T                               #
# --------------------------------------------------------------------------- #

# override this instead of _ready
func initialize(): pass

# should take in a slice of data the same length as page_size, and return an
# array of Control nodes which we will then add as children.
func load_items(_data_slice: Array[Variant]) -> Array[Control]:
	return []

# do whatever should be done when a child is selected.
# note: we might _always_ want to manage focus on select/deselect, so it may
# be better to do so outside these abstract functions.
func on_select(item: Control): item.grab_focus()

func on_deselect(item: Control): item.release_focus()

func on_page_changed(): pass


# =========================================================================== #
#                             P A G I N A T I O N                             #
# --------------------------------------------------------------------------- #

# called from the `page` setter.  should not be called on its own.
func load_page():
	for child in get_children(): child.queue_free()
	var start = page_size * page
	items = load_items(data.slice(start, start + page_size))
	for i in items.size():
		var item = items[i]
		connect_item(item, i)
		add_child(item)
	# since we just instantiated these items, we have to trigger `on_selected`
	# again.  setting `selected` also re-clamps it in case the page size shrunk.
	select(selected)

# --------------------------------------------------------------------------- #

# set up each item to update `selected` on the appropriate mouse action
func connect_item(item: Control, i: int):
	match mouse_mode:
		MouseMode.HOVER: item.mouse_entered.connect(func(): select(i))
		MouseMode.CLICK: item.gui_input.connect(
			func(e): if e is InputEventMouseButton and e.pressed: select(i)
		)
	item.focus_exited.connect(
		func():
			Log.verbose(self, ['focus_exited ', item,
				' | selected: ', selected, items[selected],
				' | ignore_unfocus: ', ignore_unfocus])
			if ignore_unfocus: return
			if allow_unselected: selected = -1
			else: select(selected)
	)

# --------------------------------------------------------------------------- #

func next(wrap: bool):
	if page >= page_count - 1: return
	page += 1
	if wrap: select(columns * row)

func prev(wrap: bool):
	if page <= 0: return
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
	# special case: only capture `ui_cancel` if we have a selection to clear and
	# we are allowed to clear it
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
