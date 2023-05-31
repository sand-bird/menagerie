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
# pointer. the "item_size" argument contains size info for
# the element, depending on the parent ItemGrid's grid_size.
func initialize(i, iref, item_size):
	index = i
	set_size(item_size)
	var item = Player.inventory_get(iref)
	set_qty(item.qty)
	$icon.texture = Data.fetch_res([item.id, "icon"])

# g4 complains about overriding native set_size - not sure if we need this
#	func set_size(size, _keep_margins = false):
#		custom_minimum_size = size
#		size = size

func set_qty(item_qty):
	qty = item_qty
	if qty == 1: $quantity.hide()
	else:
		$quantity.text = str(qty)
		$quantity.offset_left = -$quantity.get_minimum_size().x

func _pressed():
	Dispatcher.emit_signal("item_selected", index)

func show_quantity(show):
	if show && qty > 1: $quantity.show()
	else: $quantity.hide()
