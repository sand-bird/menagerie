extends Node

# -------------- #
#  GAME SIGNALS  #
# -------------- #

signal new_game
signal load_game
signal save_game
signal quit_game

# ------------ #
#  UI SIGNALS  #
# ------------ #

signal ui_open(args)
signal ui_close

signal menu_open(args)

# emitted by grid_items in the inventory page of the main menu
signal item_selected(item_info)

# ----------------- #
#  OPTIONS SIGNALS  #
# ----------------- #

signal control_mode_changed(control_mode)

# -----------------------------------------------------------

func _ready():
	Log.info(self, "ready!")

func _unhandled_input(e):
	if e.is_action("ui_menu"): emit_signal("menu_open")
	elif e.is_action("ui_menu_monsters"): emit_signal("menu_open", "monsters")

# we have to explicitly emit an argumentless signal if args
# is null (meaning we want no arguments), because:
# - exporting a variable (args) defaults it to null
# - passing null still counts as an argument to the callee
# - signals can only accept their predefined number of args
func emit_signal(sig, args = null):
	Log.debug(self, ["emitting signal: ", sig, 
			", args: ", Utils.pack(args) if args else "(none)"])
	if args: .emit_signal(sig, args)
	else: .emit_signal(sig)