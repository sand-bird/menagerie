extends PagedList

func initialize():
	rows = 3
	columns = 1
	allow_unselected = false

	data = [
		{
			title = T.NEW_GAME,
			on_press = func(): Dispatcher.ui_open.emit(["name_input", 1, false])
		},
		{
			title = T.QUIT_GAME,
			on_press = func(): Dispatcher.quit_game.emit()
		}
	]
	if SaveUtils.get_save_list():
		data.push_front({
			title = T.LOAD_GAME,
			on_press = func(): Dispatcher.ui_open.emit("save_list")
		})

## should take in a slice of data the same length as page_size, and return an
## array of Control nodes which we will then add as children.
func load_items(data_slice: Array[Variant]) -> Array[Control]:
	var buttons: Array[Control] = []
	for d in data_slice:
		var b = Button.new()
		b.pressed.connect(d.on_press)
		b.text = tr(d.title).capitalize()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.append(b)
	return buttons
