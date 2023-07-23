extends PagedList

const PROPERTIES = {
	Constants.GridSize.SMALL: {
		item_size = Vector2(20, 20),
		columns = 6,
		rows = 6
	},
	Constants.GridSize.LARGE: {
		item_size = Vector2(24, 24),
		columns = 5,
		rows = 5
	}
}
var grid_size: Constants.GridSize:
	set(x):
		grid_size = x
		# update rows and columns whenever the grid size is updated
		for prop in [&'columns', &'rows']:
			set(prop, PROPERTIES[grid_size][prop])

var GridItem = preload("res://ui/main_menu/inventory/grid_item.tscn")

# should take in a slice of data the same length as page_size, and return an
# array of Control nodes which we will then add as children.
func load_items(data_slice: Array[Variant]) -> Array[Control]:
	var new_items: Array[Control] = []
	for data in data_slice:
		var item = GridItem.instantiate()
		item.initialize(data, PROPERTIES[grid_size].item_size)
		new_items.push_back(item)
	return new_items

# note: item_grid moves the selector on a selected_changed signal.
# focus is irrelevant for now, but will be meaningful if we add a context menu
# on a second interaction with an already-selected item
func on_select(item: Control):
	item.show_quantity(false)
	item.grab_focus()

func on_deselect(item: Control):
	item.show_quantity(true)
	item.release_focus()

func on_page_changed(page: int):
	Dispatcher.menu_set_pages.emit(page, page_count)
