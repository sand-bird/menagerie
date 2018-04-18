extends Node

var player_name
var playtime
var money
var last_update_time

func _ready():
	pass

func serialize():
	var data = {}
	for k in ["player_name", "playtime", "money"]:
		data[k] = self[k]
	return data

func deserialize(data):
	for k in ["player_name", "playtime", "money"]:
		self[k] = data[k]
	last_update_time = OS.get_unix_time()

func update_playtime():
	var current_time = OS.get_unix_time()
	var playtime_difference = current_time - last_update_time
	print(playtime_difference)
	playtime += playtime_difference
	print(playtime)
	last_update_time = current_time

func get_printable_playtime(time = null):
	if time == null:
		time = playtime
	# convert to minutes. playtime isn't updated often 
	# enough for us to sit and watch it tick, so we don't 
	# care about seconds. (maybe change this later anyway)
	time = int(time / 60)
	var hour = int(time / 60)
	var minute = int(time) % 60
	return str(hour) + ":" + str(minute).pad_zeros(2)