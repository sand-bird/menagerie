extends Control

func _ready():
	$terrain.set_cell(0, 0, 0)
	$terrain.set_cell(0, 1, 1)
	pass

func initialize():
	print("init garden")
	deserialize()

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
#	$camera.deserialize(data.camera)

func load_terrain(data):
	for y in data.size():
		for x in data[y].size():
			$terrain.set_cell(x, y, data[y][x])
	rect_size = Vector2(data[0].size(), data.size()) * $terrain.cell_size
	print("garden size: ", rect_size)

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