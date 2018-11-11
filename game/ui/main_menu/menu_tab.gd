extends Button

var is_current setget set_is_current
var id

func _ready(): 
	connect("mouse_entered", self, "hover")
	connect("focus_entered", self, "hover")
	
	connect("mouse_exited", self, "unhover")
	connect("focus_exited", self, "unhover")

func load_info(key, data):
	id = key
	$sprite/icon.texture = load(data.icon)

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
