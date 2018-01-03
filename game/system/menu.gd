# class Menu

extends Node

onready var ui = get_tree().get_root().get_node("game/ui")
var menu_stack = []

func open(menu):
	if menu_stack.find_last(menu) != -1: return
	menu_stack.append(menu)
	ui.open_menu(menu)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().set_pause(true)

func change(menu):
	close()
	open(menu)

func close():
	if menu_stack.empty(): return false
	var menu = menu_stack.back()
	print("entering menu_close")
	ui.close_menu(menu)
	print("exiting menu_close")
	menu_stack.pop_back()
	if menu_stack.empty(): get_tree().set_pause(false)
	return true