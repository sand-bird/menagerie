extends Control

#warning-ignore:unused_signal
signal change_page

const ANIM = "bob"

func _ready():
	$left.pressed.connect(func(): Dispatcher.menu_prev_page.emit())
	$right.pressed.connect(func(): Dispatcher.menu_next_page.emit())

func restart_animations():
	$left/sprite/anim.stop()
	$right/sprite/anim.stop()
	$left/sprite/anim.play(ANIM)
	$right/sprite/anim.play(ANIM)

func update_visibility(current, total):
	$left.visible = current > 0
	$right.visible = current < total - 1
	restart_animations()
