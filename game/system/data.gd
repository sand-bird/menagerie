extends Node

const BASE_DIR = "res://data"
const DATA_EXTENSION = "data"

# -----------------------------------------------------------

# regular path resolution is "res://" + [path].
# for a mod we must look for [path] in *every subfolder* of:
# - user://mods/
# - res://mods/
#
# if multiple files are found with the same path, we do our 
# best to merge them. (this is TODO and will be for a while)

var EntityType = Constants.Type

var lookup = {
	EntityType.MONSTER: "monsters",
	EntityType.ITEM: "items",
	EntityType.OBJECT: "objects",
	EntityType.NPC: "npcs",
	EntityType.LOCATION: "locations"
}

# apparently there is NO WAY AROUND accessing all of our data
# by Data.data.whatever, as stupid as that is, since we can't
# populate class properties at runtime. if you can think of a
# better name for this silly dict i'm all ears!!
var data = {}

func _ready(): # do the thing
	data = load_dir(BASE_DIR)
	# DEBUG: print(to_json(data))

# -----------------------------------------------------------

# if we find a directory with an identically-named datafile
# inside (eg pufig/pufig.data), we should take that file to
# represent the directory in the data structure, with the
# expectation that it's the main data file, and if any others
# exist in the directory it will reference them as it needs.
#
# if there is no name-matching datafile, we should create a 
# dictionary for the directory in Data.data, and give each
# data file we find its own entry inside. (eg. system.types,
# system.menu_chapters, etc.)
func load_dir(dirname):
	var data = {}
	var dir = Directory.new()
	assert(dir.open(dirname) == OK)
	# start iterating through directories
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		# do the following for each dir found:
		if dir.current_is_dir():
			var default_path = get_default_path(current)
			if dir.file_exists(default_path):
				data[current] = load_file(dirname.plus_file(default_path))
			else:
				var child_dir = load_dir(dirname.plus_file(current))
				if child_dir: data[current] = child_dir
		elif current.get_extension() == DATA_EXTENSION:
			data[current.get_basename()] = load_file(dirname, current)
		# increment iterator
		current = dir.get_next()
	return data

# -----------------------------------------------------------

# basically file i/o boilerplate so we can call process_data.
# accepts the path either in two arguments, the directory and
# the filename, or as a single arg containing the full path.
func load_file(dirname, fname = null):
	var path = dirname.plus_file(fname) if fname else dirname
	var file = File.new()
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	if data: data = process_data(data, path.get_base_dir())
	file.close()
	return data

# -----------------------------------------------------------

# TODO: eventually, we want to load resources referenced in 
# datafiles intelligently (eg. ResourceLoader for .png files,
# process_data() for .data files, etc). also not 100% sold on
# ~ syntax, since it doesn't do a great job of conveying that
# the value must be specially annotated as a file reference -
# especially since we might want to be able to load resources
# from the base res:// dir, and ~ has basically the opposite
# implication. otoh, we could treat ! paths like normal unix 
# filepaths, eg !path for relative, !/path for absolute, etc.
# 
# also worth considering: differentiating paths to user://...
# from paths to res://... from datafiles in the user://mods/
# directory. i guess ideally we'd resolve these paths in the
# same way we resolve files, with user://mods, res://../mods, 
# and res:// tried in that order for a match.
func process_data(data, basedir):
#	print("process_data: ", data)
	for i in data:
		#if typeof(data[i]) in [TYPE_ARRAY, TYPE_DICTIONARY]:
		#	data[i] = process_data(data[i], basedir)
		if typeof(data[i]) == TYPE_STRING:
			match data[i][0]:
				'~': # we have an image (or other link) we should process
					data[i] = ResourceLoader.load(
							basedir.plus_file(data[i].substr(1, 
							data[i].length() - 1)))
				'$': # we have an enum we need to resolve
					data[i] = Condition.eval_arg(data[i])
	return data

# -----------------------------------------------------------

# dumb little utility function to get the relative filepath 
# for the "default" datafile (for lack of a better term),
# dirname/dirname.data (or dirname/dirname + DATA_EXT),
# literally just because the relevant line in load_dir() 
# would've been too long otherwise.
func get_default_path(dirname):
	return dirname.plus_file(dirname.get_file() + "." + DATA_EXTENSION)
