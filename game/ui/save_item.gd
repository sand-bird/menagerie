extends Button

func _ready():
	connect("mouse_entered", self, "grab_focus")
	connect("mouse_exited", self, "release_focus")
	pass

var save_name

func load_info(save_info):
	save_name = save_info.save_name
	$player_name/label.text = save_info.player_name
	$monsters/label.text = str(save_info.monsters)
	$money/label.text = str(save_info.money)
	$encyclopedia/label.text = save_info.encyclopedia
	$playtime/label.text = Player.get_printable_playtime(save_info.playtime)
	$time/label.text = Time.get_printable_time(save_info.time)

func _pressed():
	EventManager.emit_signal("load_game", save_name)