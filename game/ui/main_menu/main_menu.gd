extends Control

const icon_dir = "res://assets/ui/icons/"
const menu_dir = "res://ui/main_menu/"

const chapters = {
	monsters = {
		icon = icon_dir + "monster.png",
		scene = menu_dir + "monsters/monsters.tscn"
	},
	items = {
		icon = icon_dir + "items.png",
		scene = menu_dir + "inventory/inventory.tscn"
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

onready var MenuTab = Utils.load_relative(filename, "menu_tab")

var current setget set_current
var current_scene
var next
var prev

func _ready():
	Dispatcher.connect("menu_open", self, "open")
	Dispatcher.connect("ui_close", self, "close")
	for id in chapters:
		new_tab(id, chapters[id])

# -----------------------------------------------------------

func new_tab(id, data):
	var tab = MenuTab.instance()
	tab.load_info(id, data)
	$content/tabs.add_child(tab)

# -----------------------------------------------------------

func set_current(val):
	if current == val: return # already current
	current = val
	Log.debug(self, ["setting current chapter: ", current])
	var tabs = $content/tabs.get_children()
	for i in tabs.size():
		if tabs[i].id == current:
			tabs[i].is_current = true
			next = tabs[i + 1].id if i < tabs.size() - 1 else tabs[0].id
			prev = tabs[i - 1].id if i > 0 else tabs[tabs.size() - 1].id
		else: tabs[i].is_current = false


# -----------------------------------------------------------

func open(input):
	var chapter = Utils.unpack(input)
	# update current_page (this is the page's string id)
	Log.debug(self, ["opening chapter: ", chapter, ", current: ", 
			current if current else "(none)"])
	if chapter == current or !(chapter in chapters.keys()): return
	set_current(chapter) # also updates tab z-indices
	
	# initialize new scene
	var new_scene = load(chapters[chapter].scene).instance()
	new_scene.connect("update_page_display", self, "update_page_display")
	new_scene.connect("update_title_display", self, "update_title_display")
	
	# update current scene (and destroy old scene)
	if (current_scene): 
		$content/book.remove_child(current_scene)
		current_scene.queue_free()
	current_scene = new_scene
	$content/book.add_child(current_scene)


func close():
	current = null
	queue_free()

# -----------------------------------------------------------

func update_page_display(text):
	$content/book/pages.text = text

func update_title_display(text):
	$content/book/title.text = text

# -----------------------------------------------------------

func _input(e):
	if e.is_action_pressed("ui_focus_prev"): open(prev)
	elif e.is_action_pressed("ui_focus_next"): open(next)
	else: return
	accept_event()
