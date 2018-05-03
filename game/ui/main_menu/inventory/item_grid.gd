extends TextureRect

var InventorySize = Constants.InventorySize
onready var Item = Utils.load_relative(filename, "grid_item")
var props # passed from big mama inventory scene

func _ready(): pass

func initialize():
	$items.columns = props.columns
	texture = Utils.load_resource(Constants.UI_ELEMENT_PATH, props.grid_bg)
	$items.rect_position = props.grid_offset

func load_items(items):
	for i in items.size():
		var item = Item.instance()
		var item_data = items[i]
		item.initialize(i, item_data, props)
		$items.add_child(item)

func show_quantity(index, show):
	$items.get_child(index).show_quantity(show)