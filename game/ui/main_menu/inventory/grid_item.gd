extends Button

var qty: int

# iref is a pointer to a "stack" in Player.inventory.
# will need to be updated if we want to use this to represent items outside of
# the player's inventory, eg in NPC shops.
func initialize(iref, item_size: Vector2):
	custom_minimum_size = item_size
	size = item_size
	var item = Player.inventory_get(iref)
	if !item:
		Log.error(self, ['could not find item in inventory: ', iref])
		return
	set_qty(item.qty)
	$icon.texture = Data.fetch_res([item.id, "icon"])

func set_qty(item_qty: int):
	qty = item_qty
	if qty == 1: $quantity.hide()
	else:
		$quantity.text = str(qty)
		$quantity.offset_left = -$quantity.get_minimum_size().x

func show_quantity(yes: bool):
	if yes && qty > 1: $quantity.show()
	else: $quantity.hide()
