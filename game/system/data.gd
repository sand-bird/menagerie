extends Node

const BASE_DIR = "res://data"
const MOD_DIR = "res://mods"

# --------------------------------------------------------------------------- #

# regular path resolution is "res://" + [path].
# for a mod we must look for [path] in *every subfolder* of:
# - user://mods/
# - res://mods/

# 1. load base schemas
# 2. load base data
# 3. load/update modinfo
# 4. load mod schemas
# 5. load mod data
# 6. validate

var schemas = {}
var data = {}

var by_type = {}

func _init():
	# loads schemas and datafiles from data/
	var sourceinfo = {
		"id": "menagerie",
		"version": "0.1.0",  # todo: a real version
	}
	var base_data = load_data(BASE_DIR, sourceinfo)
	data = base_data.data
	schemas = base_data.schemas

	# reads .modconfig file into var modconfig
	var modconfig = load_modconfig()
	# checks & updates modconfig against mod folder
	update_modconfig(modconfig)
	save_modconfig(modconfig)
	
#	load_mod_schemas(modconfig)
#	load_mod_data(modconfig)
	
	# index by type
	for key in data:
		var type = data[key].type
		if type not in by_type:
			by_type[type] = []
		by_type[type].push_back(key)
	
	var val = Validator.new(schemas)
	val.validate_schemas()
	val.validate(data)

#	Log.debug(self, ["data: ", data.keys()])
#	Log.verbose(self, data)
#	Log.debug(self, ["schemas: ", schemas.keys()])
#	Log.verbose(self, schemas) # apparently this is a circular structure

# --------------------------------------------------------------------------- #

# get a data definition or returns null.  takes a path array.
# we can't call this `get` anymore because godot 4 no longer lets you override
# native functions :(
func fetch(a, default = null, warn = true):
	var args = U.pack(a)
	Log.verbose(self, ["(fetch) ", args])

	var result
	# note: i think this was to make it compatible with native `get`.
	# not sure if it's needed anymore
	if args.size() > 0 and args[0] in self:
		Log.verbose(self, ["arg `", args[0], "` is a property of Data!"])
		result = get(args[0])
		args.pop_front() # args[0] is resolved, don't use it again
	else: result = data

	for arg in args:
		if !result.has(arg):
			# don't warn if there's a default, just return
			if default != null: return default
			if warn: Log.warn(self, [
				"(fetch) could not find data for ", arg, ": ",
				".".join(PackedStringArray(args))
			])
			return null
		else: result = result[arg]

	return result

# --------------------------------------------------------------------------- #

func missing(a): return fetch(a, null, false) == null

# --------------------------------------------------------------------------- #

func fetch_res(a):
	var path = fetch(a)
	return ResourceLoader.load(path) if (path) else null

# --------------------------------------------------------------------------- #

# TODO
#func filter(a):
#	var filtered = {}
#	match data:
#		a: Log.info(self, "hello")

# =========================================================================== #
#                             . M O D C O N F I G                             #
# --------------------------------------------------------------------------- #

# fetches modconfig from the place where we keep it. if there is no modconfig,
# we make one (duh).
func load_modconfig():
	var modconfig = U.read_file(MOD_DIR.path_join(".modconfig"))
	if modconfig == null: modconfig = {
		"load_order": [],
		"mods": {}
	}
	return modconfig

# --------------------------------------------------------------------------- #

func save_modconfig(modconfig):
	U.write_file(MOD_DIR.path_join(".modconfig"), modconfig)

# --------------------------------------------------------------------------- #

# checks mod directory against modconfig for any new mods. we call either
# check_modinfo or add_modinfo for every mod found, depending on whether it's
# in modconfig already. important: both of these functions add a temporary flag
# to that mod's info, "found", to be used by clean_modconfig, which wipes the
# flag when it is done. this is why we call clean_modconfig from here, rather
# than from _ready.
func update_modconfig(modconfig):
	var dir = DirAccess.open(MOD_DIR)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var current = dir.get_next()
	while (current != ""):
		var path = MOD_DIR.path_join(current)
		if !dir.current_is_dir():
			current = dir.get_next()
			continue
		var modinfo = U.read_file(path.path_join("meta.data"))
		if modinfo:
			if modconfig.mods.has(modinfo.id):
				check_modinfo(modconfig, modinfo, path)
			else: add_modinfo(modconfig, modinfo, path)
		current = dir.get_next()
	clean_modconfig(modconfig)

# --------------------------------------------------------------------------- #

# looks for the presence of a "found" key, which is set by add_modinfo and
# check_modinfo, in each entry in modconfig. since update_modconfig crawls the
# mod directory and calls one of those for each valid mod it finds, we can
# expect it to be set for all mods ~*found*~ in the directory. we clear the
# "found" key after we've seen it.
#
# fyi, we do these shenanigans so we don't have to crawl the directory all over
# again in search of missing mods.
func clean_modconfig(modconfig):
	for i in modconfig.load_order.size():
		var id = modconfig.load_order[i]
		var modinfo = modconfig.mods[id]
		if modinfo.has("found") and modinfo.found:
			modinfo.erase("found")
		else:
			Log.warn(self, ["mod `", id,
					"` not found. its data will be erased from modconfig."])
			modconfig.mods.erase(id)
			modconfig.load_order.remove(i)

# --------------------------------------------------------------------------- #

# formerly it checked the entire mod directory to see if any of the files
# inside had a more recent date_modified. now it checks the version in the
# mod's meta.data against the one known to our modconfig. right now this is
# mostly relevant for updating the schema list.
#
# ALSO i just realized that we need to make sure the mod's directory is what we
# expect it to be. phew, BUG AVERTED
#
# note: if we're here, it means we've already validated that the passed-in
# modinfo's id exists in modconfig.mods.
func check_modinfo(modconfig, modinfo, path):
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

	saved_info.found = true

# --------------------------------------------------------------------------- #

# new mod! yay!
func add_modinfo(modconfig, modinfo, path):
	Log.debug(self, ["new mod found! adding to modconfig: `",
			modinfo.id, "`"])
	modconfig.mods[modinfo.id] = {
		"path": path,
		"version": modinfo.version,
		"is_new": true,
		"is_enabled": true,
		"schemas": modinfo.schemas if modinfo.has("schemas") else {},
		"found": true
	}
	modconfig.load_order.append(modinfo.id)


# =========================================================================== #
#                           L O A D I N G   D A T A                           #
# --------------------------------------------------------------------------- #

func load_mod_schemas(modconfig):
	for mod in modconfig.load_order:
		Log.debug(self, ["loading schemas for mod: `", mod, "`..."])
		if !modconfig.mods[mod].has("schemas") or !modconfig.mods[mod].schemas:
			Log.debug(self, ["`", mod, "` has no schemas!"])
			break
		for schema in modconfig.mods[mod].schemas:
			Log.info(self, ["mod: `", mod, "` | schema: `", schema, "`"])
			# load schema

# --------------------------------------------------------------------------- #

func load_mod_data(modconfig):
	for id in modconfig.load_order:
		var sourceinfo = {
			"id": id,
			"version": modconfig.mods[id].version,
		}
		load_data(modconfig.mods[id].path, sourceinfo)

# --------------------------------------------------------------------------- #

func load_data(dirname, sourceinfo):
	Log.verbose(self, ["loading data from directory: `", dirname, "`"])
	var loaded: Dictionary = { data = {}, schemas = {} }
	var dir = DirAccess.open(dirname) 
	if !dir:
		Log.error(self, ["could not open `", dirname, "`!"])
		return
	# start iterating through directories
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var current = dir.get_next()
	while (current != ""):
		var current_path = dirname.path_join(current)
		if dir.current_is_dir():
			var child = load_data(current_path, sourceinfo)
			if child: loaded = merge(loaded, child)
		# both datafiles and schemafiles are json files;
		# we identify schemas by ending the filename with _schema.
		elif current.get_extension() == 'json':
			if current.ends_with('.schema.json'):
				var s = load_schemafile(current_path, sourceinfo)
				loaded.schemas = merge(loaded.schemas, s)
			else:
				var d = load_datafile(current_path, sourceinfo)
				loaded.data = merge(loaded.data, d)
		current = dir.get_next()
	return loaded

# --------------------------------------------------------------------------- #

# basically file i/o boilerplate so we can call process_data. accepts the path
# either in two arguments, the directory and the filename, or as a single arg
# containing the full path.
func load_datafile(path, sourceinfo) -> Dictionary:
	Log.debug(self, ["loading data from file: `", path, "`"])
	var filedata = U.read_file(path)
	if filedata == null:
		Log.error(self, ["error loading data from `", path, "`!"])
		return {}
	if !filedata.has("id"):
		Log.error(self, ["the datafile at `", path, "` is missing an id"])
		return {}
	filedata = process_data(filedata, path.get_base_dir())
	filedata.sources = [sourceinfo]
	return { filedata.id: filedata }

# --------------------------------------------------------------------------- #

func load_schemafile(path, sourceinfo):
	Log.debug(self, ["loading schema from file: `", path, "`"])
	var schema = U.read_file(path)
	if schema == null:
		Log.error(self, ["error loading schema from `", path, "`!"])
		return
	# schemafiles are named foo.schema.json.
	# this line strips the path and schema.json, leaving just foo.
	var filename = path.get_basename().get_basename().get_file()
	schema = process_schema(schema, filename)
	schema.sources = [sourceinfo]
	return { filename: schema }


# =========================================================================== #
#                        P R O C E S S I N G   D A T A                        #
# --------------------------------------------------------------------------- #
# U.read_file already parses JSON files, but we need to tweak the results
# a bit, so we recurse down the loaded files.  we process data and schema files
# slightly differently: data files may have filepaths, and schema files may
# have refs.  both of those get resolved here.
# 
# for both filetypes, we also want to (a) recurse down arrays and objects and
# (b) coerce integer values to ints by casting them to an int and then checking
# for equality.  (this is necessary because json doesn't have integer types,
# but much of our data actually consists of integer values.)

func process_data(d, basedir):
	var collection = d.size() if typeof(d) == TYPE_ARRAY else d
	for i in collection:
		if typeof(d[i]) == TYPE_ARRAY or typeof(d[i]) == TYPE_DICTIONARY:
			d[i] = process_data(d[i], basedir)
		
		# we use `~` as a sigil to mark a path.  kinda weird since `~` connotes the
		# home directory, which isn't how it's being used here, but eh ¯\_(ツ)_/¯
		elif d[i] and typeof(d[i]) == TYPE_STRING and d[i][0] == '~':
			d[i] = basedir.path_join(U.strip_sigil(d[i]))
		
		elif d[i] and typeof(d[i]) == TYPE_FLOAT and int(d[i]) == d[i]:
			d[i] = int(d[i])
		
	return d

# --------------------------------------------------------------------------- #

func process_schema(s, filename):
	var collection = s.size() if typeof(s) == TYPE_ARRAY else s
	for i in collection:
		if typeof(s[i]) == TYPE_ARRAY or typeof(s[i]) == TYPE_DICTIONARY:
			s[i] = process_schema(s[i], filename)
		
		# keeping it simple: processing a schema involves resolving local reference
		# paths to absolute paths by replacing the '#' with the basename.  this is
		# enough for now since we only support static references ($ref).
		elif i is String and i == '$ref':
			if s[i] is String:
				s[i] = s[i].replace('#', filename)
			else: Log.warn(self, [
				"found $ref keyword in schema whose value is not a string | schema: ",
				filename
			])
		
		elif s[i] and typeof(s[i]) == TYPE_FLOAT and int(s[i]) == s[i]:
			s[i] = int(s[i])
	
	return s

# --------------------------------------------------------------------------- #

# if we find multiple instances of some data, we should try to intelligently
# merge them. the second argument, the "mod" dict, takes precedence over the
# first. we do the following:
# - keys that do not appear in the base dict are added
# - keys that lead to dicts in the base dict *and* in the mod dict are dealt
# 	with recursively. the goal is to prevent loss of data whenever possible,
# 	so the game ideally never misses something it's expecting (like a nested
# 	subproperty). if the mod dict is trying to replace a dictionary property
# 	with something else, it's probably user error.
# - for keys that lead to arrays in the base dict, whatever's in the mod dict
#   is appended to them. there is no type checking here, obviously, so if we
#   were expecting an array of dicts and the mod doesn't conform, we're SOL.
func merge(base: Dictionary, mod: Dictionary):
	if mod == null: return base
	Log.verbose(self, ["merging: ", mod.keys(), " into ", base.keys()])

	for key in mod:
		var k = key
		var replace = false
		if k.left(1) == '!':
			replace = true
			k = U.strip_sigil(key)
		if base.has(k) and !replace:
			if typeof(base[k]) == TYPE_ARRAY:
				if typeof(mod[k]) == TYPE_ARRAY:
					for item in mod[k]: base[k].append(item)
				else: base[k].append(mod[k])
			elif (typeof(base[k]) == TYPE_DICTIONARY
					and typeof(mod[k]) == TYPE_DICTIONARY):
				merge(base[k], mod[k])
		else: base[k] = mod[k]
	return base


# =========================================================================== #
#                          M O D I F I E D   T I M E                          #
# --------------------------------------------------------------------------- #
# we're not using these right now, but there's nothing wrong with them so we
# might as well leave em in.

func get_modified_time(dirname):
	var modtime = 0
	var dir = DirAccess.open(dirname)
	assert(!!dir)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var current = dir.get_next()
	while (current != ""):
		if dir.current_is_dir():
			modtime = max(modtime,
				get_modified_time(dirname.path_join(current)))
		else:
			modtime = max(modtime,
				FileAccess.get_modified_time(dirname.path_join(current)))
		current = dir.get_next()
	return modtime

# --------------------------------------------------------------------------- #

func is_current(time, dirname):
	var dir = DirAccess.open(dirname)
	assert(!!dir)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var current = dir.get_next()
	while (current != ""):
		if (dir.current_is_dir() && !is_current(time, dirname.path_join(current))
				or FileAccess.get_modified_time(dirname.path_join(current)) > time):
			return false
		current = dir.get_next()
	return true


# =========================================================================== #
#                                  U T I L S                                  #
# --------------------------------------------------------------------------- #

func list_dir(dirname):
	Log.info(self, "==========================")
	Log.info(self, ["listing dir: ", dirname])
	Log.info(self, "--------------------------")
	var dir = DirAccess.open(dirname)
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var current = dir.get_next()
	while (current != ""):
		Log.info(self, current)
		current = dir.get_next()
	Log.info(self, "--------------------------")

# --------------------------------------------------------------------------- #

# given a `discovered` object (see player.gd), calculates the percentage of
# available data which has been discovered.
# each key in `data` is weighted the same, whether or not it has discoverable
# children (morphs or states).
func get_completion_percent(discovered: Dictionary) -> int:
	var total: float = data.size()
	var completed: float = 0
	var valid_keys = discovered.keys().filter(func (k): return data.has(k))
	for key in valid_keys:
		var value = discovered[key]
		match typeof(value):
			TYPE_BOOL: if value: completed += 1
			TYPE_DICTIONARY:
				completed += get_key_completion(key, value)
	return round((completed / total) * 100) as int

const discoverable_children = { monster = 'morphs', object = 'states' }
func get_key_completion(key: String, value: Dictionary):
	var source = fetch(key)
	var child_keys: Array = source[discoverable_children[source.type]].keys()
	var total: float = child_keys.size()
	var completed: float = 0
	for child_key in value.keys().filter(func (k): return child_keys.has(k)):
		if value[child_key]: completed += 1
	return completed / total
