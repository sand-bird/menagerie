extends Panel

const SaveItem = preload("res://ui/title/save_item.tscn")

func _ready():
	for save_info in SaveManager.get_save_info_list():
		add_save_item(save_info)

func add_save_item(save_info):
	var save_item = SaveItem.instance()
	print(save_info)
	save_item.load_info(save_info)
	$scroll_container/container.add_child(save_item)