extends Node

signal inventory_changed

# since there's only one player at a time, Player basically functions as a
# store for game state. pretty much everything here is saved to and loaded from
# the `player.save` file.

var player_name: String = ""
var playtime: float = 0
var last_update_time: int = 0 # used to update playtime
var money: int = 0

var garden: Garden

# entity names that should be revealed in the encyclopedia.
# we use a dictionary so it's trivial to look up an entity to see whether it has
# already been discovered, and so that we can sub-discover states/morphs of an
# entity.
# there are 2 kinds of discoverable entity:
# 1. "complex" discoverables have sub-discoverables and are represented as dicts
#    whose keys are the id of the sub-discoverable and values are booleans.
#    currently these are monsters (with morphs) and objects (with states).
# 2. "simple" discoverables do not have sub-discoverables and are represented
#    with boolean values.
var discovered = { bunny = { sprout = true }, fluffy_tuft = true }

# keys are entity ids, values are arrays of serialized instances.
# keying inventory items by id allows us to neatly filter out entities that are
# not present in Data (eg because a mod was removed), and quickly reference all
# stored entities of the same type.
# each element in the value array has some distinct state which prevents it from
# being stacked with any of its siblings, and a `qty` field which is not part of
# the entity itself.  when inserting to the inventory, if we find an existing
# element with which the new one _can_ be stacked (because the serialized data
# is identical), we increment its qty.  otherwise, we append the new element
# to the back of the array.
var inventory = {}

# --------------------------------------------------------------------------- #

# ui elements are loaded and unloaded as needed, so they can't hold state (and
# shouldn't anyway). but we do want to remember some state info, like what page
# we were on and what we had selected, so we should save that here.
var current_inventory_item: int = 0
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
	for k in SAVE_KEYS:
		var value = data.get(k)
		# dirty check to prevent errors if the save format is old
		if value != null and typeof(value) == typeof(get(k)):
			set(k, data[k])
	last_update_time = int(Time.get_unix_time_from_system())

# --------------------------------------------------------------------------- #

# manually deinitialize Player state when we reload the game.
# called from `reset_game` in `game.gd`, which listens to the `reset_game` 
# signal from the dispatcher.
func reset():
	player_name = ""
	playtime = 0
	last_update_time = 0
	money = 0
	discovered = {}
	inventory = {}
	garden = null

# =========================================================================== #
#                               P L A Y T I M E                               #
# --------------------------------------------------------------------------- #

func update_playtime():
	var current_time = int(Time.get_unix_time_from_system())
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

# checks if new and saved are identical except for `qty`.
# this modifies the `qty` property on `new`, but it's ok since we won't use it
func is_stackable(new: Dictionary, saved: Dictionary):
	new.merge({ qty = saved.qty }, true)
	var result = U.deep_equals(new, saved)
	return result

# --------------------------------------------------------------------------- #

# takes in a serialized entity, meaning it should have all of its required
# state params (most notably for now, these are `id`, `morph` on monsters, and
# `state` on objects).
# 1. if we don't have any of this entity yet, add a key to the inventory for it
#    whose value is an empty array, and add it to `discovered`
# 2. if we do have one, go through the values until we find one that matches
#    the input object's state, and increment its qty
# 3. else, add the input item to the end of the value array
func inventory_add(serialized: Dictionary, qty: int = 1):
	if qty < 1:
		Log.error(self, [
			"(inventory_add) 'qty' must be a positive number, but was ", qty
		])
		return
	var id = serialized.id
	if Data.missing(id):
		Log.error(self, ["(inventory_add) can't add '", id,
			"' to inventory: not found in data"])
		return
	maybe_discover(serialized)
	if not id in inventory: inventory[id] = []
	for saved in inventory[id]:
		if is_stackable(serialized, saved):
			saved.qty += qty
			inventory_changed.emit()
			return
	serialized.merge({ qty = qty }, true)
	inventory[id].push_back(serialized)
	inventory_changed.emit()

# --------------------------------------------------------------------------- #

# get a stack from the inventory.  takes the id and index either as separate
# args or as an array (since that's how we store them in the inventory menu ui.)
func inventory_get(id, i = null):
	if typeof(id) == TYPE_ARRAY: i = id[1]; id = id[0]
	if !inventory.has(id) or inventory[id].size() <= i: return null
	return inventory[id][i]

# --------------------------------------------------------------------------- #

# takes an entity id and index and either decrements qty or removes the element
func inventory_remove(id, i):
	if id not in inventory:
		Log.error(self, [
			"tried to remove an invalid element from inventory: ", id
		])
		return
	var items: Array = inventory[id]
	if i not in range(0, items.size()):
		Log.error(self, [
			"tried to remove an invalid index from inventory element ", id, ": ",
			i, " (has length ", items.size(), ")"
		])
		i = clamp(i, 0, items.size() - 1)
	var item: Dictionary = items[i]
	# if we have more than 1, decrement qty and return a copy of the item
	if item.qty > 1:
		item.qty -= 1
		return item.duplicate(true).erase('qty')
	# if it's the last one, we need to remove it from the array
	items.remove_at(i)
	inventory_changed.emit()
	return item.erase('qty') # TODO: make sure this still works after remove


# =========================================================================== #
#                           E N C Y C L O P E D I A                           #
# --------------------------------------------------------------------------- #

# discover an entity and its morph/state if it has not been discovered yet.
# takes in a serialized entity, meaning we have access to its id and any state
# that should be serialized, but not data properties like type or description.
# TODO: fire dispatcher events when something is actually discovered
func maybe_discover(entity):
	var data = Data.fetch(entity.id)
	if data == null:
		Log.error(self, [
			"(maybe_discover) can't discover '", entity.id, "': not found in data"
		])
		return
	if entity.id not in discovered:
		@warning_ignore("incompatible_ternary")
		discovered[entity.id] = {} if (
			data.type in ['monster', 'object']
		) else true
	match data.type:
		'monster': maybe_discover_child(entity, 'morph')
		'object': maybe_discover_child(entity, 'state')

# discover a child discoverable of the given entity if it has not already been
# discovered.  key is either 'morph' (for monsters) or 'state' (for objects),
# since those are the only kinds of sub-discoverables we have right now.
func maybe_discover_child(entity, child_key):
	var record = discovered[entity.id]
	if child_key not in entity:
		Log.error(self, [
			"(maybe_discover_child) found a ", Data.fetch([entity.id, 'type']),
			" without a ", child_key, ": ", entity
		])
		return
	var child_id = entity[child_key]
	if child_id not in record:
		record[child_id] = true
