extends Control

signal opened
signal closed

export (Animation) var enter
export (Animation) var exit
var player
var status

#var in_speed
#var out_speed

#var status

func _enter_tree():
	load_player()
	open()

func load_player():
	var has_player = false
	for child in get_children():
		if child is AnimationPlayer:
			has_player = true
			player = child
	if !has_player: player = AnimationPlayer.new()
	add_child(player)
	if enter: player.add_animation("enter", enter)
	if exit:  player.add_animation("exit", exit)
	player.connect("finished", self, "_on_transition_finished")

func open():
	if status == "closing":
		print("reverse the close!!!")
	play("enter")
	status = "opening"
	yield(player, "finished")
	status = "opened"
	emit_signal("opened")

func close():
	print("closing...")
	if status == "opening":
		print("reverse the open!!!")
	play("exit")
	status = "closing"
	yield(player, "finished")
	status = "closed"
	emit_signal("closed")

func _on_transition_finished():
	print("transition finished")
	pass

func play(anim):
	if player: player.play(anim)