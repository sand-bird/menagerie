extends Node

var garden = load("res://garden/garden.tscn").instance()

func _ready(): 
	print("game ready!")
	new_game()
	pass

func new_game():
	garden.initialize()
	add_child(garden)

func load_game():
	add_child(garden)