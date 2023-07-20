extends PagedList

@onready var SaveItem = preload("res://ui/save_list/save_item.tscn")

# should initialize `data`.
func initialize():
	data = SaveUtils.get_save_info_list()

# should take in a slice of data the same length as page_size, and return an
# array of Control nodes which we will then add as children.
func load_items(data_slice: Array) -> Array[Control]:
	var new_items: Array[Control] = []
	for i in data_slice.size():
		var save_info = data_slice[i]
		var save_item = SaveItem.instantiate()
		save_item.load_info(i, save_info)
		new_items.push_back(save_item)
	return new_items

# do whatever should be done when a child is selected.
func on_select(item: Control):
	item.grab_focus()

func on_deselect(item: Control):
	item.release_focus()
