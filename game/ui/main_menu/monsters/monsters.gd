extends "res://ui/main_menu/menu_page.gd"

func _ready():
	title = "Monsters"
	initialize()

func initialize():
	.initialize()
	# specific stuff goes here

func get_page_display():
	return "mon"