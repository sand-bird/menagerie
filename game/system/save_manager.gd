extends Node

const SAVE_ROOT = "user://saves/"
const PLAYER = "player.save"
const GARDEN = "garden.save"
const NEW_SAVE = "res://data/system/new_save.json"

var current_save_dir
# probably not the best idea, but seems to work fine for now
# var dir = Directory.new()


# =========================================================== #
#              G E T T I N G   S A V E   I N F O              #
# ----------------------------------------------------------- #

# scans the SAVE_ROOT dir for valid save directories.
func get_save_list():
	var dir = Directory.new()
	var saves = []
	if dir.open(SAVE_ROOT) != OK:
		return
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		if is_save(current):
			Log.debug(self, ["Found save: ", current])
			saves.append(current)
		current = dir.get_next()
	saves.sort_custom(self, "sort_by_date")
	return saves

# ------------------------------------------------------------

func sort_by_date(a, b):
	var file = File.new()
	return (file.get_modified_time(get_filepath(a, PLAYER))
			> file.get_modified_time(get_filepath(b, PLAYER)))

# ------------------------------------------------------------

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

# ------------------------------------------------------------

func get_save_time(save_dir):
	return File.new().get_modified_time(get_filepath(save_dir, PLAYER))

# ------------------------------------------------------------

func get_save_info_list():
	var saves = []
	for save in get_save_list():
		saves.append(get_save_info(save))
	saves.sort_custom(self, "sort_saves")
	Log.debug(self, saves)
	return saves


# =========================================================== #
#          S A V I N G   &   L O A D I N G   D A T A          #
# ----------------------------------------------------------- #

func new_save(pname):
	# load fresh save data
	var new_save = Utils.read_file(NEW_SAVE)
	new_save.player.player_name = pname

	# create new save
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_ROOT):
		dir.make_dir(SAVE_ROOT)

	current_save_dir = create_dirname(pname)
	dir.make_dir(SAVE_ROOT.plus_file(current_save_dir))
	save_game(new_save)

	return current_save_dir

# -----------------------------------------------------------

func save_game(data, save_dir = current_save_dir):
	Utils.write_file(get_filepath(save_dir, PLAYER), data.player)
	Utils.write_file(get_filepath(save_dir, GARDEN), data.garden)

# -----------------------------------------------------------

func load_game(save_dir):
	current_save_dir = save_dir
	return {
		"player": Utils.read_file(get_filepath(save_dir, PLAYER)),
		"garden": Utils.read_file(get_filepath(save_dir, GARDEN)),
	}


# =========================================================== #
#              U T I L I T Y   F U N C T I O N S              #
# ----------------------------------------------------------- #

func is_save(dir_name):
	var dir = Directory.new()
	var save_path = SAVE_ROOT.plus_file(dir_name)
	return (dir.dir_exists(save_path) and
			dir.file_exists(save_path.plus_file(PLAYER)) and
			dir.file_exists(save_path.plus_file(GARDEN)))

# -----------------------------------------------------------

func get_filepath(save_dir, file_name):
	return SAVE_ROOT.plus_file(save_dir).plus_file(file_name)

# -----------------------------------------------------------

# order save info by timestamp, so the most recent save will
# show first on the save list.
func sort_save_info(a, b):
	if get_save_time(a.save_dir) > get_save_time(b.save_dir):
		return true
	return false

# -----------------------------------------------------------

# strips numbers and any char not a-z, then lowercases.
# (in future, should convert unicode chars eg. 'e-acute' to
# their plain ascii counterpart eg. 'e' when possible.)
#
# then appends the current unix time to the formatted result
# to ensure a unique directory name.
#
# only used once, when creating a new save directory.
func create_dirname(name):
	var newstr = ""
	for i in name:
		if (i >= 'a' and i <= 'z') or (i >= 'A' and i <= 'Z'):
			newstr += i
		if i == ' ':
			newstr += '_'
	return newstr.to_lower() + "_" + str(OS.get_unix_time())
