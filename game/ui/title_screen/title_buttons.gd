extends VBoxContainer

func _ready():
	if SaveUtils.get_save_list():
		$load_game.show()
	$load_game.grab_focus()
