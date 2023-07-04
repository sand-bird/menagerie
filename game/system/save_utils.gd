extends Node
class_name SaveUtils
const LNAME = 'SaveUtils'

const SAVE_ROOT = "user://saves/"
const PLAYER = "player.save"
const GARDEN = "garden.save"
const NEW_SAVE = "res://data/system/new.save"

# =========================================================================== #
#                      G E T T I N G   S A V E   I N F O                      #
# --------------------------------------------------------------------------- #

# scans the SAVE_ROOT dir for valid save directories.
static func get_save_list() -> Array[String]:
	var dir = DirAccess.open(SAVE_ROOT)
	var saves: Array[String] = []
	if !dir: return []
	dir.list_dir_begin()
	var current = dir.get_next()
	while (current != ""):
		if is_save(current):
			Log.debug(LNAME, ["(get_save_list) found save: ", current])
			saves.append(current)
		current = dir.get_next()
	# order save info by timestamp, so the most recent save will show first on
	# the save list.
	saves.sort_custom(
		func (a, b): return get_save_time(a) > get_save_time(b)
	)
	return saves

# --------------------------------------------------------------------------- #

# gets the following info for display on the save list menu:
# - player name
# - date
# - player money
# - player monsters
static func get_save_info(save_dir: String) -> Dictionary:
	var save_info = {}
	var data: Dictionary = U.read_file(get_filepath(save_dir, PLAYER))
	for k in ['player_name', 'time', 'money', 'playtime']:
		save_info[k] = data.get(k, "")
	save_info.encyclopedia = Data.get_completion_percent(
		data.get('discovered', {})
	)
	save_info.monsters = data.get('monster_count', 0)
	save_info.save_dir = save_dir
	return save_info

# --------------------------------------------------------------------------- #

static func get_save_info_list():
	return get_save_list().map(func (s): return get_save_info(s))


# =========================================================================== #
#                  S A V I N G   &   L O A D I N G   D A T A                  #
# --------------------------------------------------------------------------- #

static func new_save(pname: String) -> String:
	# load fresh save data
	var save = U.read_file(NEW_SAVE)
	save.player.player_name = pname

	# create new save
	if !DirAccess.dir_exists_absolute(SAVE_ROOT):
		DirAccess.make_dir_absolute(SAVE_ROOT)

	var save_dir = create_dirname(pname)
	DirAccess.make_dir_absolute(SAVE_ROOT.path_join(save_dir))
	write(save, save_dir)
	return save_dir

# --------------------------------------------------------------------------- #

static func write(data: Dictionary, save_dir: String):
	U.write_file(get_filepath(save_dir, PLAYER), data.player)
	U.write_file(get_filepath(save_dir, GARDEN), data.garden)

# --------------------------------------------------------------------------- #

static func read(save_dir: String):
	return {
		"player": U.read_file(get_filepath(save_dir, PLAYER)),
		"garden": U.read_file(get_filepath(save_dir, GARDEN)),
	}


# =========================================================================== #
#                      U T I L I T Y   F U N C T I O N S                      #
# --------------------------------------------------------------------------- #

static func is_save(dir_name: String) -> bool:
	var save_path = SAVE_ROOT.path_join(dir_name)
	return (DirAccess.dir_exists_absolute(save_path) and
			FileAccess.file_exists(save_path.path_join(PLAYER)) and
			FileAccess.file_exists(save_path.path_join(GARDEN)))

# --------------------------------------------------------------------------- #

static func get_filepath(save_dir: String, file_name: String) -> String:
	return SAVE_ROOT.path_join(save_dir).path_join(file_name)

# --------------------------------------------------------------------------- #

static func get_save_time(save_dir):
	return FileAccess.get_modified_time(get_filepath(save_dir, PLAYER))

# --------------------------------------------------------------------------- #

# strips numbers and any char not a-z, lowercases, then appends the current
# unix time to the formatted result to ensure a unique directory name.
# (TODO: should ideally convert unicode chars eg. 'e-acute' to their plain
# ascii counterpart eg. 'e' when possible, rather than just stripping them out)
#
# only used once, when creating a new save directory.
static func create_dirname(dirname: String) -> String:
	var newstr = ""
	for i in dirname:
		if (i >= 'a' and i <= 'z') or (i >= 'A' and i <= 'Z'):
			newstr += i
		if i == ' ':
			newstr += '_'
	return newstr.to_lower() + "_" + str(Time.get_unix_time_from_system())
