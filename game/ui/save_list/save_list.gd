extends Panel

onready var SaveItem = Utils.load_relative(filename, "save_item")

var saves = []
var current_page = 0 setget load_page
const SAVES_PER_PAGE = 3

func _ready():
	saves = SaveManager.get_save_info_list()
	$pages/arrows.connect("change_page", self, "change_page")
	load_page(0)

# --------------------------------------------------------------------------- #

func add_save_item(index, save_info):
	Log.verbose(self, ["adding save item: ", save_info])
	var save_item = SaveItem.instance()
	save_item.load_info(index, save_info)
	$container.add_child(save_item)

# --------------------------------------------------------------------------- #

func change_page(offset): load_page(current_page + offset)

func load_page(pagenum):
	Log.debug(self, ["loading page: ", pagenum, " | current page: ", current_page])
	if pagenum < 0 or pagenum >= saves.size():
		Log.error(self, ["could not load page ",
				pagenum, ": out of bounds"])
		return
	current_page = pagenum

	for child in $container.get_children():
		child.queue_free()

	var start = SAVES_PER_PAGE * pagenum
	for i in SAVES_PER_PAGE:
		if start + i < saves.size():
			add_save_item(i + 1, saves[i + start])

	update_page_display()

# --------------------------------------------------------------------------- #

func update_page_display():
	var total_pages = ((saves.size() - 1) / SAVES_PER_PAGE) + 1
	$pages.text = str(current_page + 1) + " / " + str(total_pages)
	$pages/arrows.update_visibility(current_page, total_pages)
