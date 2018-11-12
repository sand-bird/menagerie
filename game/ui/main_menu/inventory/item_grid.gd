extends TextureRect

var InventorySize = Constants.InventorySize
onready var Item = Utils.load_relative(filename, "grid_item")
var props # passed from big mama inventory scene
var item_count = 0

func _ready(): pass

func initialize():
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
		item.queue_free()
