class_name MainMenu
extends Control
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

const DEFAULT_CHAPTER = &'monsters'
var current_chapter = null

@onready var chapters = {
	monsters = MenuChapter.Monsters.new(),
	items = MenuChapter.Items.new(),
	objects = MenuChapter.Objects.new(),
	town_map = MenuChapter.TownMap.new(),
	calendar = MenuChapter.Calendar.new(),
	encyclopedia = MenuChapter.Encyclopedia.new(),
	settings = MenuChapter.Settings.new()
}

func _ready():
	$tabs.initialize(chapters)
	Dispatcher.menu_set_title.connect(set_title)
	Dispatcher.menu_set_pages.connect(set_pages)


# =========================================================================== #
#                               C H A P T E R S                               #
# --------------------------------------------------------------------------- #

# called from Ui.open, which is triggered on a `menu_open` dispatch.
func open(input = null):
	var path = U.pack(input)
	var chapter_key = path[0] if !path.is_empty() else null
	if chapter_key == null:
		Log.warn(self, "unexpected: someone dispatched `menu_open` without an argument while menu was already open. did we want to close insted?")
		return
	if not chapter_key in chapters:
		Log.error(self, ["(open) menu chapter '", chapter_key, "' not found!"])
		return
	
	Log.debug(self, ["(open) menu chapter: '", chapter_key])
	
	reset()
	var dir = direction(path)
	# don't play the page turn anim when first opening the menu
	if dir != 0 and current_chapter != null:
		$tabs/current.z_index = 0
		$book/page_turn.play("default", dir, dir == -1)
		await $book/page_turn.animation_finished
	$tabs.open(path)
	$tabs/current.z_index = 1
	
	var section_key = U.aget(path, 1)
	var section = chapters[chapter_key].open(section_key)
	$book/chapter.add_child(section)
	current_chapter = chapter_key

# --------------------------------------------------------------------------- #

func direction(path) -> int:
	var new_chapter = path[0]
	var new_section = U.aget(path, 1)
	var keys = chapters.keys()
	var current_idx = keys.find(current_chapter)
	var new_idx = keys.find(new_chapter)
	var chapter_dir = (
		1 if new_idx > current_idx else
		-1 if new_idx < current_idx else 0
	)
	# if navigating to a different section within the same chapter,
	# use the new section's direction relative to the current section
	if chapter_dir != 0: return chapter_dir
	return chapters[new_chapter].direction(new_section)

# --------------------------------------------------------------------------- #

func reset() -> void:
	# in case our new scene doesn't override all the header info set by our
	# last scene, we reset it to default
	reset_headers()
	# destroy the old chapter (todo: only do this if it's different)
	for child in $book/chapter.get_children():
		child.queue_free()


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
