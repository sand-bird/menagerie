extends NinePatchRect

enum GridSize { SMALL, LARGE }

# grid properties
@export var grid_size: GridSize = GridSize.SMALL
@export var cols: int = 6
@export var rows: int = 6
var props

# state
var items = []
var current_item = 0
var current_page = 0

@onready var Item = Utils.load_relative(scene_file_path, "grid_item")
var item_count = 0

func init_bg(grid_width, cells):
	return grid_width

func as_vec():
	return Vector2(cols, rows)

func calc_size(item_size):
	return item_size + Vector2(1, 1) + item_size + Vector2(2, 2) + (
		(item_size + Vector2(3, 3)) * Vector2(cols - 2, rows - 2)
	)

# --------------------------------------------------------------------------- #

# grid_config is an object with the following:
# columns: int, rows: int, grid_size: GridSize
#
# state is an object with the following:
# items: object, current_item: int, current_page: int
func initialize(grid_config = null, state = null):
	for i in ['cols', 'rows', 'grid_size']:
		if grid_config and grid_config.has(i):
			set(i, grid_config[i])
	props = Constants.GRID_PROPERTIES[grid_size]
	$items.columns = cols
	texture = Utils.load_resource(Constants.UI_ELEMENT_PATH, props.grid_bg)
	size = calc_size(props.item_size)
	patch_margin_left = props.item_size.x + 2
	patch_margin_right = props.item_size.y + 1
	patch_margin_top = patch_margin_left
	patch_margin_bottom = patch_margin_right

	for i in ['items', 'current_item', 'current_page']:
		if state and state.has(i):
			set(i, state[i])

	if items: load_items(get_page_items())
	init_selector()

# --------------------------------------------------------------------------- #

func load_items(new_items):
	clear_items()
	item_count = new_items.size()
	for i in item_count:
		var item = Item.instantiate()
		item.initialize(i, new_items[i], props.item_size)
		$items.add_child(item)

# --------------------------------------------------------------------------- #

func show_quantity(index, show):
	$items.get_child(index).show_quantity(show)

# --------------------------------------------------------------------------- #

func clear_items():
	item_count = 0
	for item in $items.get_children():
		item.free()

# --------------------------------------------------------------------------- #

func update_current_item(new_index):
	#  clamp to the last item on the page, in case we're on the last page and
	#  it's not completely full. doing this here ensures it always happens, so
	#  that we have less bounds- checking to do elsewhere.
	new_index = min(new_index, item_count - 1)
	Log.debug(self, ["(update_current_item) new: ", new_index, " | old: ", current_item])

	move_selector(new_index)
	if current_item < item_count:
		show_quantity(current_item, true)
	show_quantity(new_index, false)
	current_item = new_index


# =========================================================================== #
#                      S E L E C T O R   C O N T R O L S                      #
# --------------------------------------------------------------------------- #

func init_selector():
	if !item_count: return
	$selector.texture = Utils.load_resource(
			Constants.UI_ELEMENT_PATH, props.selector)
	var selector_pos = get_selector_dest(0)
	$selector.position = selector_pos
	$selector.dest_pos = selector_pos

# --------------------------------------------------------------------------- #

# gets the pixel coordinates for our selector's destination based on the
# item-grid index it wants to move to. (TODO: something about that magic 3x3
# vector - i forgot exactly what it was supposed to be for. spacing maybe?)
func get_selector_dest(index):
	var base_pos = -Vector2(4, 4)
	var coords = get_coords(index)
	Log.debug(self, ["(get_selector_dest) destination coords: ", coords])
	var item_offset = coords * (props.item_size + Vector2(3, 3))
	return base_pos + item_offset

# --------------------------------------------------------------------------- #

func move_selector(index):
	$selector.move_to(get_selector_dest(index))
	$selector.show()


# =========================================================================== #
#                         I N P U T   H A N D L I N G                         #
# --------------------------------------------------------------------------- #

func _input(e):
	if e.is_action_pressed("ui_left"): move_left()
	elif e.is_action_pressed("ui_right"): move_right()
	elif e.is_action_pressed("ui_up"): move_up()
	elif e.is_action_pressed("ui_down"): move_down()
	elif e.is_action_pressed("ui_aux_right"): next_page()
	elif e.is_action_pressed("ui_aux_left"): prev_page()
	else: return
	accept_event()

# --------------------------------------------------------------------------- #

func move_left():
	if get_coords(current_item).x > 0:
		update_current_item(current_item - 1)
	else: prev_page(true)

func move_right():
	if get_coords(current_item).x < cols - 1:
		update_current_item(current_item + 1)
	else: next_page(true)

func move_up():
	if get_coords(current_item).y > 0:
		update_current_item(current_item - cols)

func move_down():
	if get_coords(current_item).y < get_page_row():
		update_current_item(current_item + cols)

# --------------------------------------------------------------------------- #

func next_page(wrap = false):
	if (current_page < get_page_count() - 1):
		change_page(1, wrap)

func prev_page(wrap = false):
	if (current_page > 0):
		change_page(-1, wrap)

# --------------------------------------------------------------------------- #

func change_page(offset, wrap = false):
	# change the page now
	current_page += offset
	load_items(get_page_items())

	# determine where to place our cursor. if we're changing page via move_left
	# or move_right, we want to wrap the selector to the opposite side of the row
	var new_index = current_item
	if (wrap):
		var current_row = get_coords(current_item).y
		if (offset > 0):
			# in case we are going to the last page and it is not full, we must
			# restrict our new cursor to the maximum row for that page. since the
			# cursor snaps to the left, and rows are left-aligned, this is safe.
			var new_row = min(current_row, get_page_row())
			new_index = coords_to_index(0, new_row)
		if (offset < 0):
			new_index = coords_to_index(cols - 1, current_row)

	update_current_item(new_index)


# =========================================================================== #
#                              U T I L I T I E S                              #
# --------------------------------------------------------------------------- #

# utility function to get the last row of the current page, while handling the
# case where our page is partially empty. this only happens on the last page;
# otherwise, we should be safe to just return the maximum row.
func get_page_row():
	if current_page < get_page_count() - 1:
		return rows - 1
	else:
		return get_coords(item_count - 1).y

# --------------------------------------------------------------------------- #

# gets the row and column of a given item-grid index, based on the
# (configurable) column size of the inventory
func get_coords(index):
	return Vector2(int(index) % int(cols), int(index) / int(cols))

func coords_to_index(col, row):
	return (cols * row) + col

# --------------------------------------------------------------------------- #

# returns a slice of the items array containing only the ones that are visible
# on our current page
func get_page_items():
	var page_size = cols * rows
	var start = current_page * page_size
	return Utils.slice(items, start, page_size)

# --------------------------------------------------------------------------- #

# todo: convert this to ceil(float()) maybe
func get_page_count():
	var pages = items.size() / (cols * rows)
	if items.size() % (cols * rows) > 0: pages += 1
	return pages

# --------------------------------------------------------------------------- #

func get_item(index):
	return current_page * cols * rows + index
