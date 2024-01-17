extends NinePatchRect
"""
A grid of items with a sliding selector.  Uses PagedList internally.
Works with two grid sizes: small is 6x6, and large is 5x5.  Currently the grid
size is determined by Options.inventory_size since this component is only used
inside the inventory menu.

Ideally this would be generic enough to use outside the inventory menu, eg in
an NPC shop.  However, it currently works with pointers to the inventory - each
element in the `data` param to `initialize` (stored in $items) is an array of
[id, index] that points to a "stack" in the inventory.  This will need to be
refactored if we want to use item_grid elsewhere.
"""

const PROPERTIES = {
	Options.InventorySize.SMALL: {
		grid_bg = "item_grid_small_9patch",
		selector = "selector_small",
		item_size = Vector2(20, 20)
	},
	Options.InventorySize.LARGE: {
		grid_bg = "item_grid_large_9patch",
		selector = "selector_big",
		item_size = Vector2(24, 24)
	}
}
var grid_size: Options.InventorySize = Options.InventorySize.SMALL
var props:
	get: return PROPERTIES[grid_size]

# --------------------------------------------------------------------------- #

func initialize(data: Array):
	grid_size = Options.inventory_size
	$items.grid_size = grid_size
	$items.data = data
	init_selector()
	$items.selected_changed.connect(move_selector)
	texture = U.load_resource(Constants.UI_ELEMENT_PATH, props.grid_bg)
	size = calc_size(props.item_size)
	patch_margin_left = props.item_size.x + 2
	patch_margin_right = props.item_size.y + 1
	patch_margin_top = patch_margin_left
	patch_margin_bottom = patch_margin_right

# --------------------------------------------------------------------------- #

func calc_size(item_size):
	var inner_squares = Vector2($items.columns - 2, $items.rows - 2)
	return (
		item_size + Vector2(1, 1) +
		item_size + Vector2(2, 2) +
		((item_size + Vector2(3, 3)) * inner_squares)
	)

# =========================================================================== #
#                      S E L E C T O R   C O N T R O L S                      #
# --------------------------------------------------------------------------- #

func init_selector():
	$selector.hide()
	$selector.texture = U.load_resource(Constants.UI_ELEMENT_PATH, props.selector)
	var selector_pos = get_selector_dest()
	$selector.position = selector_pos
	$selector.dest_pos = selector_pos

# --------------------------------------------------------------------------- #

func move_selector(index, _data):
	if index < 0:
		$selector.hide()
		return
	$selector.move_to(get_selector_dest())
	$selector.show()

# --------------------------------------------------------------------------- #

# gets the pixel coordinates for our selector's destination based on the
# item-grid index it wants to move to. (TODO: something about that magic 3x3
# vector - i forgot exactly what it was supposed to be for. spacing maybe?)
func get_selector_dest():
	var base_pos = -Vector2(4, 4)
	var coords = Vector2($items.column, $items.row)
	Log.debug(self, ["(get_selector_dest) destination coords: ", coords])
	var item_offset = coords * (props.item_size + Vector2(3, 3))
	return base_pos + item_offset
