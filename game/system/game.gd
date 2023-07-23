extends Node

var garden: Garden
var current_save_dir: String

func _ready():
	# connect all the signals for manipulating game state (see Dispatcher.gd)
	for i in ['new', 'load', 'save', 'quit', 'reset']:
		var sig = str(i, '_game')
		(Dispatcher[sig] as Signal).connect(Callable(self, sig))
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Data.init()
	Dispatcher.ui_open.emit("title_screen")


# =========================================================================== #
#                                L O A D I N G                                #
# --------------------------------------------------------------------------- #

# loading a predefined "fresh" save is probably the way to go here. default
# values will have to be defined for everybody that normally relies on save
# data, anyway, so might as well do it all in one place.
func new_game(player_name):
	Log.info(self, ["Starting new game: ", player_name])
	var new_save_dir = SaveUtils.new_save(player_name)
	load_game(new_save_dir)

# --------------------------------------------------------------------------- #

func load_game(save_dir: String):
	current_save_dir = save_dir
	var data = SaveUtils.read(current_save_dir)
	load_player(data.player)
	load_garden(data.garden)
	Dispatcher.date_changed.connect(save_game)

# --------------------------------------------------------------------------- #

func load_player(data):
	# process the player data
	Player.deserialize(data)
	Clock.deserialize(data.time)

# --------------------------------------------------------------------------- #

func load_garden(data):
	# process the garden data. garden is an instanced node, unlike player and
	# time, and it must instantiate its own children depending on the contents
	# of the save file.
	garden = preload("res://garden/garden.tscn").instantiate()
	$viewport.add_child(garden)
	garden.init(data)
	Player.garden = garden
	Dispatcher.ui_close.emit(0)


# =========================================================================== #
#                                 S A V I N G                                 #
# --------------------------------------------------------------------------- #

func save_game():
	if current_save_dir == null:
		Log.error(self, "no save directory")
		return
	SaveUtils.write({
		"player": save_player(),
		"garden": save_garden()
	}, current_save_dir)

# --------------------------------------------------------------------------- #

func save_player():
	var data = Player.serialize()
	data.time = Clock.serialize()
	data.monster_count = garden.monsters.size() if garden else 0
	return data

# --------------------------------------------------------------------------- #

func save_garden():
	if garden: return garden.serialize()


# =========================================================================== #
#                    Q U I T T I N G  /  R E L O A D I N G                    #
# --------------------------------------------------------------------------- #

func quit_game():
#	var process_id = OS.get_process_id()
#	print(process_id)
	get_tree().quit()
#	OS.kill(process_id)

# --------------------------------------------------------------------------- #

func reset_game():
	Clock.reset()
	Player.reset()
	get_tree().reload_current_scene()
