extends Control

var current_menu
var last_menu
onready var screen = get_node("screen")
onready var ui = get_node("ui")

func _ready():
	set_process_input(true)
	change_scene("garden")
	#change_scene(TITLE)

func change_scene(scene):
	screen.remove_child(screen.get_child(0))
	screen.add_child(load("res://" + scene + "/" + scene + ".tscn").instance())
	ui.get_node(scene).show()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		do_esc()
	elif event.is_action_pressed("ui_accept"):
		ui.switch_menu("save_list")

func do_esc():
	if !ui.close_menu(): ui.open_menu("pause_menu")