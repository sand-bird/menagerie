extends Node

signal new_game
signal load_game
signal save_game
signal quit_game

signal ui_open(args)
signal ui_close

signal menu_open(args)

# emitted by grid_items in the inventory page of the main menu
signal item_selected(item_info)

func _ready():
	Log.info(self, "Dispatcher loaded!")

func _unhandled_input(e):
	if e.is_action("ui_menu"): emit_signal("menu_open")
	elif e.is_action("ui_menu_monsters"): emit_signal("menu_open", "monsters")