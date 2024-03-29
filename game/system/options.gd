extends Node

# disable erroneous "unused class variable" warnings, as of godot 3.1. maybe
# something about the enum imports?
#warning-ignore-all:unused_class_variable

# =========================================================================== #
#                              C O N S T A N T S                              #
# --------------------------------------------------------------------------- #
enum ControlMode {
	MOUSE_AND_KEY, # edge, drag, button
	TOUCH, # drag
	JOYPAD, # joystick, edge
	KEYBOARD_ONLY # button, edge
}
enum ScrollMode {
	EDGE_SCROLL, # mouse & key, joypad, key only
	DRAG_SCROLL, # touch, mouse + key
	KEY_SCROLL, # mouse + key, key only
	JOYSTICK_SCROLL, # joypad
}
enum InventorySize {
	LARGE, # 5x5 (meant for touch)
	SMALL # 6x6
}

# =========================================================================== #
#                                O P T I O N S                                #
# --------------------------------------------------------------------------- #

#                                   g a m e                                   #
# --------------------------------------------------------------------------- #

const TextSpeed = {
	1: 16.0,
	2: 24.0,
	3: 32.0,
	4: 40.0,
	5: 48.0
}

var autosave_interval = "hour"
var text_speed = TextSpeed[3] # characters per second

#                              i n v e n t o r y                              #
# --------------------------------------------------------------------------- #

var inventory_size = InventorySize.LARGE

#                                  i n p u t                                  #
# --------------------------------------------------------------------------- #

var control_mode = ControlMode.MOUSE_AND_KEY

var keybindings = {
	camera_up = KEY_W,
	camera_left = KEY_A,
	camera_down = KEY_S,
	camera_right = KEY_D
}

# presumably called by game.gd when it detects a change in input - or by the
# settings ui when we change it manually
func set_control_mode(mode):
	control_mode = mode

#                                 c a m e r a                                 #
# --------------------------------------------------------------------------- #

# these are both the defaults (for now) and all the possible scroll mode
# options for each control mode; remember to keep track of both these things
# elsewhere
var scroll_modes = {
	ControlMode.MOUSE_AND_KEY: [
#		ScrollMode.EDGE_SCROLL,
		ScrollMode.DRAG_SCROLL
#		ScrollMode.KEY_SCROLL
	],
	ControlMode.TOUCH: [
		ScrollMode.DRAG_SCROLL
	],
	ControlMode.JOYPAD: [
		ScrollMode.JOYSTICK_SCROLL,
		ScrollMode.EDGE_SCROLL
	],
	ControlMode.KEYBOARD_ONLY: [
		ScrollMode.KEY_SCROLL,
		ScrollMode.EDGE_SCROLL
	]
}

# options used for drag scroll
var camera_flick_distance = 8.0
var camera_flick_speed = 0.8

# options used for edge scroll
var camera_edge_size = 0.05 # percent of total screen width/height
var camera_scroll_speed = 0.30
var camera_scroll_acceleration = 1.05 # increases asymptotically toward 1.0

func is_scroll_enabled(mode):
	return scroll_modes[control_mode].has(mode)

func set_scroll_enabled(mode):
	if !is_scroll_enabled(mode):
		scroll_modes[control_mode].append(mode)

func set_scroll_disabled(mode):
	if is_scroll_enabled(mode):
		scroll_modes[control_mode].erase(mode)


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
