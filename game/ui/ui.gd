extends CanvasLayer

onready var fader = get_node("fader")

func open_menu(menu):
	var anim = fader.get_animation("fade_in")	
	load_menu(menu)
	get_node(menu).set_focus_mode(Control.FOCUS_ALL)
	get_node(menu).grab_focus()

func close_menu(menu):
	# trying to save the node in menu stack to pass it
	# in here is not working, so let's just do this
	print("before fade out")
	fader.fade_out(menu, 1.5)
	yield(fader, "finished")
	print("after fade out")
	remove_child(get_node(menu))
#	remove_child(get_children().back())

func load_menu(menu):
	add_child(load("res://ui/" + menu + ".tscn").instance())
	print("before fade in")
	fader.fade_in(menu, 0.8)
	yield(fader, "finished")
	print("after fade in")