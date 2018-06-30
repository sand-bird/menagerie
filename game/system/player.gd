extends Node

# class Player
# ------------
# since there's only one player at a time, Player basically
# functions as a store for game state. pretty much everything
# here is saved to and loaded from the `player.save` file.

var player_name
var playtime
var last_update_time # used to update playtime
var money
var level

# the big boys
var encyclopedia = {}
var inventory = [
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 1
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 2
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 3
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 4
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 5
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 6
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 7
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 8
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 9
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 10
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 11
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 12
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 13
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 14
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 15
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 16
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 17
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 18
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 19
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 20
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 21
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 22
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 23
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 24
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 25
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 26
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 27
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 28
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 29
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 30
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 31
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 32
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 33
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 34
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 35
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 36
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 37
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 38
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 39
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 40
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 41
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 42
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 43
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 44
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 45
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 46
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 47
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 48
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 49
	},
	{
		type = Constants.Type.ITEM,
		id = "fluffy_tuft",
		qty = 50
	}
]

# this should store the letter fragments the player has seen,
# and how often they've occurred (i guess)
var letters

var requests # "current" is too verbose and should be implied
var completed_requests
# expired requests: own category, put them in completed with 
# a FAILED tag or something, or don't remember them at all? 
#
# tracking expired requests implies not allowing them to be 
# generated again, which might be overly punishing. (could 
# also be to prevent the same type of request from being 
# generated too often, which is ok but probably not a big 
# enough deal to be worth it.)

# not really a huge feature, but npcs should warm up to you
# as you interact with them and complete requests
var relationships

# -----------------------------------------------------------

# ui elements are loaded and unloaded as needed, so they
# can't hold state (and shouldn't anyway). but we do want to
# remember some state info, like what page we were on and
# what we had selected, so we should save that here.
var current_inventory_item = 5
var current_inventory_filter = {}

# -----------------------------------------------------------

func _ready():
	pass

# -----------------------------------------------------------

const SAVE_KEYS = [
	"player_name", "playtime", "level", "money",
	"encyclopedia", "inventory",
	"requests", "completed_requests",
]

func serialize():
	var data = {}
	update_playtime()
	for k in SAVE_KEYS: data[k] = self[k]
	return data

func deserialize(data):
	for k in SAVE_KEYS: self[k] = data[k]
	last_update_time = OS.get_unix_time()

# -----------------------------------------------------------

func update_playtime():
	var current_time = OS.get_unix_time()
	var playtime_difference = current_time - last_update_time
	playtime += playtime_difference
	Log.info(self, ["Updated playtime: ", playtime, 
			" (difference: ", playtime_difference, ")"])
	last_update_time = current_time

func get_printable_playtime(time = null):
	if time == null:
		time = playtime
	# convert to minutes. playtime isn't updated often 
	# enough for us to sit and watch it tick, so we don't 
	# care about seconds. (maybe change this later anyway)
	time = int(time / 60)
	var hour = int(time / 60)
	var minute = int(time) % 60
	return str(hour) + ":" + str(minute).pad_zeros(2)

# -----------------------------------------------------------