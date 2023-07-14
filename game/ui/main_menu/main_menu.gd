extends Control
class_name MainMenu
"""
the book-shaped menu for most things in the game.

there are three levels to the main menu:

1. chapters
- monsters, items, objects, locations, etc.
- each of these has a corresponding tab at the top of the menu.
- navigate between chapters by clicking/pressing the tabs or with the
  `prev_chapter`/`next_chapter` inputs (bound to L2/R2 buttons).

2. sections
- multi-page units like monster descriptions or encyclopedia entries.
- each chapter can contain multiple sections.
- the current section determines the title displayed on the main menu
- navigate between sections by clicking/pressing the arrows on the left and
  right edges of the main menu, or with the `prev_section`/`next_section` inputs
  (bound to the L1/R1 buttons).
- on sections of a chapter after the first, the bookmark/tab for that chapter
  should no longer appear over the top of the page.  clicking it or pressing
  `prev_chapter` should navigate back to the first section of the chapter.

3. pages
- each section can contain multiple pages.
- the page counter on the main menu should show the current and total number of
  pages in the section.
- navigate between pages with the arrows left and right of the page counter, or
  the left/right buttons while focus is at the edge of the page

direct navigation:
- in addition to next and previous chapters/sections/pages, you must be able to
  navigate directly to a specific section/page (even in a different chapter).
- jump navigation should store the source page and allow the user to jump back
  to it using a `ui_cancel` input or a "back" button at the top-left of the menu
  (only shown when there is a source page to go back to).
"""


@onready var MenuTab = U.load_relative(scene_file_path, 'menu_tab')

const DEFAULT_TITLE = "1 / 1" #"\u2727 \u2726 \u2727"

const CHAPTERS = {
	monsters = {
		icon = "monster",
		scene = "monsters/monsters"
	},
	items = {
		icon = "items",
		scene = "inventory/items"
	},
	objects = {
		icon = "inventory",
		scene = "inventory/objects"
	},
	town_map = {
		icon = "town",
		scene = "town_map/town_map"
	},
	calendar = {
		icon = "calendar",
		scene = "calendar/calendar"
	},
	encyclopedia = {
		icon = "encyclopedia",
		scene = "encyclopedia/encyclopedia"
	},
	options = {
		icon = "options",
		scene = "options/options"
	}
}


var current # id of the current chapter
var current_scene # scene pointer for curent chapter

# tab stuff
var next
var prev

func _ready():
	Dispatcher.menu_open.connect(open)
	Dispatcher.menu_set_title.connect(set_title)
	Dispatcher.menu_set_pages.connect(set_pages)
	
	$content/arrows2/left.pressed.connect(
		func():
			print('left pressed')
			Dispatcher.menu_prev_page.emit()
	)
	$content/arrows2/right.pressed.connect(
		func():
			print('right pressed')
			Dispatcher.menu_next_page.emit()
	)
	
	$content/arrows.change_page.connect(_on_arrow)
	make_tabs()


# =========================================================================== #
#                                   T A B S                                   #
# --------------------------------------------------------------------------- #

func make_tabs():
	for id in CHAPTERS:
		var chapter = CHAPTERS[id]
		if (!chapter.has('condition') or
				Condition.resolve(chapter.condition)):
			new_tab(id, chapter)

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
	var chapter = U.unpack(input)
	if chapter == null: chapter = current
	Log.debug(self, ["(open) menu chapter: '", chapter, "' | current: ",
			str("'", current, "'") if current else "(none)"])

	var chapter_info = get_chapter_info(chapter)
	if chapter_info == null:
		Log.error(self, ["(open) menu chapter '", chapter, "' not found!"])
		return
	load_chapter(chapter_info.scene)
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

func load_chapter(scene_path):
	# in case our new scene doesn't override all the header info set by our
	# last scene, we reset it to default
	reset_headers()
	# destroy the old chapter (todo: only do this if it's different)
	for child in $content/book/chapter.get_children():
		child.queue_free()
	
	var chapter = U.load_relative(scene_file_path, scene_path).instantiate()
	chapter.open()
	
	$content/book/chapter.add_child(chapter)

# --------------------------------------------------------------------------- #

func get_chapter_info(chapter):
	if CHAPTERS.has(chapter):
		return CHAPTERS[chapter]


# =========================================================================== #
#                                H E A D E R S                                #
# --------------------------------------------------------------------------- #
# the title and page number nodes are children of main_menu, so we control their
# displays here from signals sent by property setters in our menu chapters.

#                                s e t t e r s
# --------------------------------------------------------------------------- #

func set_title(text):
	$content/book/title.text = text

func set_pages(current: int, total: int):
	$content/book/pages.text = (
		str(current + 1, " / ", total) if total > 0 else "~ * ~"
	)
	$content/arrows.update_visibility(current, total)

func reset_headers():
	set_title(DEFAULT_TITLE)
	set_pages(0, 0)

#                               t r i g g e r s
# --------------------------------------------------------------------------- #

func _on_arrow(offset):
	if current_scene and current_scene.has_method('change_page'):
		current_scene.change_page(offset)

# --------------------------------------------------------------------------- #

#func _input(e):
#	if e.is_action_pressed('ui_focus_prev'): open(prev)
#	elif e.is_action_pressed('ui_focus_next'): open(next)
#	else: return
#	accept_event()
