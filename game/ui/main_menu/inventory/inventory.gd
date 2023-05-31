extends "res://ui/main_menu/menu_chapter.gd"

const PROPERTIES = {
	Constants.InventorySize.SMALL: {
		cols = 6,
		rows = 6,
		grid_size = Constants.GridSize.SMALL,
	},
	Constants.InventorySize.LARGE: {
		cols = 5,
		rows = 5,
		grid_size = Constants.GridSize.LARGE,
	}
}

var props = PROPERTIES[Options.inventory_size]

# as in "inventory item", not as in Item (the specific type of game entity).
# an array of 2-element arrays: id and index.  each identifies a "stack" in
# `Player.inventory`, which can have multiple stacks for each entity id.
#
# represents the subset of the player's inventory that we can SEE & INTERACT
# WITH.  possible reasons an inventory item doesn't show up in this list:
# - it's being filtered out by our current filter settings
# - the data for its entity id was not found; an uncommon but expected case,
#   eg. if an entity belongs to a mod that's currently disabled.
@onready var indices = []

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #
func _ready():
	Dispatcher.item_selected.connect(update_current_item)

# --------------------------------------------------------------------------- #

func initialize(data_filter = null, state_filter = null):
	# init self
	indices = filter_items(data_filter, state_filter)

	# init item grid
	$item_grid.initialize(props, { items = indices })
	if indices: update_current_item(0)

	super.initialize()

# --------------------------------------------------------------------------- #

# there are two ways to filter a stack: based on data (shared by all stacks with
# the same entity id, and based on state (unique to a stack).
# the latter is more costly because it requires checking all the stacks for each
# id in the inventory, so we skip calling it if null is passed.
func filter_items(
	data_filter = null, # Dict (data def) -> bool
	state_filter = null # Dict (serialized state) -> bool
):
	var results = []
	for id in Player.inventory:
		var data = Data.fetch(id)
		if data == null: continue  # dw, Data.fetch already logged it
		if data_filter != null and !data_filter.call(data): continue
		
		var stacks = Player.inventory[id]
		for i in stacks.size():
			if state_filter == null or state_filter.call(stacks[i]):
				results.push_back([id, i])
	return results


# =========================================================================== #
#                         U P D A T I N G   S T A T E                         #
# --------------------------------------------------------------------------- #
# these functions operate on indices to the `indices` array

func update_current_item(i: int):
	$item_grid.update_current_item(i)
	update_item_details(i)
	current_item = i

# --------------------------------------------------------------------------- #

func update_item_details(i: int):
	var item = get_item(i)
	$item_info.update_item(item)

# --------------------------------------------------------------------------- #

# fetches actual item data from the Player global
func get_item(i: int):
	var index = indices[i]
	return Player.inventory_get(index)
