extends Button

var is_current : set = set_is_current
var id

func _ready(): 
	mouse_entered.connect(hover)
	focus_entered.connect(hover)
	
	mouse_exited.connect(unhover)
	focus_exited.connect(unhover)

func load_info(key, chapter: MenuChapter):
	id = key
	$sprite/icon.texture = U.load_resource(
			Constants.UI_ICON_PATH, chapter.ICON)

func set_is_current(val):
	is_current = val

func _pressed():
	if is_current: return
	unhover()
	is_current = true
	Dispatcher.menu_open.emit(id)

func hover():
	if !is_current: $sprite.position.y = -1

func unhover():
	$sprite.position.y = 0
