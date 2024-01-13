extends PagedList

# initialize `data` in here
func initialize():
	pass

# should take in a slice of data the same length as page_size, and return an
# array of Control nodes which we will then add as children.
func load_items(_data_slice: Array[Variant]) -> Array[Control]:
	return []

# do whatever should be done when a child is selected.
# note: we might _always_ want to manage focus on select/deselect, so it may
# be better to do so outside these abstract functions.
func on_select(item: Control): item.grab_focus()

func on_deselect(item: Control): item.release_focus()

func on_page_changed(): pass
