class_name Constants

enum Speed {
	AMBLE = 30,
	STROLL = 40,
	WALK = 50,
	TROT = 65,
	JOG = 80,
	RUN = 100,
	DASH = 130,
	SPRINT = 180,
}

# ------- #
#  TYPES  #
# ------- #

enum Status {
	HEALTHY, SICK
}

enum DataType {}

enum EntityType {
	MONSTER, ITEM, OBJECT, NPC, LOCATION, EVENT
}

enum Category {
	RESOURCE, TOY, FOOD, POTION, SEED, MUSHROOM,
	FRUIT, FLOWER, TREE, DECORATION, FLOORING
}

enum Direction {
	TOP, BOTTOM, LEFT, RIGHT
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
	NEW,
	RUNNING,
	PAUSED,
	SUCCESS,
	FAILURE,
	INTERRUPTED,
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
enum GridSize { SMALL, LARGE }

