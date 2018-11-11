extends VBoxContainer

func _ready():
	if SaveManager.get_save_list(): $load_game.show()
