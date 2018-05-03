extends Control

var InventorySize = Constants.InventorySize
const LARGE_SIZE = Vector2(27, 27)
const SMALL_SIZE = Vector2(23, 23)

var qty
var id
var index

func _ready():
	connect("focus_entered", self, "_pressed")
	pass

# the notion of an inventory "item" is a bit misleading in
# our terminology, since an Item is already a kind of thing
# in the game. actually, the player's inventory can have
# both Items and Objects, and possibly other things as well.
#
# the data files for game entities are organized by type, so 
# we need to look up the type of each "item" in order to set
# our properties. `Data.lookup` holds a map of EntityTypes 
# to directory-names-as-data-keys (eg. "monsters", "items").
func initialize(i, item_info, props):
	index = i
	set_size(props.item_size)
	set_qty(item_info.qty)
	var item_type = Data.lookup[item_info.type]
	$icon.texture = Data.data[item_type][item_info.id].icon

func set_qty(item_qty):
	qty = item_qty
	if qty == 1: $quantity.hide()
	else: 
		$quantity.text = str(qty)
		$quantity.margin_left = -$quantity.get_minimum_size().x

func set_size(size):
	rect_min_size = size
	rect_size = size

func _pressed():
	Dispatcher.emit_signal("item_selected", index)