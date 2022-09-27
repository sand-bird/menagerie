extends Button

func _ready():
	connect("mouse_entered", self, "grab_focus")
	connect("mouse_exited", self, "release_focus")

var save_dir

func load_info(index, save_info):
	save_dir = save_info.save_dir
	$player_name/label.text = save_info.player_name
	$monsters/label.text = str(save_info.monsters)
	$money/label.text = str(save_info.money)
	$encyclopedia/label.text = str(save_info.encyclopedia, '%')
	$playtime/label.text = Player.get_printable_playtime(save_info.playtime)
	$time/label.text = Clock.get_printable_time(save_info.time)
	$index.text = str(index)

func _pressed():
	Dispatcher.emit_signal("ui_close")
	Dispatcher.emit_signal("load_game", save_dir)
