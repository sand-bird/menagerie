extends Node

# as of godot 3.1, we're getting a bunch of unused signal warnings for signals
# that are in fact being used - probably still some bugs in the new linter.
# disable warnings for now
#warning-ignore-all:unused_signal

# the dispatcher handles every signal in the game, except for a couple used by
# parent nodes to receive events from their children.

# we also create some signals from unhandled inputs (for now) that map to
# fairly universal actions, like closing a menu with ui_cancel. the idea is, if
# some other node needs that input for its own stuff, it should mark it as
# handled. not sure if this will work long term tho.

# =========================================================================== #
#                                S I G N A L S                                #
# --------------------------------------------------------------------------- #
#                                   g a m e                                   #
# --------------------------------------------------------------------------- #
signal new_game
signal load_game
signal save_game
signal quit_game

#                                   t i m e                                   #
# --------------------------------------------------------------------------- #
signal tick_changed
signal hour_changed
signal date_changed
signal month_changed
signal year_changed

#                                     u i                                     #
# --------------------------------------------------------------------------- #
signal ui_open(args)
signal ui_close

signal menu_open(args)

# emitted by grid_items in the inventory page of the main menu
signal item_selected(item_info)

#                                 g a r d e n                                 #
# --------------------------------------------------------------------------- #
signal entity_highlighted(entity)
signal entity_unhighlighted(entity)
signal entity_selected(entity)
signal entity_unselected(entity)

#                                o p t i o n s                                #
# --------------------------------------------------------------------------- #
signal control_mode_changed(control_mode)


# =========================================================================== #
#                                M E T H O D S                                #
# --------------------------------------------------------------------------- #
func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	Log.info(self, "ready!")

# --------------------------------------------------------------------------- #

func _unhandled_input(e):
	if e.is_action_pressed("ui_menu"):
		emit_signal("menu_open")
	elif e.is_action_pressed("ui_menu_monsters"):
		emit_signal("menu_open", "monsters")
	elif e.is_action_pressed("ui_cancel"):
		emit_signal("ui_close")

# --------------------------------------------------------------------------- #

# we have to explicitly emit an argumentless signal if args is null (meaning we
# want no arguments), because:
# - exporting a variable (args) defaults it to null
# - passing null still counts as an argument to the callee
# - signals can only accept their predefined number of args
func emit_signal(sig, args = null, should_log = true):
	if should_log: Log.debug(self, ["emitting signal '", sig,
			"' | args: ", Utils.pack(args) if args != null else "(none)"])
	if args != null: .emit_signal(sig, args)
	else: .emit_signal(sig)

func emit(sig, args = null, should_log = true):
	emit_signal(sig, args, should_log)
