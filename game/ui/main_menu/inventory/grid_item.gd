extends Control

var qty
var index

func _ready():
	connect("focus_entered", self, "_pressed")

# the notion of an inventory "item" is a bit misleading in
# our terminology, since an Item is already a kind of thing
# in the game. actually, the player's inventory can have
# both Items and Objects, and possibly other things as well.
#
# the data files for game entities are organized by type, so 
# we need to look up the type of each "item" in order to set
# our properties. `Data.lookup` holds a map of EntityTypes 
# to directory-names-as-data-keys (eg. "monsters", "items").
func initialize(i, item, props):
	index = i
	set_size(props.item_size)
	set_qty(item.qty)
	$icon.texture = Data.get([item.id, "icon"])

func set_size(size):
	rect_min_size = size
	rect_size = size

func set_qty(item_qty):
	qty = item_qty
	if qty == 1: $quantity.hide()
	else:
		$quantity.text = str(qty)
		$quantity.margin_left = -$quantity.get_minimum_size().x

func _pressed():
	Dispatcher.emit("item_selected", index)

func show_quantity(show):
	if show && qty > 1: $quantity.show()
	else: $quantity.hide()