extends Node

const SAVE_ROOT = "user://saves/"
const PLAYER = "player.save"
const GARDEN = "garden.save"
const NEW_SAVE = "res://data/system/new.save"

var current_save_dir
# probably not the best idea, but seems to work fine for now
# var dir = Directory.new()


# =========================================================================== #
#                      G E T T I N G   S A V E   I N F O                      #
# --------------------------------------------------------------------------- #
# scans the SAVE_ROOT dir for valid save directories.
func get_save_list():
	var dir = DirAccess.open(SAVE_ROOT)
	var saves = []
	if !dir: return
	dir.list_dir_begin()
	var current = dir.get_next()
	while (current != ""):
		if is_save(current):
			Log.debug(self, ["Found save: ", current])
			saves.append(current)
		current = dir.get_next()
	saves.sort_custom(Callable(self, "sort_by_date"))
	return saves

# --------------------------------------------------------------------------- #

func sort_by_date(a, b):
	return get_save_time(a) > get_save_time(b)

# --------------------------------------------------------------------------- #

# gets the following info for display on the save list menu:
# - player name
# - date
# - player money
# - player monsters
func get_save_info(save_dir):
	var save_info = {}
	var data = Utils.read_file(get_filepath(save_dir, PLAYER))
	for k in ["player_name", "time", "money", "playtime"]:
		save_info[k] = data[k]
	save_info.encyclopedia = data.encyclopedia.completion
	save_info.monsters = data.monster_count
	save_info.save_dir = save_dir
	return save_info

# --------------------------------------------------------------------------- #

func get_save_time(save_dir):
	return FileAccess.get_modified_time(get_filepath(save_dir, PLAYER))

# --------------------------------------------------------------------------- #

func get_save_info_list():
	var saves = []
	for save in get_save_list():
		saves.append(get_save_info(save))
	saves.sort_custom(Callable(self, "sort_saves"))
	Log.debug(self, saves)
	return saves


# =========================================================================== #
#                  S A V I N G   &   L O A D I N G   D A T A                  #
# --------------------------------------------------------------------------- #

func new_save(pname):
	# load fresh save data
	var save = Utils.read_file(NEW_SAVE)
	save.player.player_name = pname

	# create new save
	if !DirAccess.dir_exists_absolute(SAVE_ROOT):
		DirAccess.make_dir_absolute(SAVE_ROOT)

	current_save_dir = create_dirname(pname)
	DirAccess.make_dir_absolute(SAVE_ROOT.path_join(current_save_dir))
	save_game(save)

	return current_save_dir

# --------------------------------------------------------------------------- #

func save_game(data, save_dir = current_save_dir):
	Utils.write_file(get_filepath(save_dir, PLAYER), data.player)
	Utils.write_file(get_filepath(save_dir, GARDEN), data.garden)

# --------------------------------------------------------------------------- #

func load_game(save_dir):
	current_save_dir = save_dir
	return {
		"player": Utils.read_file(get_filepath(save_dir, PLAYER)),
		"garden": Utils.read_file(get_filepath(save_dir, GARDEN)),
	}


# =========================================================================== #
#                      U T I L I T Y   F U N C T I O N S                      #
# --------------------------------------------------------------------------- #
func is_save(dir_name):
	var save_path = SAVE_ROOT.path_join(dir_name)
	return (DirAccess.dir_exists_absolute(save_path) and
			FileAccess.file_exists(save_path.path_join(PLAYER)) and
			FileAccess.file_exists(save_path.path_join(GARDEN)))

# --------------------------------------------------------------------------- #

func get_filepath(save_dir, file_name):
	return SAVE_ROOT.path_join(save_dir).path_join(file_name)

# --------------------------------------------------------------------------- #

# order save info by timestamp, so the most recent save will show first on the
# save list.
func sort_save_info(a, b):
	if get_save_time(a.save_dir) > get_save_time(b.save_dir):
		return true
	return false

# --------------------------------------------------------------------------- #

# strips numbers and any char not a-z, lowercases, then appends the current
# unix time to the formatted result to ensure a unique directory name.
# (TODO: should ideally convert unicode chars eg. 'e-acute' to their plain
# ascii counterpart eg. 'e' when possible, rather than just stripping them out)
#
# only used once, when creating a new save directory.
func create_dirname(dirname):
	var newstr = ""
	for i in dirname:
		if (i >= 'a' and i <= 'z') or (i >= 'A' and i <= 'Z'):
			newstr += i
		if i == ' ':
			newstr += '_'
	return newstr.to_lower() + "_" + str(Time.get_unix_time_from_system())
