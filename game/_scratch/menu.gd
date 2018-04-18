# class Menu

extends Node

onready var ui = get_tree().get_root().get_node("game/ui")
var menu_stack = []

func open(menu):
	print(menu_stack)
	if menu_stack.has(menu): 
		print("MENU ALREADY OPEN! ", menu)
		return
	menu_stack.append(menu)
	print("open: ", menu_stack)
#	ui.open_menu(menu)
#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#	get_tree().set_pause(true)

func change(menu):
	close()
	open(menu)

func close():
	if menu_stack.empty(): return false
	var menu = menu_stack.back()
#	print("close: ", menu_stack)
#	print("entering menu_close")
#	ui.close_menu(menu)
#	yield(ui, "closed")
#	print("exiting menu_close")
	menu_stack.pop_back()
#	if menu_stack.empty(): get_tree().set_pause(false)
	return true