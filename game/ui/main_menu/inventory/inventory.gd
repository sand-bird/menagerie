extends "res://ui/main_menu/menu_chapter.gd"

var Wrap = Constants.Wrap

onready var props = Constants.INVENTORY_PROPERTIES[Options.inventory_size]
onready var selector_offset = props.grid_offset - Vector2(4, 4)
onready var columns = props.columns
onready var rows = props.rows if props.has('rows') else props.columns

# as in "inventory item", not as in Item (the specific type
# of game entity). unfortunately ambiguous, but i couldn't 
# come up with any decent alternatives :(
# 
# an array of ints, each an index within Player.inventory.
# represents the subset of the player's inventory that we can
# SEE & INTERACT WITH. possible reasons an inventory item 
# doesn't show up in this list:
# - it's being filtered out by our current filter settings
# - the data for its entity id was not found; an uncommon but
#   expected case, eg. if an entity belongs to a mod that's 
#   currently disabled.
onready var items = []

# =========================================================== #
#                 I N I T I A L I Z A T I O N                 #
# ----------------------------------------------------------- #

func _ready():
	Dispatcher.connect("item_selected", self, "update_current_item")

# -----------------------------------------------------------

func initialize(filter):
	# init self
	items = filter_items(filter)
	var pages = items.size() / (columns * columns)
	if items.size() % (columns * columns) > 0: pages += 1
	self.page_count = pages
	
	# init item grid
	$item_grid.props = props
	$item_grid.initialize()
	$item_grid.load_items(get_page_items())
	init_selector()
	if items: update_current_item(0)
	
	.initialize()

# -----------------------------------------------------------

func filter_items(filter):
	var results = []
	for i in Player.inventory.size():
		var id = Player.inventory[i].id
		var data = Data.get(id)
		if !data: continue  # dw, Data.get already logged it
		var matches = true
		for key in filter.keys():
			if !data.has(key) or data[key] != filter[key]:
				matches = false
				break
		if matches:
			Log.info(self, [id, " passed filter!"])
			results.append(i)
	return results


# =========================================================== #
#                 U P D A T I N G   S T A T E                 #
# ----------------------------------------------------------- #

func update_current_item(new_index):
	# clamp to the last item on the page, in case we're on the
	# last page and it's not completely full. doing this here
	# ensures it always happens, so that we have less bounds-
	# checking to do elsewhere.
	new_index = min(new_index, $item_grid.item_count - 1)
	$item_grid.show_quantity(current_item, true)
	$item_grid.show_quantity(new_index, false)
	move_selector(new_index)
	update_item_details(new_index)
	self.current_item = new_index

# -----------------------------------------------------------

# returns a slice of the items array containing only the ones
# that are visible on our current page
func get_page_items():
	var page_size = columns * columns
	var start = current_page * page_size
	return Utils.slice(items, start, page_size)

# -----------------------------------------------------------

func update_item_details(index):
	var item = get_item(index)
	var item_data = Data.get(item.id)
	
	$item_name/label.text = Utils.trans(item_data.name)
	$item_description/label.text = Utils.trans(item_data.description)
	$item_icon/icon.texture = Data.get_resource([item.id, "icon"])
	$item_properties/category.text = item_data.category
	$item_properties/value.text = Utils.comma(item_data.value)
	$item_properties/value/aster.show()
	
	var qty = item.qty
	if qty == 1: $item_icon/quantity.hide()
	else:
		$item_icon/quantity.show()
		$item_icon/quantity.text = str(qty)
		var min_size = $item_icon/quantity.get_minimum_size().x
		$item_icon/quantity.margin_left = -7 - min_size

# -----------------------------------------------------------

# fetches actual item data from the Player global
func get_item(index):
	var actual_index = current_page * columns * columns + index
	return Player.inventory[items[actual_index]]


# =========================================================== #
#              S E L E C T O R   C O N T R O L S              #
# ----------------------------------------------------------- #

func init_selector():
	if items.empty(): return
	$selector.texture = Utils.load_resource(
			Constants.UI_ELEMENT_PATH, props.selector)
	var selector_pos = get_selector_dest(current_item)
	$selector.rect_position = selector_pos
	$selector.dest_pos = selector_pos

# -----------------------------------------------------------

# gets the pixel coordinates for our selector's destination
# based on the item-grid index it wants to move to.
# (TODO: something about that magic 3x3 vector - i forgot
# exactly what it was supposed to be for)
func get_selector_dest(index):
	var base_pos = $item_grid.rect_position
	var coords = get_coords(index)
	var item_offset = coords * (props.item_size + Vector2(3, 3))
	return base_pos + item_offset + selector_offset

# -----------------------------------------------------------

func move_selector(index):
	$selector.move_to(get_selector_dest(index))
	$selector.show()

# -----------------------------------------------------------

# gets the row and column of a given item-grid index, based
# on the (configurable) column size of the inventory
func get_coords(index):
	return Vector2(int(index) % int(columns), int(index) / int(columns))


# =========================================================== #
#                 I N P U T   H A N D L I N G                 #
# ----------------------------------------------------------- #

func _input(e):
	if e.is_action_pressed("ui_left"): move_left()
	elif e.is_action_pressed("ui_right"): move_right()
	elif e.is_action_pressed("ui_up"): move_up()
	elif e.is_action_pressed("ui_down"): move_down()
	elif e.is_action_pressed("ui_aux_right"): next_page()
	elif e.is_action_pressed("ui_aux_left"): prev_page()
	else: return
	accept_event()

# -----------------------------------------------------------

func move_left():
	if get_coords(current_item).x > 0:
		update_current_item(current_item - 1)
	else: prev_page(true)

func move_right():
	if get_coords(current_item).x < columns - 1:
		update_current_item(current_item + 1)
	else: next_page(true)

func move_up():
	if get_coords(current_item).y > 0:
		update_current_item(current_item - columns)

func move_down():
	if get_coords(current_item).y < get_page_row():
		update_current_item(current_item + columns)

# -----------------------------------------------------------

func next_page(wrap = false):
	if (current_page < page_count - 1):
		change_page(1, wrap)

func prev_page(wrap = false):
	if (current_page > 0):
		change_page(-1, wrap)

# -----------------------------------------------------------

func change_page(offset, wrap = false):
	# change the page now
	self.current_page += offset
	$item_grid.load_items(get_page_items())
	
	# determine where to place our cursor. if we're changing
	# page via move_left or move_right, we want to wrap the
	# cursor to the opposite side of the row.
	var new_index = current_item
	if (wrap):
		var current_row = get_coords(current_item).y
		if (offset > 0):
			# in case we are going to the last page and it is not
			# full, we must restrict our new cursor to the maximum
			# row for that page. since the cursor snaps to the
			# left, and rows are left-aligned, this will be safe.
			new_index = min(current_row, get_page_row()) * columns
		if (offset < 0):
			new_index = current_row * columns + (columns - 1)
	
	update_current_item(new_index)

# -----------------------------------------------------------

# utility function to get the last row of the current page,
# while handling the case where our page is partially empty.
# this only happens on the last page; otherwise, we should be
# safe to just return the maximum row.
func get_page_row():
	if current_page < page_count - 1:
		return rows - 1
	else:
		return get_coords($item_grid.item_count - 1).y
