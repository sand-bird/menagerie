extends Node

# as of godot 3.5, we're getting a bunch of unused signal warnings for signals
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
signal reset_game

#                                   t i m e                                   #
# --------------------------------------------------------------------------- #
signal tick_changed
signal hour_changed
signal date_changed
signal month_changed
signal year_changed

#                            u i :   g e n e r a l                            #
# --------------------------------------------------------------------------- #
signal ui_open(args) # item_ref, open_type, restore_on_close
signal ui_close
signal ui_toggle(item_ref)

#                          u i :   m a i n   m e n u                          #
# --------------------------------------------------------------------------- #

signal menu_open(args)
signal menu_set_title(title) # sets the title of the main menu
signal menu_set_pages(curent, total) # sets the number of pages of the main menu

signal menu_next_page(wrap)
signal menu_prev_page(wrap)

signal menu_next_section()
signal menu_prev_section()

# emitted by grid_items in the inventory page of the main menu
signal item_selected(item_info)

#                                 g a r d e n                                 #
# --------------------------------------------------------------------------- #
signal entity_highlighted(entity)
signal entity_unhighlighted(entity)
signal entity_selected(entity)
signal entity_unselected()

#                                o p t i o n s                                #
# --------------------------------------------------------------------------- #
signal control_mode_changed(control_mode)


# =========================================================================== #
#                                M E T H O D S                                #
# --------------------------------------------------------------------------- #
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.info(self, "ready!")

# --------------------------------------------------------------------------- #

# we have to explicitly emit an argumentless signal if args is null (meaning we
# want no arguments), because:
# - exporting a variable (args) defaults it to null
# - passing null still counts as an argument to the callee
# - signals can only accept their predefined number of args
func emit(sig, args = null, should_log = true):
	if should_log: Log.info(self, ["emitting signal '", sig,
			"' | args: ", U.pack(args) if args != null else "(none)"])
	if args != null: emit_signal(sig, args)
	else: emit_signal(sig)
