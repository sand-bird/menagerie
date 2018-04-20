extends Node

var garden = load("res://garden/garden.tscn").instance()

func _ready(): 
	print("game ready!")
	EventManager.connect("new_game", self, "new_game")
	# new_game()
	pass

func new_game():
	print("game.gd: starting new game")
	garden.initialize()
	add_child(garden)

func load_game():
	add_child(garden)