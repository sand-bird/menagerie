extends Node

const BASE_DIR = "res://data"
const MOD_DIR = "res://mods"
const DATA_EXTENSION = "data"
const SCHEMA_EXTENSION = "schema"

# -----------------------------------------------------------

# regular path resolution is "res://" + [path].
# for a mod we must look for [path] in *every subfolder* of:
# - user://mods/
# - res://mods/

var EntityType = Constants.Type

var schemas = {
	
}

var data = {
	"fluffy_tuft": {
		"value": 1,
		"type": "item",
		"name": {
			"en": "Fluffy Tuft"
		}
	},
	"an_object": {
		"type": "object",
		"name": {
			"en": "An Object"
		}
	}
}

var monsters = {}
var items = {
	"fluffy_tuft": data.fluffy_tuft
}
var objects = {
	"an_object": data.an_object
}
var npcs = {}
var locations = {}


var metadata # temp holder for contentpack metadata
var modconfig

func _ready():
#	load_data()  # loads schemas and datafiles from data/
	load_modconfig()  # reads .modconfig file into var modconfig
	update_modconfig()  # checks & updates modconfig against mod folder
	Log.info(self, to_json(get("an_object")))
	#list_dir(MOD_DIR)
	#data = load_dir(BASE_DIR)
	# Log.verbose(self, to_json(data))

# -----------------------------------------------------------

func get(a):
	var args = Utils.pack(a)
	Log.debug(self, ["get ", args])
	
	var result
	if args.size() > 0 and args[0] in self:
		Log.verbose(self, ["arg `", args[0], "` is a property of Data!"])
		result = self[args[0]]
		args.pop_front() # args[0] is resolved, don't use it again
	else: result = data
	
	for arg in args:
		if !result.has(arg):
			Log.warn(self, ["could not find data for ", arg, 
					": ", PoolStringArray(args).join(".")]) 
			return null
		else: result = result[arg]
	
	return result

# -----------------------------------------------------------

# oh boy
func validate (obj, schema):
	pass

# =========================================================== #
#                     . M O D C O N F I G                     #
# ----------------------------------------------------------- #

# fetches modconfig from the place where we keep it. if there
# is no modconfig, we make one (duh).
func load_modconfig():
	modconfig = SaveManager.read_file(MOD_DIR.plus_file(".modconfig"))
	if !modconfig: modconfig = {
		"load_order": [],
		"mods": {}
	}

func save_modconfig():
	SaveManager.write_file(MOD_DIR.plus_file(".modconfig"), modconfig)

# -----------------------------------------------------------

# checks mod directory against modconfig for any new mods.
# if we find a new mod, we call add_modinfo on it.
func update_modconfig():
	var dir = Directory.new()
	dir.open(MOD_DIR)
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		var path = MOD_DIR.plus_file(current)
		if !dir.current_is_dir(): 
			current = dir.get_next()
			continue
		var modinfo = SaveManager.read_file(path.plus_file("meta.data"))
		if modinfo:
			if modconfig.mods.has(modinfo.id):
				check_modinfo(modinfo, path)
			else: add_modinfo(modinfo, path)
		current = dir.get_next()
	SaveManager.write_file(MOD_DIR.plus_file(".modconfig"), modconfig)

# -----------------------------------------------------------

# used to look through the entire mod directory to see if any
# of the files inside had a more recent date_modified. now it
# checks the version in the mod's meta.data against the one
# known to our modconfig. right now this is mostly relevant
# for updating the schema list.
#
# ALSO i just realized that we need to make sure the mod's
# directory is what we expect it to be. phew, BUG AVERTED
#
# note: if we're here, it means we've already validated that
# the passed-in modinfo's id exists in modconfig.mods.
func check_modinfo(modinfo, path):
	var mod_id = modinfo.id
	var saved_info = modconfig.mods[mod_id]
	Log.verbose(self, ["found entry for `", mod_id, 
			"` in modconfig: ", saved_info])
	
	if saved_info.path != path:
		Log.info(self, ["looks like mod `", mod_id, 
				"` was moved. new path: `", path, "`"])
		saved_info.path = path
	
	if saved_info.version != modinfo.version:
		Log.info(self, ["mod `", mod_id, "` has been updated! version: ",
				saved_info.version, " -> ", modinfo.version])
		saved_info.schemas = modinfo.schemas
		saved_info.version = modinfo.version

# -----------------------------------------------------------

# new mod! yay!
func add_modinfo(modinfo, path):
	Log.debug(self, ["new mod found! adding to modconfig: `",
			modinfo.id, "`"])
	modconfig.mods[modinfo.id] = {
		"path": path,
		"version": modinfo.version,
		"is_new": true,
		"is_enabled": true,
		"schemas": modinfo.schemas if modinfo.has("schemas") else {}
	}
	modconfig.load_order.append(modinfo.id)

# -----------------------------------------------------------

# if we find multiple instances of some data, we should try
# to intelligently merge them. the second argument, the "mod"
# dict, takes precedence over the first. we do the following:
# - keys that do not appear in the base dict are added
# - keys that lead to dicts in the base dict *and* in the mod
#   dict are dealt with recursively. the goal is to prevent
#   loss of data whenever possible, so the game ideally never
#   misses something it's expecting (like a sub-subproperty).
#   if the mod dict is trying to replace a dictionary 
#   property with something else, it's probably user error.
# - for keys that lead to arrays in the base dict, whatever's
#   in the mod dict is appended to them. there is no type
#   checking here, obviously, so if we were expecting an 
#   array of dicts and the mod doesn't conform, we're SOL.
func merge(base, mod):
	for k in mod:
		if !base.has(k): base[k] = mod[k]
		else:
			if (typeof(base[k]) == TYPE_DICTIONARY 
					&& typeof(mod[k]) == TYPE_DICTIONARY):
				update_dict(base[k], mod[k])
			elif typeof(base[k]) == TYPE_ARRAY:
				if typeof(mod[k]) == TYPE_ARRAY:
					for item in mod[k]: base[k].append(item)
				else: base[k].append(mod[k])
			else: base[k] = mod[k]

# -----------------------------------------------------------

func list_dir(dirname):
	Log.info(self, "==========================")
	Log.info(self, ["listing dir: ", dirname])
	Log.info(self, "--------------------------")
	var dir = Directory.new()
	dir.open(dirname)
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		Log.info(self, current)
		current = dir.get_next()
	Log.info(self, "--------------------------")

#func load_data():
#	for type in types:
#		print(type)

# -----------------------------------------------------------

func load_dir(dirname):
	var dir = Directory.new()
	assert(dir.open(dirname) == OK)
	# start iterating through directories
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		Log.verbose(self, ["current dir: ", current])
		if dir.current_is_dir():
			load_dir(dirname.plus_file(current))
		else: 
			match current.get_extension():
				DATA_EXTENSION:
					load_file(dirname, current)
				SCHEMA_EXTENSION:
					load_file(dirname, current)
		current = dir.get_next()

# -----------------------------------------------------------

# basically file i/o boilerplate so we can call process_data.
# accepts the path either in two arguments, the directory and
# the filename, or as a single arg containing the full path.
func load_file(dirname, fname = null):
	return
	var path = dirname.plus_file(fname) if fname else dirname
	Log.verbose(self, ["load_file: ", path])
	var file = File.new()
	file.open(path, File.READ)
	var filedata = parse_json(file.get_as_text())
	file.close()
	if filedata: process_data(filedata, path.get_base_dir())

# -----------------------------------------------------------

# TODO: we want to resolve 
func process_data(data, basedir):
	Log.verbose(self, ["process_data: ", data])
	for i in data:
		if typeof(data[i]) in [TYPE_ARRAY, TYPE_DICTIONARY]:
			data[i] = process_data(data[i], basedir)
		if typeof(data[i]) == TYPE_STRING:
			match data[i][0]:
				'!': # we have an image (or other link) we should process
					data[i] = ResourceLoader.load(
							basedir.plus_file(data[i].substr(1, 
							data[i].length() - 1)))
				'$': # we have an enum we need to resolve
					data[i] = Condition.eval_arg(data[i])
				'#': # we have an enum we need to resolve
					data[i] = Condition.eval_arg(data[i])
	return data


# =========================================================== #
#                  M O D I F I E D   T I M E                  #
# ----------------------------------------------------------- #
# we're not using these right now, but there's nothing wrong
# with them so we might as well leave em in.

func get_modified_time(dirname):
	var modtime = 0
	var file = File.new()
	var dir = Directory.new()
	assert(dir.open(dirname) == OK)
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		if dir.current_is_dir():
			modtime = max(modtime, 
				get_modified_time(dirname.plus_file(current)))
		else:
			modtime = max(modtime, 
				file.get_modified_time(dirname.plus_file(current)))
		current = dir.get_next()
	return modtime

# -----------------------------------------------------------

func is_current(time, dirname):
	var file = File.new()
	var dir = Directory.new()
	assert(dir.open(dirname) == OK)
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		if (dir.current_is_dir() && !is_current(time, dirname.plus_file(current))
				or file.get_modified_time(dirname.plus_file(current)) > time):
			return false
		current = dir.get_next()
	return true