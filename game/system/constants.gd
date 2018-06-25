# class Constants

extends Node

# ------- #
#  TYPES  #
# ------- #

enum DataType {
	
}

enum Type {
	MONSTER
	ITEM
	OBJECT
	NPC
	LOCATION
	EVENT
	RESOURCE
	TOY
	FOOD
	POTION
	SEED
	MUSHROOM
	FRUIT
	FLOWER
	TREE
	DECORATION
	FLOORING
}

var text_keys = {
	Type.MONSTER: "MONSTER",
	Type.ITEM: "ITEM",
	Type.OBJECT: "OBJECT",
	Type.NPC: "NPC", 
	Type.LOCATION: "LOCATION",
	Type.EVENT: "EVENT",
	Type.RESOURCE: "RESOURCE",
	Type.TOY: "TOY",
	Type.FOOD: "FOOD",
	Type.POTION: "POTION",
	Type.SEED: "SEED",
	Type.MUSHROOM: "MUSHROOM",
	Type.FRUIT: "FRUIT",
	Type.FLOWER: "FLOWER",
	Type.TREE: "TREE",
	Type.DECORATION: "DECORATION",
	Type.FLOORING: "FLOORING"
}

# ------- #
#  PATHS  #
# ------- #

const UI_ELEMENT_PATH = "res://assets/ui/elements"
const UI_PANEL_PATH = "res://assets/ui/panels"
const UI_ICON_PATH = "res://assets/ui/icons"

# --------- #
#  ACTIONS  #
# --------- #

enum ActionStatus { 
	SUCCESS
	FAILURE 
	RUNNING
	INTERRUPTED
	ERROR
}

# --------- #
#  OPTIONS  #
# --------- #

enum ControlMode {
	MOUSE_AND_KEY # edge, drag, button
	TOUCH # drag
	JOYPAD # joystick, edge
	KEYBOARD_ONLY # button, edge
}

enum ScrollMode {
	EDGE_SCROLL # mouse & key, joypad, key only
	DRAG_SCROLL # touch, mouse + key
	KEY_SCROLL # mouse + key, key only
	JOYSTICK_SCROLL # joypad
}

enum InventorySize {
	LARGE # 5x5 (meant for touch)
	SMALL # 6x6
}