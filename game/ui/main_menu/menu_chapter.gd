extends Control

signal update_page_display(text)
signal update_title_display(text)

var title = "Default"

var prev_item = 0
var current_item = 0
var current_page = 0 setget update_current_page
var page_count = 0 setget update_page_count

func initialize():
	emit_signal("update_title_display", title)
	emit_signal("update_page_display", "\u2727 \u2726 \u2727")

func update_current_page(new_page):
	current_page = new_page
	update_page_display()
	update_title_display()

func update_page_display():
	var new_display = str(current_page + 1) + " / " + str(page_count)
	emit_signal("update_page_display", new_display)

func update_title_display():
	emit_signal("update_title_display", title)

func update_page_count(new_page_count):
	