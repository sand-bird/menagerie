extends MenuSection

# we have two different versions of the inventory for different kinds of entity,
# items and objects/sessiles.  they are differentiated only by their title and
# initial filter (a data_filter that matches `type`).
# we know which inventory we are initializing based on the section key passed
# into the `initialize` function, either 'items' or 'objects'.
const TYPE_CONFIG = {
	items = { data_type = &'item', title = T.ITEMS },
	objects = { data_type = &'object', title = T.OBJECTS }
}

# see `filter_items` for usage.  we store filters in state so the item list
# can be refreshed when the inventory changes.
var data_filter: Callable # Dict (data def) -> bool
var state_filter: Callable # Dict (serialized state) -> bool

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready():
	Player.inventory_changed.connect(refresh_items)

# --------------------------------------------------------------------------- #

func initialize(key = 'items'):
	var config = TYPE_CONFIG[key]
	title = tr(config.title)
	data_filter = func (data): return data.type == config.data_type
	var indices = filter_items()
	$item_grid/items.selected_changed.connect(update_item_details)
	$item_grid.initialize(indices)

# --------------------------------------------------------------------------- #

# returns an array of inventory pointers: 2-element arrays, id and index.
# each identifies a "stack" in `Player.inventory`, which can have multiple
# stacks for the same entity id if they have different state.
#
# there are two ways to filter a stack: based on data (shared by all stacks with
# the same entity id, and based on state (unique to a stack).
# the latter is more costly because it requires checking all the stacks for each
# id in the inventory, so we skip calling it if null is passed.
func filter_items():
	var results = []
	for id in Player.inventory:
		var data = Data.fetch(id)
		if data == null: continue  # dw, Data.fetch already logged it
		if !data_filter.is_null() and !data_filter.call(data): continue
		
		var stacks = Player.inventory[id]
		for i in stacks.size(): # need to iterate over stacks to push each index
			if state_filter.is_null() or state_filter.call(stacks[i]):
				results.push_back([id, i])
	return results

# --------------------------------------------------------------------------- #

# state lives in $item_grid/items.  it's initially set through $item_grid's
# initialize function, but on refresh we can just set it directly.
func refresh_items(): $item_grid/items.data = filter_items()


# =========================================================================== #
#                         U P D A T I N G   S T A T E                         #
# --------------------------------------------------------------------------- #

func update_item_details(_selected: int, iref):
	if iref == null:
		Log.warn(self, "(update_item_details) unexpected: no item selected")
		return
	var item = Player.inventory_get(iref)
	$item_info.update_item(item)
