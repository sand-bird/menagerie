extends Control
class_name MenuChapter
"""
base class for menu chapters; implements nagivation logic general to all menu
chapters.  individual chapters should extend this class and implement their own
logic for initializing their sections based on game state.
"""
# deprecated
var title: String
func initialize(_arg = null): pass

# dict of section keys to MenuSection PackedScenes.
# although sections are supposed to be ordered, we use a dict because we need to
# be able to nagivate directly to a specific section, identified by its key.
# fortunately godot appears to preserve ordering of dict properties, so ordering
# of sections _should_ still work.
# the key is also the param we pass into `initialize` on the MenuSection
# instance, eg a monster uuid for monster details.
var sections: Dictionary = {}

func _ready():
	build_index()

# open the chapter to the section associated with the key param, or to the first
# section if the key is null.
func open(key = null): # key: String
	if sections.is_empty(): build_index()
	if sections.is_empty(): return
	if key == null: key = sections.keys()[0]
	if not key in sections:
		Log.error(self, ["tried to open invalid section: ", key])
		return
	var scene = load(sections[key]).instantiate()
	scene.initialize(key)
	add_child(scene)

#                               a b s t r a c t                               #
# --------------------------------------------------------------------------- #

# populate the `sections` dict. the first key/value pair added will be the
# default, or "index" page.
func build_index():
	sections = {}
