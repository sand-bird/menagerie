extends Control

signal update_page_display(text)
signal update_title_display(text)

var title

func initialize():
	emit_signal("update_page_display", get_page_display())
	emit_signal("update_title_display", title)

func get_page_display():
	return "98 / 99"