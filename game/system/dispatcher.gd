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
	print("Dispatcher loaded!")

func _unhandled_input(e):
	if e.is_action_type():
		print(e)