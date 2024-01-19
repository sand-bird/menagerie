class_name MenuSection
extends Control
"""
base class for menu sections; implements nagivation logic general to all menu
sections.  individual sections should extend this class and implement their own
logic for initializing their pages based on game state.

initialize(key):
- set title and pages
- open first page

open(page):
- free previous children if any
- add children for current page
- focus appropriate child (depends on pagination direction)
"""

var title: String:
	set(new):
		title = new
		Dispatcher.menu_set_title.emit(title)

var pages: int:
	set(new):
		pages = new
		Dispatcher.menu_set_pages.emit(current, pages)

var current: int = -1:
	set(new):
		current = new
		Dispatcher.menu_set_pages.emit(current, pages)

# --------------------------------------------------------------------------- #

func _ready():
	# size of the usable area in the menu ui (page space under the headers)
	custom_minimum_size = Vector2(296, 142)
	print('menu_section _ready')
	Dispatcher.menu_next_page.connect(next_page)
	Dispatcher.menu_prev_page.connect(prev_page)
	open(0)

func open(page: int = 0, from_right = false):
	print('menu-section open ', page)
	if page == current: return
	if page < 0 or page >= pages: return
	current = page
	load_page(page)
	focus(from_right)

func next_page():
	print('next page')
	open(current + 1)
func prev_page():
	print('prev page')
	open(current - 1, true)

func _input(e: InputEvent):
	if e.is_action_pressed('ui_right') and can_next_page(): next_page()
	if e.is_action_pressed('ui_left') and can_prev_page(): prev_page()


#                               a b s t r a c t                               #
# --------------------------------------------------------------------------- #

# pseudo-constructor, called from `menu_chapter` when it loads a section.
# menu sections sometimes take params (ie, a monster uuid), but are stored as
# PackedScenes because they are full of fiddly ui bits.
# this _should_ be called before `_ready` since we call it before adding the
# section as a child of the chapter, but we should test to be sure.
func initialize(_key = null): pass

# given a page index, render that page.
func load_page(_page: int): pass

# focus the appropriate child.  `from_right` is true when navigating back via
# `prev_page`, meaning we should focus the rightmost child instead of the left.
func focus(_from_right = false): pass

# the ui_right/ui_left inputs should turn the page if the focused element is on
# the far right or left side of the page.  it seems the easiest way to check for
# this is to let subclasses determine it by overriding these functions.
func can_next_page() -> bool: return false
func can_prev_page() -> bool: return false
