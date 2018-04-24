extends Node

const SAVE_ROOT = "user://saves/"
const PLAYER = "player.save"
const GARDEN = "garden.save"
const NEW_SAVE = "res://system/new_save.data"

var current_save_dir
# probably not the best idea, but seems to work fine for now
var dir = Directory.new()


# =========================================================== #
#              G E T T I N G   S A V E   I N F O              #
# ----------------------------------------------------------- #

# scans the SAVE_ROOT dir for valid save directories.
func get_save_list():
	var saves = []
	if dir.open(SAVE_ROOT) != OK:
		return
	dir.list_dir_begin(true)
	var current = dir.get_next()
	while (current != ""):
		if is_save(current):
			print("Found save: ", current)
			saves.append(current)
		current = dir.get_next()
	return saves

# ------------------------------------------------------------

# gets the following info for display on the save list menu:
# - player name
# - date
# - player money
# - player monsters
func get_save_info(save_dir):
	var save_info = {}
	var data = parse_json(read_file(get_path(save_dir, PLAYER)))
	for k in ["player_name", "time", "money", "playtime"]:
		save_info[k] = data[k]
	save_info.encyclopedia = data.encyclopedia.completion
	save_info.monsters = data.monster_count
	save_info.save_dir = save_dir
	return save_info

# ------------------------------------------------------------

func get_save_time(save_dir):
	return File.new().get_modified_time(get_path(save_dir, PLAYER))

# ------------------------------------------------------------

func get_save_info_list():
	var saves = []
	for save in get_save_list():
		saves.append(get_save_info(save))
	saves.sort_custom(self, "sort_saves")
	print(saves)
	return saves


# =========================================================== #
#          S A V I N G   &   L O A D I N G   D A T A          #
# ----------------------------------------------------------- #

func new_save(pname):
	# load fresh save data
	var new_save = parse_json(read_file(NEW_SAVE))
	new_save.player.player_name = pname
	
	# create new save
	current_save_dir = create_dirname(pname)
	dir.make_dir(current_save_dir)
	save_game(new_save)
	
	return current_save_dir

# -----------------------------------------------------------

func save_game(data, save_dir = current_save_dir):
	write_file(get_path(save_dir, PLAYER), data.player)
	write_file(get_path(save_dir, GARDEN), data.garden)

# -----------------------------------------------------------

func load_game(save_dir):
	current_save_dir = save_dir
	return {
		"player": parse_json(read_file(get_path(save_dir, PLAYER))),
		"garden": parse_json(read_file(get_path(save_dir, GARDEN))),
	}


# =========================================================== #
#                       F I L E   I / O                       #
# ----------------------------------------------------------- #

func write_file(path, data):
	var file = File.new()
	file.open(path, File.WRITE)
	print(file.file_exists(path))
	file.store_string(to_json(data))
	file.close()

# -----------------------------------------------------------

func read_file(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = file.get_as_text()
	file.close()
	return data


# =========================================================== #
#              U T I L I T Y   F U N C T I O N S              #
# ----------------------------------------------------------- #

func is_save(dir_name):
	return (dir.current_is_dir() and 
			dir.file_exists(dir_name.plus_file(PLAYER)) and
			dir.file_exists(dir_name.plus_file(GARDEN)))

# -----------------------------------------------------------

func get_path(save_dir, file_name):
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

# -----------------------------------------------------------

func set_autosave_interval(interval):
	Time.connect("hour_changed", self, "save_game")