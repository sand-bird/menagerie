extends Node

signal new_game
signal load_game
signal save_game
signal quit_game

signal ui_open(args)
signal ui_close

signal menu_open(args)

func _ready():
	print("Dispatcher loaded!")

func _unhandled_input(e):
	if e.is_action_type():
		print(e)