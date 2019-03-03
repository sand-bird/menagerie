extends Node

const BASE_DIR = "res://data"
const MOD_DIR = "res://mods"
const DATA_EXT= "data"
const SCHEMA_EXT = "schema"

# -----------------------------------------------------------

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

# var EntityType = Constants.EntityType

var schemas = {}
var data = {}

func _ready(): pass
#	init()

func init():
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

	validate()

	Log.debug(self, ["data: ", data.keys()])
	Log.verbose(self, data)
	Log.debug(self, ["schemas: ", schemas.keys()])
	Log.verbose(self, schemas)

# -----------------------------------------------------------

func get(a):
	var args = Utils.pack(a)
	Log.debug(self, ["get ", args])

	var result
	if args.size() > 0 and args[0] in self:
		Log.verbose(self, ["arg `", args[0], "` is a property of Data!"])
		result = get(args[0])
		args.pop_front() # args[0] is resolved, don't use it again
	else: result = data

	for arg in args:
		if !result.has(arg):
			Log.warn(self, ["could not find data for ", arg,
					": ", PoolStringArray(args).join(".")])
			return null
		else: result = result[arg]

	return result

func get_resource(a):
	var path = get(a)
	return ResourceLoader.load(path) if (path) else null

# -----------------------------------------------------------

# TODO
#func filter(a):
#	var filtered = {}
#	match data:
#		a: Log.info(self, "hello")

# =========================================================== #
#                     . M O D C O N F I G                     #
# ----------------------------------------------------------- #

# fetches modconfig from the place where we keep it. if there
# is no modconfig, we make one (duh).
func load_modconfig():
	var modconfig = Utils.read_file(MOD_DIR.plus_file(".modconfig"))
	if !modconfig: modconfig = {
		"load_order": [],
		"mods": {}
	}
	return modconfig

# -----------------------------------------------------------

func save_modconfig(modconfig):
	Utils.write_file(MOD_DIR.plus_file(".modconfig"), modconfig)

# -----------------------------------------------------------

# checks mod directory against modconfig for any new mods.
# we call either check_modinfo or add_modinfo for every mod
# found, depending on whether it's in modconfig already.
# important: both of these functions add a temporary flag to
# that mod's info, "found", to be used by clean_modconfig,
# which wipes the flag when it is done. this is why we call
# clean_modconfig from here, rather than from _ready.
func update_modconfig(modconfig):
	var dir = Directory.new()
	dir.open(MOD_DIR)
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		var path = MOD_DIR.plus_file(current)
		if !dir.current_is_dir():
			current = dir.get_next()
			continue
		var modinfo = Utils.read_file(path.plus_file("meta.data"))
		if modinfo:
			if modconfig.mods.has(modinfo.id):
				check_modinfo(modconfig, modinfo, path)
			else: add_modinfo(modconfig, modinfo, path)
		current = dir.get_next()
	clean_modconfig(modconfig)

# -----------------------------------------------------------

# looks for the presence of a "found" key, which is set by
# add_modinfo and check_modinfo, in each entry in modconfig.
# since update_modconfig crawls the mod directory and calls
# one of those for each valid mod it finds, we can expect it
# to be set for all mods ~*found*~ in the directory. we clear
# the "found" key after we've seen it.
#
# fyi, we do these shenanigans so we don't have to crawl the
# directory all over again in search of missing mods.
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

# -----------------------------------------------------------

# formerly it checked the entire mod directory to see if any
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

# -----------------------------------------------------------

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


# =========================================================== #
#                   L O A D I N G   D A T A                   #
# ----------------------------------------------------------- #

func load_mod_schemas(modconfig):
	for mod in modconfig.load_order:
		Log.debug(self, ["loading schemas for mod: `", mod, "`..."])
		if !modconfig.mods[mod].has("schemas") or !modconfig.mods[mod].schemas:
			Log.debug(self, ["`", mod, "` has no schemas!"])
			break
		for schema in modconfig.mods[mod].schemas:
			Log.info(self, ["mod: `", mod, "` | schema: `", schema, "`"])
			# load schema

# -----------------------------------------------------------

func load_mod_data(modconfig):
	for id in modconfig.load_order:
		var sourceinfo = {
			"id": id,
			"version": modconfig.mods[id].version,
		}
		load_data(modconfig.mods[id].path, sourceinfo)
	pass

# -----------------------------------------------------------

func load_data(dirname, sourceinfo):
	Log.verbose(self, ["loading data from directory: `", dirname, "`"])
	var loaded = {}
	var dir = Directory.new()
	if dir.open(dirname) != OK:
		Log.error(self, ["could not open `", dirname, "`!"])
		return
	# start iterating through directories
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		var current_path = dirname.plus_file(current)
		if dir.current_is_dir():
			var child = load_data(current_path, sourceinfo)
			if child: loaded = merge(loaded, child)
		elif current.get_extension() == DATA_EXT:
			var d = load_datafile(current_path, sourceinfo)
			if !loaded.has("data"): loaded.data = {}
			loaded.data = merge(loaded.data, d)
		elif current.get_extension() == SCHEMA_EXT:
			var s = load_schemafile(current_path, sourceinfo)
			if !loaded.has("schemas"): loaded.schemas = {}
			loaded.schemas = merge(loaded.schemas, s)
		current = dir.get_next()
	return loaded

# -----------------------------------------------------------

# basically file i/o boilerplate so we can call process_data.
# accepts the path either in two arguments, the directory and
# the filename, or as a single arg containing the full path.
func load_datafile(path, sourceinfo):
	Log.debug(self, ["loading data from file: `", path, "`"])
	var filedata = Utils.read_file(path)
	if !filedata:
		Log.error(self, ["error loading data from `", path, "`!"])
		return
	if !filedata.has("id"):
		Log.error(self, ["the datafile at `", path, "` is missing an id"])
		return
	filedata = process_data(filedata, path.get_base_dir())
	filedata.sources = [sourceinfo]
	return { filedata.id: filedata }

# -----------------------------------------------------------

func load_schemafile(path, sourceinfo):
	Log.debug(self, ["loading schema from file: `", path, "`"])
	var schema = Utils.read_file(path)
	if !schema:
		Log.error(self, ["error loading schema from `", path, "`!"])
		return
	schema.sources = [sourceinfo]
	return { path.get_basename().get_file(): schema }


# =========================================================== #
#                P R O C E S S I N G   D A T A                #
# ----------------------------------------------------------- #

# okay, new plan. we don't want to resolve sigils on LOAD;
# that would make validation (which should happen once, post-
# load) a big headache, and open us up to a bunch of fatal
# errors from stuff not getting found, which is exactly what
# all this validation nonsense is supposed to prevent. plus,
# we can't resolve @ sigils (instance properties) right now
# anyway, for obvious reasons.
#
# as for fileref sigils, we should resolve the sigil to the
# full filepath (this is the only time we will know what it
# is), but don't load the resource yet for the reasons above.
func process_data(data, basedir):
	var collection = data.size() if typeof(data) == TYPE_ARRAY else data
	for i in collection:
		if typeof(data[i]) == TYPE_ARRAY or typeof(data[i]) == TYPE_DICTIONARY:
			data[i] = process_data(data[i], basedir)
		elif data[i] and typeof(data[i]) == TYPE_STRING and data[i][0] == '~':
			data[i] = basedir.plus_file(Utils.strip_sigil(data[i]))
	return data

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
	if !mod: return base
	Log.verbose(self, ["merging: ", mod.keys(), " into ", base.keys()])

	for key in mod:
		var k = key
		var replace = false
		if k[0] == '!':
			replace = true
			k = Condition.strip_sigil(key)
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

# -----------------------------------------------------------

# oh boy
func validate ():
	return true


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

#                 o t h e r   s t u f f
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
