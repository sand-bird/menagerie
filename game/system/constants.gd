# class Constants

extends Node

enum Speed {
	AMBLE = 30
	STROLL = 40
	WALK = 50
	TROT = 65
	JOG = 80
	RUN = 100
	DASH = 130
	SPRINT = 180
}

# ------- #
#  TYPES  #
# ------- #

enum Status {
	HEALTHY
	SICK
}

enum DataType {
	
}

enum EntityType {
	MONSTER
	ITEM
	OBJECT
	NPC
	LOCATION
	EVENT
}

enum Category {
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

# ------- #
#  PATHS  #
# ------- #

const UI_ELEMENT_PATH = "res://assets/ui/elements"
const UI_PANEL_PATH = "res://assets/ui/panels"
const UI_ICON_PATH = "res://assets/ui/icons"
const UI_MENU_PATH = "res://ui/main_menu"

const EVENT_BUTTON_PATH = "res://ui/event_button.gd"

const MONSTER_PATH = "res://monster/monster.tscn"
const ITEM_PATH = "res://item/item.tscn"

const ROOT_PATH = "/root/game"

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

# ------- #
#  PATHS  #
# ------- #

const Anim = {
	IDLE = "idle",
	LIE_DOWN = "lie_down",
	WALK = "walk",
	SLEEP = "sleep"
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

enum Language {
	ENGLISH
	PORTUGUESE
}

enum Wrap {
	NONE
	HORIZONTAL
	VERTICAL
}


# CONFIG

const INVENTORY_PROPERTIES = {
	InventorySize.SMALL: {
		columns = 6,
		grid_bg = "item_grid_small",
		selector = "selector_small",
		selector_size = Vector2(0, 0),
		grid_offset = Vector2(0, 0),
		item_size = Vector2(20, 20)
	},
	InventorySize.LARGE: {
		columns = 5,
		grid_bg = "item_grid_large",
		selector = "selector_big",
		selector_size = Vector2(0, 0),
		grid_offset = Vector2(2, 2),
		item_size = Vector2(24, 24)
	}
}

# we call them chapters, because pages are already a thing
const MENU_CHAPTERS = {
	monsters = {
		icon = "monster",
		scene = "monsters/monsters",
		condition = "$garden.monsters"
	},
	items = {
		icon = "items",
		scene = "inventory/items",
		condition = {"filter": [
			"$player.inventory:id",
			{"==": [
				"$data.*.type",
				"item"
			]}
		]}
	},
	objects = {
		icon = "inventory",
		scene = "inventory/objects",
		condition = {"filter": [
			"$player.inventory",
			{"==": [
				{"get": [
					{"get": ["$data", "*.id"]},
					"type"
				]},
				"object"
			]}
		]}
	},
	town_map = {
		icon = "town",
		scene = "town_map/town_map"
	},
	calendar = {
		icon = "calendar",
		scene = "calendar/calendar"
	},
	encyclopedia = {
		icon = "encyclopedia",
		scene = "encyclopedia/encyclopedia"
	},
	options = {
		icon = "options",
		scene = "options/options"
	}
}