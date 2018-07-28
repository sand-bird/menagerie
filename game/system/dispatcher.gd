extends Node

# ------ #
#  GAME  #
# ------ #

signal new_game
signal load_game
signal save_game
signal quit_game


# ------ #
#  TIME  #
# ------ #

signal tick_changed
signal hour_changed(hour)
signal date_changed(date)
signal month_changed(month)
signal year_changed(year)


# ---- #
#  UI  #
# ---- #

signal ui_open(args)
signal ui_close

signal menu_open(args)

# emitted by grid_items in the inventory page of the main menu
signal item_selected(item_info)


# --------- #
#  OPTIONS  #
# --------- #

signal control_mode_changed(control_mode)

# -----------------------------------------------------------

func _ready():
	Log.info(self, "ready!")

func _unhandled_input(e):
	if e.is_action_pressed("ui_menu"): 
		emit_signal("menu_open")
	elif e.is_action_pressed("ui_menu_monsters"): 
		emit_signal("menu_open", "monsters")

# we have to explicitly emit an argumentless signal if args
# is null (meaning we want no arguments), because:
# - exporting a variable (args) defaults it to null
# - passing null still counts as an argument to the callee
# - signals can only accept their predefined number of args
func emit_signal(sig, args = null, log_it = true):
	if log_it: Log.debug(self, ["emitting signal: `", sig, 
			"`, args: ", Utils.pack(args) if args != null else "(none)"])
	if args != null: .emit_signal(sig, args)
	else: .emit_signal(sig)