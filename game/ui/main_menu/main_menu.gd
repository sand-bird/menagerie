extends Control

enum menu_pages_enum {
	MONSTERS = 0,
	INVENTORY = 1,
	MAP = 2,
	CALENDAR = 3,
	ENCYCLOPEDIA = 4,
	OPTIONS = 5
}

var current_page setget set_current_page
var current_scene

const icon_dir = "res://assets/ui/icons/"
const menu_dir = "res://ui/main_menu/"

const MenuTab = preload("res://ui/main_menu/menu_tab.tscn")

const menu_pages = {
	monsters = {
		icon = icon_dir + "monster.png",
		scene = menu_dir + "monsters/monsters.tscn"
	},
	inventory = {
		icon = icon_dir + "inventory.png",
		scene = menu_dir + "inventory/inventory.tscn"
	},
	town_map = {
		icon = icon_dir + "town.png",
		scene = menu_dir + "town_map/town_map.tscn"
	},
	calendar = {
		icon = icon_dir + "calendar.png",
		scene = menu_dir + "calendar/calendar.tscn"
	},
	encyclopedia = {
		icon = icon_dir + "encyclopedia.png",
		scene = menu_dir + "encyclopedia/encyclopedia.tscn"
	},
	options = {
		icon = icon_dir + "options.png",
		scene = menu_dir + "options/options.tscn"
	}
}

func _ready():
	Dispatcher.connect("menu_open", self, "open")
	Dispatcher.connect("ui_close", self, "close")
	for page in menu_pages:
		new_tab(page, menu_pages[page])
	pass

func new_tab(page, data):
	var tab = MenuTab.instance()
	print(page)
	tab.load_info(page, data)
	$content/tabs.add_child(tab)

func set_current_page(val):
	if current_page == val: return # already current
	current_page = val
	print("current page: ", current_page)
	for tab in $content/tabs.get_children():
		tab.is_current = (tab.id == current_page)

func open(input_page):
	var page = Utils.unpack(input_page)
	# update current_page (this is the page's string id)
	print("opening: ", page, " | current: ", current_page)
	if page == current_page or !(page in menu_pages.keys()): return
	set_current_page(page) # also updates tab z-indices
	
	# initialize new scene
	var new_scene = load(menu_pages[page].scene).instance()
	new_scene.connect("update_page_display", self, "update_page_display")
	new_scene.connect("update_title_display", self, "update_title_display")
	
	# update current scene (and destroy old scene)
	if (current_scene): 
		$content/book.remove_child(current_scene)
		current_scene.queue_free()
	current_scene = new_scene
	$content/book.add_child(current_scene)

func close():
	current_page = null
	queue_free()

func update_page_display(text):
	$content/book/pages.text = text

func update_title_display(text):
	$content/book/title.text = text