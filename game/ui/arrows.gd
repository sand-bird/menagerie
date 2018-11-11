extends Control

signal change_page

const ANIM = "bob"

func _ready():
	$left.connect("pressed", self, "emit_signal", ["change_page", -1])
	$right.connect("pressed", self, "emit_signal", ["change_page", 1])

func update_visibility(current, total):
	if current > 0:
		$left.show()
		$left/sprite/anim.play(ANIM)
	else:
		$left.hide()
		$left/sprite/anim.stop()
	
	if current < total - 1:
		$right.show()
		$right/sprite/anim.play(ANIM)
	else:
		$right.hide()
		$right/sprite/anim.stop()

func update_viz2(current, total):
	if current == 0 and $left.visible: 
		$left.hide()
		$left/sprite/anim.stop()
	elif !$left.visible:
		$left/sprite/anim.play(ANIM)
		$left.show()
	
	if current >= total - 1 and $right.visible:
		$right.hide()
		$right/sprite/anim.stop()
	elif !$right.visible:
		$right/sprite/anim.play(ANIM)
		$right.show()
