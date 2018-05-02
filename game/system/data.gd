extends Node

const BASE_DIR = "res://data"
const DATA_EXTENSION = ".data"

# -----------------------------------------------------------

# regular path resolution is "res://" + [path].
# for a mod we must look for [path] in *every subfolder* of:
# - user://mods/
# - res://mods/
#
# if multiple files are found with the same path, we do our 
# best to merge them.

var EntityType = Constants.EntityType

var lookup = {
	EntityType.MONSTER: "monsters",
	EntityType.ITEM: "items",
	EntityType.OBJECT: "objects",
	EntityType.NPC: "npcs",
	EntityType.LOCATION: "locations",
	EntityType.GARDEN: "garden"
}

func _enter_tree():
	set_meta("test", 1)

var data = {}

func _ready():
	data = load_dir(BASE_DIR)
#	print("done: ", to_json(data))


func load_dir(dirname):
	var data = {}
	var dir = Directory.new()
	assert(dir.open(dirname) == OK)
	# start iterating through directories
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		# print("current: ", dirname.plus_file(current))
		# do the following for each dir found:
		if dir.current_is_dir():
			var child_dir = load_dir(dirname.plus_file(current))
			if child_dir: data[current] = child_dir
		elif current == dirname.get_file() + DATA_EXTENSION:
			data = load_file(dirname, current)
		# increment iterator
		current = dir.get_next()
	return data

func load_file(dirname, path):
	print("load_file: ", path)
	var file = File.new()
	file.open(dirname.plus_file(path), File.READ)
	var data = parse_json(file.get_as_text())
	if data: data = process_data(data, dirname)
	file.close()
	return data

func process_data(data, basedir):
#	print("process_data: ", data)
	for i in data:
		#if typeof(data[i]) in [TYPE_ARRAY, TYPE_DICTIONARY]:
		#	data[i] = process_data(data[i], basedir)
		if typeof(data[i]) == TYPE_STRING and data[i][0] == '!':
			print("! found!!")
			# we have an image (or other link) we should process
			data[i] = ResourceLoader.load(basedir.plus_file(data[i].substr(1, 
					data[i].length() - 1)))
	return data