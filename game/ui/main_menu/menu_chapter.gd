extends Control
class_name MenuChapter
"""
base class for menu chapters; implements nagivation logic general to all menu
chapters.  individual chapters should extend this class and implement their own
logic for initializing their sections based on game state.
"""

var sections: MenuSection

# stubbing this for the monsters chapter since that's our first use case
func load_sections():
	# create a section for the monster list
	
	for monster in Player.garden.monsters:
		# create a section for that monster's description
		pass

signal title_changed(text)
signal page_info_changed(text)

var title : set = set_title

# var prev_item = 0
var current_item = 0
var current_page = 0: set = set_current_page
var page_count = 0: set = set_page_count

func initialize(_args = null):
	emit_signal('title_changed', title)

func set_title(val):
	title = val
	emit_signal('title_changed', title)

func set_current_page(new_page):
	current_page = new_page
	emit_signal('page_info_changed', [current_page, page_count])

func set_page_count(val):
	page_count = val
	emit_signal('page_info_changed', [current_page, page_count])

func is_valid():
	return true
