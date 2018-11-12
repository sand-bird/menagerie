extends Control

onready var MenuTab = Utils.load_relative(filename, "menu_tab")

var current # id of the current chapter
var current_scene

# tab stuff
var next
var prev

var current_page
var page_count

func _ready():
	Dispatcher.connect("menu_open", self, "open")
	Dispatcher.connect("ui_close", self, "close")
	$content/arrows.connect("change_page", self, "_on_arrow")
	
	var chapters = Constants.MENU_CHAPTERS
	for id in chapters:
		if (!chapters[id].has("condition") or 
				Condition.resolve(chapters[id].condition)):
			new_tab(id, chapters[id])

# -----------------------------------------------------------

func new_tab(id, data):
	var tab = MenuTab.instance()
	tab.load_info(id, data)
	$content/tabs.add_child(tab)

# -----------------------------------------------------------

# updates our state and the tab array's state to reflect the
# newly opened menu chapter
func set_current(val):
	Log.debug(self, ["setting current chapter: '", current, "'"])
	current = val
	var tabs = $content/tabs.get_children()
	for i in tabs.size():
		if tabs[i].id == current:
			tabs[i].is_current = true
			next = tabs[i + 1].id if i < tabs.size() - 1 else tabs[0].id
			prev = tabs[i - 1].id if i > 0 else tabs[tabs.size() - 1].id
		else: tabs[i].is_current = false

# -----------------------------------------------------------

# triggered on a `menu_open` dispatch. 
func open(input = null):
	var chapter = Utils.unpack(input)
	if chapter == null: chapter = current
	Log.debug(self, ["opening chapter: '", chapter, "' | current: ", 
			str("'", current, "'") if current else "(none)"])
	
	var chapters = Constants.MENU_CHAPTERS
	if chapter == current or !(chapter in chapters.keys()): return
	set_current(chapter)
	
	# initialize new scene
	var new_scene = Utils.load_relative(filename, 
			chapters[chapter].scene).instance()
	
	new_scene.connect("page_info_changed", self, "_on_page_info_changed")
	new_scene.connect("title_changed", self, "_on_title_changed")
	
	# update current scene (and destroy old scene)
	if (current_scene):
		$content/book.remove_child(current_scene)
		current_scene.queue_free()
	current_scene = new_scene
	$content/book.add_child(current_scene)

# -----------------------------------------------------------

func close():
	current = null
	queue_free()

# -----------------------------------------------------------

func _on_arrow(offset):
	if current_scene and current_scene.has_method("change_page"):
		current_scene.change_page(offset)

# -----------------------------------------------------------

func _on_title_changed(text):
	$content/book/title.text = text

# -----------------------------------------------------------

func _on_page_info_changed(args):
	current_page = args[0]
	page_count = args[1]
	update_page_display()

# -----------------------------------------------------------

func update_page_display():
	$content/book/pages.text = str(current_page + 1) + " / " + str(page_count)
	$content/arrows.update_visibility(current_page, page_count)

# -----------------------------------------------------------

func _input(e):
	if e.is_action_pressed("ui_focus_prev"): open(prev)
	elif e.is_action_pressed("ui_focus_next"): open(next)
	else: return
	accept_event()
