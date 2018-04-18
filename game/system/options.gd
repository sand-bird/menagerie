extends Node

var ControlMode = Constants.ControlMode
var ScrollMode = Constants.ScrollMode

# -----------------------------------------------------------
#                  I N P U T   O P T I O N S
# -----------------------------------------------------------

var control_mode = ControlMode.MOUSE_AND_KEY

var keybindings = {
	camera_up = KEY_W,
	camera_left = KEY_A,
	camera_down = KEY_S,
	camera_right = KEY_D 
}

# -----------------------------------------------------------
#                 C A M E R A   O P T I O N S
# -----------------------------------------------------------

# these are both the defaults (for now) and all the possible scroll mode options
# for each control mode; remember to keep track of both these things elsewhere
var scroll_modes = {
	ControlMode.MOUSE_AND_KEY: [
		ScrollMode.EDGE_SCROLL, 
		ScrollMode.DRAG_SCROLL, 
		ScrollMode.KEY_SCROLL
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
var camera_flick_distance = 6.0
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

func _ready(): 
#	print(InputMap.get_signal_list())
#	print(InputMap.get_actions())
#	print(InputMap.get_action_list("ui_focus_next"))
	pass
	# deserialize(defaults)

func deserialize(data): 
	pass
	# we will be passed just the options dict from game (probably)
	# json parse it
	# set our values
	# also should be compatible with an internal defaults object somehow
	# remember that control mode should be autodetected, not just loaded

func serialize(): pass
	# make a dict of all our props
	# json serialize it

# presumably called by game.gd when it detects a change in input - or by
# the settings ui when we change it manually
func set_control_mode(mode):
	control_mode = mode