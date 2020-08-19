tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("EventButton", "Button", preload("button.gd"), preload("icon_button.png"))

func _exit_tree():
	remove_custom_type("EventButton")
