extends CanvasLayer

signal closed

#onready var fader = get_node("fader")
func print_children():
	var children = ""
	for child in get_children():
		children += child.get_name() + ", "
	print(children)
	

func open_menu(menu):
#	var anim = fader.get_animation("fade_in")
	load_menu(menu)
	print_children()
	get_node(menu).set_focus_mode(Control.FOCUS_ALL)
	get_node(menu).grab_focus()

func close_menu(menu):
	# trying to save the node in menu stack to pass it
	# in here is not working, so let's just do this
#	print("before fade out")
#	fader.fade_out(menu, 1.5)
#	yield(fader, "finished")
#	print("after fade out")
	var fader = get_node(menu + "/fader")
	fader.play("fade_out")
	yield(fader, "finished")
	remove_child(get_node(menu))
	emit_signal("closed", menu)
#	remove_child(get_children().back())

func load_menu(menu):
	var new_node = load("res://ui/" + menu + ".tscn").instance()
	new_node.add_child(load("res://ui/fader.tscn").instance())
	add_child(new_node)
#	add_child(new_node)
#	print("before fade in")
#	fader.fade_in(menu, 0.8)
#	yield(fader, "finished")
#	print("after fade in")