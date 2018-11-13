extends Button

var qty
var index

# the notion of an inventory "item" is a bit misleading in
# our terminology, since an Item is already a kind of thing
# in the game. i couldn't come up with a better term though.

# item data, like quantity and state if there is any, is
# stored inside the Player singleton. the inventory ui only
# stores pointers to this data.
#
# here we are dealing with one specific "item" from the ui's
# list. we receive its index in the grid (for communicating
# what's been selected, i think?), and its data, which is the
# pointer. the "props" argument contains size info for the
# element, depending on the user's grid_size setting.
func initialize(i, iref, props):
	index = i
	set_size(props.item_size)
	var item = Player.inventory[iref]
	set_qty(item.qty)
	$icon.texture = Data.get_resource([item.id, "icon"])

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
	Dispatcher.emit_signal("item_selected", index)

func show_quantity(show):
	if show && qty > 1: $quantity.show()
	else: $quantity.hide()
