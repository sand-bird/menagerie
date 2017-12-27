# class Globals

extends Node

# ACTIONS 

enum ActionStatus { 
	SUCCESS,
	FAILURE, 
	RUNNING, 
	INTERRUPTED, 
	ERROR 
}

# OPTIONS

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