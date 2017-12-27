extends CanvasLayer

var menu_stack = []

func open_menu(menu):
	if menu_stack.find_last(menu) != -1: return
	menu_stack.append(menu)
	load_menu(menu)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().set_pause(true)

func switch_menu(menu):
	close_menu()
	open_menu(menu)

func close_menu():
	if menu_stack.empty(): return false
	menu_stack.pop_front()
	# trying to save the node in menu stack to pass it
	# in here is not working, so let's just do this
	remove_child(get_children().back())
	if menu_stack.empty(): get_tree().set_pause(false)
	return true

func load_menu(menu):
	add_child(load("res://ui/" + menu + ".tscn").instance())