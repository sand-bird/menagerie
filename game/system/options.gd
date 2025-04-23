extends Node

#                                   g a m e                                   #
# --------------------------------------------------------------------------- #

# text speed
# autosave interval



#                              i n v e n t o r y                              #
# --------------------------------------------------------------------------- #

enum InventorySize {
	LARGE, # 5x5 (meant for touch)
	SMALL # 6x6
}
var inventory_size = InventorySize.LARGE

#                                  i n p u t                                  #
# --------------------------------------------------------------------------- #

# const: dict of bindable actions to labels (t.text keys)
# state: array of saved binding configs, one for each input source
# (keyboard, joystick)
# defaults saved in proj settings: InputMap.load_from_project_settings
# for action in state.keys():
#	InputMap.action_erase_events(action)
#	InputMap.action_add_event(action, state[action])


#                                 c a m e r a                                 #
# --------------------------------------------------------------------------- #

# options used for drag scroll
var drag_scroll_flick_distance = 8.0
var drag_scroll_flick_speed = 0.8

# options used for edge scroll
# ideally we can set these differently for mouse cursor vs joystick cursor
var edge_scroll_enabled = false
var edge_scroll_edge_size = 0.05 # percent of total screen width/height
var edge_scroll_speed = 0.30
var edge_scroll_acceleration = 1.05 # increases asymptotically toward 1.0


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
func _ready():
#	print(InputMap.get_signal_list())
#	print(InputMap.get_actions())
#	print(InputMap.get_action_list("ui_focus_next"))
	pass
	# deserialize(defaults)

func deserialize(data) -> void:
	Log.debug(self, ["deserializing", data])
	# we will be passed just the options dict from game (probably)
	# json parse it
	# set our values
	# also should be compatible with an internal defaults object somehow
	# remember that control mode should be autodetected, not just loaded

func serialize(): pass
	# make a dict of all our props
	# json serialize it
