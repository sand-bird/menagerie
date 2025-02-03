extends Button

var save_dir

func load_info(index, save_info):
	save_dir = save_info.save_dir
	$player_name/label.text = save_info.player_name
	$monsters/label.text = str(save_info.monsters)
	$money/label.text = str(save_info.money)
	$encyclopedia/label.text = str(save_info.encyclopedia, '%')
	$playtime/label.text = Player.format_playtime(save_info.playtime)
	$time/label.text = Clock.format_datetime(save_info.time)
	$index.text = str(index)

func _pressed():
	Dispatcher.ui_close.emit()
	Dispatcher.load_game.emit(save_dir)
