extends CanvasLayer

signal closed

func print_children():
	var children = ""
	for child in get_children():
		children += child.get_name() + ", "
	print(children)

func open_menu(menu):
	load_menu(menu)
	print_children()
	get_node(menu).set_focus_mode(Control.FOCUS_ALL)
	get_node(menu).grab_focus()

func close_menu(menu):
	var menu_node = get_node(menu)
	menu_node.connect("closed", Callable(self, "_on_child_closed").bind(menu))
	menu_node.close()

func _on_child_closed(menu):
	print("ui: child closed - ", menu)
	get_node(menu).queue_free()
	emit_signal("closed", menu)

func load_menu(menu):
	var new_node = load("res://ui/" + menu + ".tscn").instantiate()
	add_child(new_node)