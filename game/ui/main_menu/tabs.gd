extends Control

@onready var MenuTab = U.load_relative(scene_file_path, 'menu_tab')

# array of tabs from left to right. when we open a chapter (thus updating the
# current tab), we move all the tabs left of it to `prev` and all the tabs
# right of it to `next`.
var tabs: Array[Control]

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func initialize(chapters):
	for key in chapters:
		var chapter = chapters[key]
		if ((not 'CONDITION' in chapter) or Condition.resolve(chapter.CONDITION)):
			var tab = MenuTab.instantiate()
			tab.load_info(key, chapter)
			tabs.push_back(tab)
			# add tabs to an invisible control so they'll be available for reparenting
			$bench.add_child(tab)

# =========================================================================== #
#                             P A G I N A T I O N                             #
# --------------------------------------------------------------------------- #

# must be called from MainMenu.open - if we connect to the dispatcher signal on
# ready we will miss the first emit
func open(input):
	var path = U.pack(input)
	var chapter = U.aget(path, 0)
	if chapter == null:
		Log.error(self, ["(open) unexpected: chapter should not be null"])
		return
	
	# if there is a section, stick the "current" chapter tab in prevs so we can
	# navigate back to it.  "index" is the name for the first page
	var has_section = path.size() > 1 and path[1] != 'index'
	
	var i = U.find_by(tabs, func(x, _i): return x.id == chapter)
	
	# start with all tabs benched to ensure they all get moved.
	# this is necessary to preserve correct ordering
	for tab in tabs:
		# menu_tab only responds to hover and clicks when is_current is false
		tab.is_current = false
		tab.reparent($bench)
	
	var current = null if has_section else tabs[i]
	var prevs = tabs.slice(0, i + 1 if has_section else i)
	var nexts = tabs.slice(i + 1)
	# $next is set to RTL so tabs will be layered left-above-right,
	# which means we need to add tabs to it in reverse order
	nexts.reverse()
	
	for tab in prevs: tab.reparent($prev)
	for tab in nexts: tab.reparent($next)
	if current:
		current.reparent($current)
		current.is_current = true
