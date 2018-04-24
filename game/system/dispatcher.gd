extends Node

signal new_game
signal load_game
signal save_game
signal quit_game

signal open_menu(args)
signal close_menu

func _ready():
	print("Dispatcher loaded!")

func _unhandled_input(e):
	if e.is_action_type():
		print(e)