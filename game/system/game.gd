extends Node

var garden

func _ready():
	Dispatcher.new_game.connect(new_game)
	Dispatcher.load_game.connect(load_game)
	Dispatcher.save_game.connect(save_game)
	Dispatcher.quit_game.connect(quit_game)

	Data.init()
	Dispatcher.emit_signal("ui_open", "title_screen")


# =========================================================================== #
#                                L O A D I N G                                #
# --------------------------------------------------------------------------- #

# loading a predefined "fresh" save is probably the way to go here. default
# values will have to be defined for everybody that normally relies on save
# data, anyway, so might as well do it all in one place.
func new_game(player_name):
	Log.info(self, ["Starting new game: ", player_name])
	var new_save = SaveManager.new_save(player_name)
	load_game(new_save)

# --------------------------------------------------------------------------- #

func load_game(save_dir):
	var data = SaveManager.load_game(save_dir)
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
	Dispatcher.emit_signal("ui_close", 0)


# =========================================================================== #
#                                 S A V I N G                                 #
# --------------------------------------------------------------------------- #
func save_game():
	SaveManager.save_game({
		"player": save_player(),
		"garden": save_garden()
	})

# --------------------------------------------------------------------------- #

func save_player():
	var data = Player.serialize()
	data.time = Clock.serialize()
	data.monster_count = garden.monsters.size() if garden else 0
	return data

# --------------------------------------------------------------------------- #

func save_garden():
	if garden: return garden.serialize()

# --------------------------------------------------------------------------- #

func quit_game():
#	var process_id = OS.get_process_id()
#	print(process_id)
	get_tree().quit()
#	OS.kill(process_id)
