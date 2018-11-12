extends Control

signal title_changed(text)
signal page_info_changed(text)

const DEFAULT_TITLE = "\u2727 \u2726 \u2727"
var title = DEFAULT_TITLE setget set_title

var prev_item = 0
var current_item = 0
var current_page = 0 setget set_current_page
var page_count = 0 setget set_page_count

func initialize():
	emit_signal("title_changed", title)

func set_title(val):
	title = val
	emit_signal("title_changed", title)

func set_current_page(new_page):
	current_page = new_page
	emit_signal("page_info_changed", [current_page, page_count])

func set_page_count(val): 
	page_count = val
	emit_signal("page_info_changed", [current_page, page_count])

func is_valid():
	return true
