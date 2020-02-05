extends "res://ui/main_menu/menu_chapter.gd"

# var Wrap = Constants.Wrap

onready var props = Constants.INVENTORY_PROPERTIES[Options.inventory_size]

# as in "inventory item", not as in Item (the specific type of game entity).
# unfortunately ambiguous, but i couldn't come up with any decent alternatives :(
#
# an array of ints, each an index within Player.inventory. represents the
# subset of the player's inventory that we can SEE & INTERACT WITH. possible
# reasons an inventory item doesn't show up in this list:

# - it's being filtered out by our current filter settings
# - the data for its entity id was not found; an uncommon but expected case,
#   eg. if an entity belongs to a mod that's currently disabled.
onready var items = []

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #
func _ready():
	Dispatcher.connect("item_selected", self, "update_current_item")

# --------------------------------------------------------------------------- #

func initialize(filter = {}):
	# init self
	items = filter_items(filter)

	# init item grid
	$item_grid.initialize(props, {items = items})
	if items: update_current_item(0)

	.initialize()

# --------------------------------------------------------------------------- #

func filter_items(filter: Dictionary):
	var results = []
	for i in Player.inventory.size():
		var id = Player.inventory[i].id
		var data = Data.get(id)
		if !data: continue  # dw, Data.get already logged it
		var matches = true
		for key in filter.keys():
			if !data.has(key) or data[key] != filter[key]:
				matches = false
				break
		if matches:
			Log.info(self, [id, " passed filter!"])
			results.append(i)
	return results


# =========================================================================== #
#                         U P D A T I N G   S T A T E                         #
# --------------------------------------------------------------------------- #
func update_current_item(new_index):
	$item_grid.update_current_item(new_index)
	update_item_details(new_index)
	current_item = new_index

# --------------------------------------------------------------------------- #

func update_item_details(index):
	var item = get_item(index)
	$item_info.update_item(item.id, item.qty)

# --------------------------------------------------------------------------- #

# fetches actual item data from the Player global
func get_item(index):
	return Player.inventory[items[index]]
