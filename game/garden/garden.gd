extends Control

func _ready():
	pass

func initialize():
	print("init garden")
	deserialize()

func serialize():
	pass

func deserialize(data):
	load_terrain(data.terrain)
	load_objects(data.objects)
	load_monsters(data.monsters)
	load_items(data.items)
	pass

func load_terrain(data):
	for x in data:
		for y in x:
			print("(", x, ",", y, "), ")
	pass

func load_objects(data):
	pass

func load_monsters(data):
	pass

func load_items(data):
	pass

func _input(event): 
	pass