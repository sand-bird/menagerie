extends Control

@onready var MenuTab = U.load_relative(scene_file_path, 'menu_tab')

# array of tabs from left to right. when we open a chapter (thus updating the
# current tab), we move all the tabs left of it to `prev` and all the tabs
# right of it to `next`.
var tabs: Array[Control]

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready():
	for id in MainMenu.CHAPTERS:
		var chapter = MainMenu.CHAPTERS[id]
		if (!chapter.has('condition') or
				Condition.resolve(chapter.condition)):
			var tab = MenuTab.instantiate()
			tab.load_info(id, chapter)
			tabs.push_back(tab)
			# add tabs to an invisible control so they'll be available for reparenting
			$bench.add_child(tab)

# =========================================================================== #
#                             P A G I N A T I O N                             #
# --------------------------------------------------------------------------- #

# must be called from MainMenu.open - if we connect to the dispatcher signal on
# ready we will miss the first emit
func open(chapter = null):
	if chapter == null:
		Log.error(self, ["(open) unexpected: chapter should not be null"])
	var i = U.find_by(tabs, func(x, _i): return x.id == chapter)
	
	# start with all tabs benched to ensure they all get moved.
	# this is necessary to preserve correct ordering
	for tab in tabs:
		# menu_tab only responds to hover and clicks when is_current is false
		tab.is_current = false
		tab.reparent($bench)
	
	var prevs = tabs.slice(0, i)
	var nexts = tabs.slice(i + 1)
	var current = tabs[i]
	
	for tab in prevs: tab.reparent($prev)
	for tab in nexts: tab.reparent($next)
	current.reparent($current)
	current.is_current = true

