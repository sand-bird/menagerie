extends Control

var color_night = Color("66588c")
var color_dawn = Color("db9ab4")
var color_morning = Color("dbc2b8")
var color_noon = Color("fbffe6")
var color_afternoon = Color("fcdec3")
var color_evening = Color("e48b9a")
var color_dusk = Color("b268dc")

var colors = {
	6: color_dawn,
	8: color_morning,
	11: color_noon,
	14: color_afternoon,
	18: color_evening,
	20: color_dusk
}

func get_anim_duration(hour):
	
	pass

func _ready():
#	$terrain.set_cell(0, 0, 0)
#	$terrain.set_cell(0, 1, 1)
	pass

func init(data):
	Log.info(self, "initializing!")
	deserialize(data)
	Dispatcher.emit_signal("ui_open", ["garden/clock_hud", 0, false])
#	print("tint color: ", $tint.color)
#	$tint.color = color1
	Time.start()
	Dispatcher.connect("hour_changed", self, "update_color")
	$tint/anim.play("tint")

func update_color(hour):
	var anim = $tint/anim.get_animation("tint")
	anim.track_set_key_value(0, 0, $tint.color)
	anim.set_length(1)
	anim.track_insert_key(0, 1, Color(randf(), randf(), randf()))
	
	$tint/anim.play("tint")


func serialize():
	return {
		"camera": $camera.serialize(),
		"terrain": save_terrain(),
		"objects": save_objects(),
		"monsters": save_monsters(),
		"items": save_items()
	}

func deserialize(data):
	load_terrain(data.terrain)
	load_objects(data.objects)
	load_monsters(data.monsters)
	load_items(data.items)
	if data.has("camera"): $camera.deserialize(data.camera)

func load_terrain(data):
	for y in data.size():
		for x in data[y].size():
			$terrain.set_cell(x, y, data[y][x])
	rect_size = Vector2(data[0].size(), data.size()) * $terrain.cell_size
	Log.debug(self, ["garden size: ", rect_size])

func print_terrain(data):
	print(data.size(), "x", data[0].size())
	var head = ""
	for num in data[0].size():
		head = head + str(num).pad_zeros(2) + " "
	print("   | ", head)
	for y in data.size():
		var row = ""
		for x in data[y].size():
			row = row + " " + str(data[y][x]) + " "
		print(str(y).pad_zeros(2), " | ", row)

func load_objects(data):
	pass

func load_monsters(data):
	pass

func load_items(data):
	pass

func _input(event): 
	pass