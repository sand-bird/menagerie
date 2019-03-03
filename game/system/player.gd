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
var inventory = []

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
# (note: should this be a property of the npc instance? makes
# sense intuitively, but in practice it's probably better to
# centralize that info here, especially since it comes from 
# player.save)
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

# =========================================================== #
#                  S E R I A L I Z A T I O N                  #
# ----------------------------------------------------------- #

const SAVE_KEYS = [
	"player_name", "playtime", "level", "money",
	"encyclopedia", "inventory",
	"requests", "completed_requests",
]

# -----------------------------------------------------------

func serialize():
	var data = {}
	update_playtime()
	for k in SAVE_KEYS: data[k] = get(k)
	return data

# -----------------------------------------------------------

func deserialize(data):
	for k in SAVE_KEYS: set(k, data[k])
	last_update_time = OS.get_unix_time()


# =========================================================== #
#                       P L A Y T I M E                       #
# ----------------------------------------------------------- #

func update_playtime():
	var current_time = OS.get_unix_time()
	var playtime_difference = current_time - last_update_time
	playtime += playtime_difference
	Log.info(self, ["Updated playtime: ", playtime, 
			" (difference: ", playtime_difference, ")"])
	last_update_time = current_time

# -----------------------------------------------------------

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
