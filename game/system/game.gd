extends Node

var current_menu
var last_menu
# onready var screen = get_node("screen")
# onready var ui = get_node("ui")

func _ready(): pass
#	set_process_input(true)
#	change_screen("garden")

func change_screen(scene): pass
#	screen.remove_child(screen.get_child(0))
#	screen.add_child(load("res://" + scene + "/" + scene + ".tscn").instance())
#	ui.get_node(scene).show()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		do_esc()
	elif event.is_action_pressed("ui_accept"):
		Menu.change("save_list")

func do_esc():
	if !Menu.close(): Menu.open("pause_menu")