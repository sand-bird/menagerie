extends "res://ui/main_menu/menu_chapter.gd"

var InventorySize = Constants.InventorySize

var properties = {
	InventorySize.SMALL: {
		columns = 6,
		grid_bg = "item_grid_small",
		selector = "selector_small",
		selector_size = Vector2(0, 0),
		grid_offset = Vector2(0, 0),
		item_size = Vector2(20, 20)
	},
	InventorySize.LARGE: {
		columns = 5,
		grid_bg = "item_grid_large",
		selector = "selector_big",
		selector_size = Vector2(0, 0),
		grid_offset = Vector2(2, 2),
		item_size = Vector2(24, 24)
	}
}

onready var props = properties[Options.inventory_size]
onready var selector_offset = props.grid_offset - Vector2(4, 4)
onready var columns = props.columns

# -----------------------------------------------------------

func _ready():
	title = "Inventory"
	Dispatcher.connect("item_selected", self, "update_current_item")
	initialize()

func initialize():
	.initialize()
	init_self()
	init_item_grid()
	init_selector()
	update_current_item(current_item)

func init_self():
	columns = props.columns
	page_count = Player.inventory.size() / (columns * columns)
	if Player.inventory.size() % (columns * columns) > 0: page_count += 1
	update_page_display()
	update_title_display()

func init_item_grid():
	$item_grid.props = props
	$item_grid.initialize()
	$item_grid.load_items(get_items())

func init_selector():
	$selector.texture = Utils.load_resource(
			Constants.UI_ELEMENT_PATH, props.selector)
	var selector_pos = get_selector_dest(current_item)
	$selector.rect_position = selector_pos
	$selector.dest_pos = selector_pos
	
# -----------------------------------------------------------

func get_items():
	var page_size = columns * columns
	var start = current_page * page_size
	return Utils.slice(Player.inventory, start, page_size)

# -----------------------------------------------------------

func update_current_item(index):
	prev_item = current_item
	current_item = index
	$item_grid.show_quantity(prev_item, true)
	$item_grid.show_quantity(current_item, false)
	move_selector(index)
	update_item_details(index)

func update_current_page(page):
	.update_current_page(page)
	current_page = page
	$item_grid.load_items(get_items())

func get_item(index):
	var actual_index = current_page * columns * columns + index
	return Player.inventory[actual_index]

func update_item_details(index):
	var item_info = get_item(index)
	var data_type = Data.lookup[item_info.type]
	var item_data = Data.data[data_type][item_info.id]
	
	$item_name/label.text = item_data.name
	$item_description/label.text = item_data.description
	$item_properties/type.text = Constants.text_keys[item_data.type]
	$item_properties/value.text = Utils.comma(item_data.value)
	
	var qty = item_info.qty
	if qty == 1: $item_icon/quantity.hide()
	else:
		$item_icon/quantity.show()
		$item_icon/quantity.text = str(qty)
		var min_size = $item_icon/quantity.get_minimum_size().x
		$item_icon/quantity.margin_left = -7 - min_size

# -----------------------------------------------------------

func get_selector_dest(index):
	var base_pos = $item_grid.rect_position
	var coords = get_coords(index)
	var item_offset = coords * (props.item_size + Vector2(3, 3))
	return base_pos + item_offset + selector_offset

func move_selector(index):
	$selector.move_to(get_selector_dest(index))
	$selector.show()

func get_coords(index):
	return Vector2(index % columns, index / columns)

# -----------------------------------------------------------

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
	var coords = get_coords(current_item)
	if coords.x > 0: 
		update_current_item(current_item - 1)
	elif current_page > 0 and prev_page():
		update_current_item(current_item + columns - 1)

func move_right():
	var coords = get_coords(current_item)
	if coords.x < columns - 1: 
		update_current_item(current_item + 1)
	elif current_page < page_count - 1 and next_page():
		update_current_item(current_item - columns + 1)


func move_up():
	var coords = get_coords(current_item)
	if coords.y > 0: 
		update_current_item(current_item - columns)
	elif current_page > 0 and prev_page():
		update_current_item(current_item + columns * (columns - 1))

func move_down():
	var coords = get_coords(current_item)
	if coords.y < columns - 1:
		update_current_item(current_item + columns)
	elif current_page < page_count - 1 and next_page():
		update_current_item(current_item - columns * (columns - 1))

func next_page():
	if (current_page < page_count - 1):
		update_current_page(current_page + 1)
		return true
	else: return false

func prev_page():
	if (current_page > 0):
		update_current_page(current_page - 1)
		return true
	else: return false