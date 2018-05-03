# class Constants

extends Node

# ------- #
#  PATHS  #
# ------- #

const UI_ELEMENT_PATH = "res://assets/ui/elements"
const UI_PANEL_PATH = "res://assets/ui/panels"
const UI_ICON_PATH = "res://assets/ui/icons"


enum EntityType {
	MONSTER = 0
	ITEM = 1
	OBJECT = 2
	NPC = 3
	LOCATION = 4
	GARDEN = 5
}

enum EntitySubtype {
	RESOURCE
	POTION
	FLOWER
	SEED
	TREE
}

# --------- #
#  ACTIONS  #
# --------- #

enum ActionStatus { 
	SUCCESS,
	FAILURE, 
	RUNNING, 
	INTERRUPTED, 
	ERROR 
}

# --------- #
#  OPTIONS  #
# --------- #

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
	JOYSTICK_SCROLL # joypad
}

enum InventorySize {
	LARGE, # 5x5 (meant for touch)
	SMALL # 6x6
}