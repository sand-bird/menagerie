extends TextureRect

onready var props = Constants.GRID_PROPERTIES[Options.inventory_size.grid_size]
onready var Item = Utils.load_relative(filename, "grid_item")
var item_count = 0

func init_bg(grid_width, cells):
	return grid_width

func calc_size(item_size, grid_size):
	return (item_size * grid_size) + Vector2(3, 3) + (grid_size - (Vector2(2, 2) * 3))

func initialize(grid_config, grid_size):
	$items.columns = props.columns
	texture = Utils.load_resource(Constants.UI_ELEMENT_PATH, props.grid_bg)
	$items.rect_position = props.grid_offset

func load_items(items):
	clear_items()
	item_count = items.size()
	for i in item_count:
		var item = Item.instance()
		item.initialize(i, items[i], props)
		$items.add_child(item)

func show_quantity(index, show):
	$items.get_child(index).show_quantity(show)

func clear_items():
	item_count = 0
	for item in $items.get_children():
		item.free()
