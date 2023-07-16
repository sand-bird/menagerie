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

func _ready():
	Dispatcher.menu_open.connect(open)
	Dispatcher.menu_set_title.connect(set_title)
	Dispatcher.menu_set_pages.connect(set_pages)


# =========================================================================== #
#                               C H A P T E R S                               #
# --------------------------------------------------------------------------- #

# triggered on a `menu_open` dispatch.
func open(input = null):
	var chapter = U.unpack(input)
	if chapter == null:
		Log.warn(self, "unexpected: someone dispatched called menu_open while menu was already open without a chapter argument. did we want to close insted?")
		return
	
	Log.debug(self, ["(open) menu chapter: '", chapter])

	var chapter_info = get_chapter_info(chapter)
	if chapter_info == null:
		Log.error(self, ["(open) menu chapter '", chapter, "' not found!"])
		return
	load_chapter(chapter_info.scene)
	$tabs.open(chapter)

# --------------------------------------------------------------------------- #

func load_chapter(scene_path):
	# in case our new scene doesn't override all the header info set by our
	# last scene, we reset it to default
	reset_headers()
	# destroy the old chapter (todo: only do this if it's different)
	for child in $book/chapter.get_children():
		child.queue_free()
	
	var chapter = U.load_relative(scene_file_path, scene_path).instantiate()
	chapter.open()
	
	$book/chapter.add_child(chapter)

# --------------------------------------------------------------------------- #

func get_chapter_info(chapter):
	if CHAPTERS.has(chapter):
		return CHAPTERS[chapter]


# =========================================================================== #
#                                H E A D E R S                                #
# --------------------------------------------------------------------------- #
# the title and page number nodes are children of main_menu, so we control their
# displays here from signals sent by property setters in our menu chapters.

func set_title(text):
	$book/title.text = text

func set_pages(current: int, total: int):
	$book/pages.text = (
		str(current + 1, " / ", total) if total > 0 else "~ * ~"
	)
	$arrows.update_visibility(current, total)

func reset_headers():
	set_title("~ * ~")
	set_pages(0, 0)
