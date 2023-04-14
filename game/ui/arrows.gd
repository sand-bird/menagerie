extends Control

#warning-ignore:unused_signal
signal change_page

const ANIM = "bob"

func _ready():
	$left.connect("pressed", Callable(self, "emit_signal").bind("change_page", -1))
	$right.connect("pressed", Callable(self, "emit_signal").bind("change_page", 1))

func restart_animations():
	$left/sprite/anim.stop()
	$right/sprite/anim.stop()
	$left/sprite/anim.play(ANIM)
	$right/sprite/anim.play(ANIM)

func update_visibility(current, total):
	$left.visible = current > 0
	$right.visible = current < total - 1
	restart_animations()
