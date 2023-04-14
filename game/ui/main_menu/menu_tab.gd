extends Button

var is_current : set = set_is_current
var id

func _ready(): 
	connect("mouse_entered", Callable(self, "hover"))
	connect("focus_entered", Callable(self, "hover"))
	
	connect("mouse_exited", Callable(self, "unhover"))
	connect("focus_exited", Callable(self, "unhover"))

func load_info(key, data):
	id = key
	$sprite/icon.texture = Utils.load_resource(
			Constants.UI_ICON_PATH, data.icon)

func set_is_current(val):
	is_current = val
	update_z(val)

func update_z(val):
	if (val): $sprite.z_index = 1
	else: $sprite.z_index = 0

func _pressed():
	if is_current: return
	unhover()
	is_current = true
	Dispatcher.emit_signal("menu_open", id)

func hover():
	if !is_current: $sprite.position.y = -1

func unhover():
	$sprite.position.y = 0
