extends Panel

onready var SaveItem = Utils.load_relative(filename, "save_item")

var saves
var current_page = 0 setget load_page
const SAVES_PER_PAGE = 3

func _ready():
	saves = SaveManager.get_save_info_list()
	load_page(0)

func add_save_item(index, save_info):
	Log.verbose(self, ["adding save item: ", save_info])
	var save_item = SaveItem.instance()
	save_item.load_info(index, save_info)
	$container.add_child(save_item)

func load_page(pagenum):
	current_page = pagenum
	
	for child in $container.get_children():
		child.queue_free()
	
	var start = SAVES_PER_PAGE * pagenum
	for i in SAVES_PER_PAGE:
		if start + i < saves.size():
			add_save_item(i + 1, saves[i + start])
