extends Node

# since there's only one player at a time, Player basically functions as a
# store for game state. pretty much everything here is saved to and loaded from
# the `player.save` file.

var player_name
var playtime
var last_update_time # used to update playtime
var money

var garden

# entity names that should be revealed in the encyclopedia
# (values should all be `true` unless we want to un-discover something).
# we use a dictionary so it's trivial to discover an entity when we add it to
# the inventory, and so that we can sub-discover states/morphs of an entity.
var discovered = { "bunny": true }

# keyed by entity id. values can be either an array of objects or an integer.
# the idea is that inventory items (entities of type "item", like fruits, or
# "object", like trees) can have arbitrary internal state, so you can't just
# stack up multiples with the same id.
#
# keying inventory items by id allows us to neatly filter out entities that are
# not present in Data (eg, because a mod was removed).
var inventory = { }

# --------------------------------------------------------------------------- #

# ui elements are loaded and unloaded as needed, so they can't hold state (and
# shouldn't anyway). but we do want to remember some state info, like what page
# we were on and what we had selected, so we should save that here.
var current_inventory_item = 0
var current_inventory_filter = {}

# --------------------------------------------------------------------------- #

func _ready():
	pass

# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
const SAVE_KEYS = [
	"player_name", "playtime", "money",
	"discovered", "inventory"
]

# --------------------------------------------------------------------------- #

func serialize():
	var data = {}
	update_playtime()
	for k in SAVE_KEYS: data[k] = get(k)
	return data

# --------------------------------------------------------------------------- #

func deserialize(data):
	for k in SAVE_KEYS: set(k, data[k])
	last_update_time = Time.get_unix_time_from_system()


# =========================================================================== #
#                               P L A Y T I M E                               #
# --------------------------------------------------------------------------- #
func update_playtime():
	var current_time = Time.get_unix_time_from_system()
	var playtime_difference = current_time - last_update_time
	playtime += playtime_difference
	Log.info(self, ["Updated playtime: ", playtime,
			" (difference: ", playtime_difference, ")"])
	last_update_time = current_time

# --------------------------------------------------------------------------- #

func get_printable_playtime(time = null):
	if time == null:
		time = playtime
	# convert to minutes. playtime isn't updated often enough for us to watch it
	# tick, so we don't care about seconds. (maybe change this later anyway)
	time = int(time / 60)
	var hour = int(time / 60)
	var minute = int(time) % 60
	return str(hour) + ":" + str(minute).pad_zeros(2)


# =========================================================================== #
#                              I N V E N T O R Y                              #
# --------------------------------------------------------------------------- #

# 1. if we don't have any of this entity yet, add a key to the inventory for it
#    whose value is an empty array, and add it to `discovered`
# 2. if we do have one, go through the values until we find one that matches
#    the input object's state, and increment its qty
# 3. else, add the input item to the end of the value array
func inventory_add(serialized):
	if not serialized.id in inventory:
		inventory[serialized.id] = []
		discovered[serialized.id] = true
	for saved in inventory[serialized.id]:
		if saved == serialized: saved.qty += 1 # TODO: need to strip qty for this to work
	inventory[serialized.id].push_back(serialized)

# takes an entity id and index and either decrements qty or removes the element
func inventory_remove(id, index):
	pass


# =========================================================================== #
#                           E N C Y C L O P E D I A                           #
# --------------------------------------------------------------------------- #

