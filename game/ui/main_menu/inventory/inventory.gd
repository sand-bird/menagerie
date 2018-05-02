extends "res://ui/main_menu/menu_page.gd"

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

var prev_item = 0
var current_item = 0
var current_page = 0 setget update_current_page
var page_count = 0

# -----------------------------------------------------------

func _ready():
	title = "Inventory" # parent class property
	Dispatcher.connect("item_selected", self, "update_current_item")
	initialize()

func initialize():
	.initialize()
	init_self()
	init_item_grid()
	init_selector()

func init_self():
	columns = props.columns
	page_count = Player.inventory.size() / (columns * columns)

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

func update_current_page(new_page):
	current_page = new_page
	update_page_display()

func update_page_display():
	var new_display = str(current_page + 1) + " / " + str(page_count)
	Dispatcher.emit_signal("update_menu_page_display", new_display)

# -----------------------------------------------------------

func update_current_item(index):
	prev_item = current_item
	current_item = index
	$item_grid.show_quantity(prev_item, true)
	$item_grid.show_quantity(current_item, false)
	move_selector(index)

func update_item_info(item_id, item_type):
	pass #var item_data = 

# -----------------------------------------------------------

func get_selector_dest(index):
	var base_pos = $item_grid.rect_position
	var coords = Vector2(index % columns, index / columns)
	var item_offset = coords * (props.item_size + Vector2(3, 3))
	return base_pos + item_offset + selector_offset

func move_selector(index):
	$selector.move_to(get_selector_dest(index))
	$selector.show()