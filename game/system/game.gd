extends Node

func _ready(): 
	Dispatcher.connect("new_game", self, "new_game")
	Dispatcher.connect("load_game", self, "load_game")
	Dispatcher.connect("save_game", self, "save_game")
	Dispatcher.connect("quit_game", self, "quit_game")
	# testing data parsing. like magic!
	#for k in Data.data.monsters.pufig:
	#	print(k, ": ", Data.id("pufig")[k])
	
	#$pufig.texture = Data.id["pufig"].sprite
	
	#Data.filter({from = "game"})
#	Data.get("pufig").sprite
#	Data.id("pufig").sprite
#	Data.type("monsters").sprite
	
	#Data.monsters["pufig"].sprite
	Dispatcher.emit_signal("ui_open", "title_screen")
#	Dispatcher.emit("load_game", "test_1524444746")
#	Dispatcher.emit("load_game", "gayton_1524538240")
#	Dispatcher.emit("menu_open", "inventory")


# =========================================================== #
#                        L O A D I N G                        #
# ----------------------------------------------------------- #

# loading a predefined "fresh" save is probably the way to go
# here. default values will have to be defined for everybody 
# that normally relies on save data, anyway, so might as well 
# do it all in one place.
func new_game(player_name):
	Log.info(self, ["Starting new game: ", player_name])
	var new_save = SaveManager.new_save(player_name)
	load_game(new_save)

# -----------------------------------------------------------

func load_game(save_dir):
	var data = SaveManager.load_game(save_dir)
	load_player(data.player)
	load_garden(data.garden)

# -----------------------------------------------------------

func load_player(data):
	# process the player data
	Player.deserialize(data)
	Time.deserialize(data.time)

# -----------------------------------------------------------

func load_garden(data):
	# proces the garden data. garden is an instanced node,
	# unlike player and time, and it must instantiate its
	# children depending on the contents of the save file.
	var garden = load("res://garden/garden.tscn").instance()
	add_child(garden)
	garden.deserialize(data)


# =========================================================== #
#                         S A V I N G                         #
# ----------------------------------------------------------- #

func save_game():
	SaveManager.save_game({ 
		"player": save_player(), 
		"garden": save_garden()
	})

# -----------------------------------------------------------

func save_player():
	var data = Player.serialize()
	data.time = Time.serialize()
	#data.monster_count = garden.get_monsters().size()
	return data

# -----------------------------------------------------------

func save_garden():
	return $garden.serialize()

# -----------------------------------------------------------

func quit_game():
	get_tree().quit()