extends Control

signal update_page_display(text)
signal update_title_display(text)

var title

func initialize():
	emit_signal("update_title_display", title)
	emit_signal("update_page_display", "\u2727 \u2726 \u2727")