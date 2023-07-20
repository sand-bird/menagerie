extends RefCounted
class_name MenuChapter
"""
base class for menu chapters; implements nagivation logic general to all menu
chapters.  individual chapters should extend this class and implement their own
logic for initializing their sections based on game state.
"""

# dict of section keys to MenuSection PackedScenes.
# although sections are supposed to be ordered, we use a dict because we need to
# be able to nagivate directly to a specific section, identified by its key.
# fortunately godot appears to preserve ordering of dict properties, so ordering
# of sections _should_ still work.
# the key is also the param we pass into `initialize` on the MenuSection
# instance, eg a monster uuid for monster details.
var sections: Dictionary = {}

var current_section = null

func _init():
	build_index()

# open the chapter to the section associated with the key param, or to the first
# section if the key is null.
func open(key = null) -> Control: # key: String
	if sections.is_empty(): build_index()
	if sections.is_empty(): return
	if key == null: key = sections.keys()[0]
	if not key in sections:
		Log.error(self, ["tried to open invalid section: ", key])
		return
	var section = load(sections[key]).instantiate()
	section.initialize(key)
	current_section = key
	return section

func direction(new_section):
	var keys = sections.keys()
	var current_idx = keys.find(current_section)
	var new_idx = keys.find(new_section)
	return (1 if new_idx > current_idx else -1 if new_idx < current_idx else 0)


#                               a b s t r a c t                               #
# --------------------------------------------------------------------------- #

# populate the `sections` dict. the first key/value pair added will be the
# default, or "index" page.
func build_index(): pass

#                             s u b c l a s s e s                             #
# --------------------------------------------------------------------------- #

class Monsters extends MenuChapter:
	const PATH = "res://ui/main_menu/monsters"
	const ICON = "monster"
	func build_index():
		sections[null] = PATH.path_join("monster_list.tscn")
		for uuid in (Player.garden.monsters if Player.garden != null else []):
			sections[uuid] = PATH.path_join("monster_details.tscn")

class Items extends MenuChapter:
	const PATH = "res://ui/main_menu/inventory"
	const ICON = "items"
	func build_index(): sections[null] = PATH.path_join("items.tscn")

class Objects extends MenuChapter:
	const PATH = "res://ui/main_menu/inventory"
	const ICON = "inventory"
	func build_index(): sections[null] = PATH.path_join("objects.tscn")

class TownMap extends MenuChapter:
	const PATH = "res://ui/main_menu/town_map"
	const ICON = "town"
	func build_index(): sections[null] = PATH.path_join("town_map.tscn")

class Calendar extends MenuChapter:
	const PATH = "res://ui/main_menu/calendar"
	const ICON = "calendar"
	func build_index(): sections[null] = PATH.path_join("calendar.tscn")

class Encyclopedia extends MenuChapter:
	const PATH = "res://ui/main_menu/encyclopedia"
	const ICON = "encyclopedia"
	func build_index(): sections[null] = PATH.path_join("encyclopedia.tscn")

class Settings extends MenuChapter:
	const PATH = "res://ui/main_menu/settings"
	const ICON = "options"
	func build_index(): sections[null] = PATH.path_join("settings.tscn")
