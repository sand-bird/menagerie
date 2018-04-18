extends Button

func _ready():
	connect("mouse_entered", self, "grab_focus")
	connect("mouse_exited", self, "release_focus")
	connect("button_down", self, "print_text", ["button down!"])
	connect("pressed", self, "print_text", ["button pressed!"])
	pass

func load_info(save_info):
	$player_name/label.text = save_info.player_name
	$time/label.text = Time.get_printable_time(save_info.time)
	$playtime/label.text = Player.get_printable_playtime(save_info.playtime)
	$money/label.text = str(save_info.money)

func print_text(txt):
	print(txt)