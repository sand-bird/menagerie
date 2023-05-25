extends Control

@onready var MenuTab = Utils.load_relative(scene_file_path, 'menu_tab')

const DEFAULT_TITLE = "\u2727 \u2726 \u2727"

var current # id of the current chapter
var current_scene # scene pointer for curent chapter

# tab stuff
var next
var prev

func _ready():
	Dispatcher.menu_open.connect(open)
	$content/arrows.change_page.connect(_on_arrow)
	open("items")
	make_tabs()


# =========================================================================== #
#                                   T A B S                                   #
# --------------------------------------------------------------------------- #

func make_tabs():
	var chapters = Constants.MENU_CHAPTERS
	for id in chapters:
		if (!chapters[id].has('condition') or
				Condition.resolve(chapters[id].condition)):
			new_tab(id, chapters[id])

# --------------------------------------------------------------------------- #

func new_tab(id, data):
	var tab = MenuTab.instantiate()
	tab.load_info(id, data)
	$content/tabs.add_child(tab)


# =========================================================================== #
#                               C H A P T E R S                               #
# --------------------------------------------------------------------------- #

# triggered on a `menu_open` dispatch.
func open(input = null):
	var chapter = Utils.unpack(input)
	if chapter == null: chapter = current
	Log.debug(self, ["(open) menu chapter: '", chapter, "' | current: ",
			str("'", current, "'") if current else "(none)"])

	var chapter_info = get_chapter_info(chapter)
	if chapter_info == null:
		Log.error(self, ["(open) menu chapter '", chapter, "' not found!"])
		return
	load_scene(chapter_info.scene)
	set_current(chapter)

# --------------------------------------------------------------------------- #

# updates our state and the tab array's state to reflect the newly opened menu
# chapter.
func set_current(chapter):
	current = chapter
	Log.debug(self, ["(set_current) chapter: '", current, "'"])

	# update tabs
	var tabs = $content/tabs.get_children()
	for i in tabs.size():
		if tabs[i].id == current:
			tabs[i].is_current = true
			next = tabs[i + 1].id if i < tabs.size() - 1 else tabs[0].id
			prev = tabs[i - 1].id if i > 0 else tabs[tabs.size() - 1].id
		else: tabs[i].is_current = false

# --------------------------------------------------------------------------- #

func load_scene(scene_path):
	# in case our new scene doesn't override all the header info set by our
	# last scene, we reset it to default
	reset_headers()

	var new_scene = Utils.load_relative(scene_file_path, scene_path).instantiate()
	new_scene.page_info_changed.connect(_on_page_info_changed)
	new_scene.title_changed.connect(_on_title_changed)

	# update current scene (and destroy old scene)
	if (current_scene):
		$content/book/chapter.remove_child(current_scene)
		current_scene.queue_free()
	current_scene = new_scene
	#  note that the new chapter sends some signals to tell us to update stuff
	#  when it is initialized through _ready. it's working now, which i guess
	#  means _ready is called when a node is added to the scene tree. if
	# chapter info ever mysteriously breaks after a godot update, look here.
	$content/book/chapter.add_child(current_scene)

# --------------------------------------------------------------------------- #

func get_chapter_info(chapter):
	var chapters = Constants.MENU_CHAPTERS
	if chapters.has(chapter):
		return chapters[chapter]


# =========================================================================== #
#                                H E A D E R S                                #
# --------------------------------------------------------------------------- #
# the title and page number nodes are children of main_menu, so we control their
# displays here from signals sent by property setters in our menu chapters.

#                                s e t t e r s
# --------------------------------------------------------------------------- #

func set_title(text):
	$content/book/title.text = text

func set_page_text(text):
	$content/book/pages.text = text

func set_arrow_visibility(c, t):
	$content/arrows.update_visibility(c, t)

func reset_headers():
	set_title(DEFAULT_TITLE)
	set_page_text(DEFAULT_TITLE)
	set_arrow_visibility(0, 0)

#                               t r i g g e r s
# --------------------------------------------------------------------------- #

func _on_arrow(offset):
	if current_scene and current_scene.has_method('change_page'):
		current_scene.change_page(offset)

func _on_title_changed(text):
	set_title(text)

# args is: [current_page, total_pages]
func _on_page_info_changed(args):
	set_page_text(str(args[0] + 1, " / ", args[1]))
	set_arrow_visibility(args[0], args[1])

# --------------------------------------------------------------------------- #

func _input(e):
	if e.is_action_pressed('ui_focus_prev'): open(prev)
	elif e.is_action_pressed('ui_focus_next'): open(next)
	else: return
	accept_event()
