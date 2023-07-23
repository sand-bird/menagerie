extends PagedList

var ListItem = preload("res://ui/main_menu/monsters/monster_list_item.tscn")

func initialize(_arg = null):
	data = Player.garden.monsters.values() if Player.garden != null else []
	Dispatcher.menu_set_title.emit(tr(T.MONSTERS))

# data_slice is Array[Monster] in this case
func load_items(data_slice: Array) -> Array[Control]:
	var new_items: Array[Control] = []
	for i in data_slice.size():
		var monster = data_slice[i]
		var item = ListItem.instantiate()
		item.initialize(monster)
		new_items.push_back(item)
	return new_items

func on_page_changed():
	Dispatcher.menu_set_pages.emit(page, page_count)
