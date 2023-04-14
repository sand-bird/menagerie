extends Control

signal title_changed(text)
signal page_info_changed(text)

var title : set = set_title

# var prev_item = 0
var current_item = 0
var current_page = 0: set = set_current_page
var page_count = 0: set = set_page_count

func initialize(args = null):
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
