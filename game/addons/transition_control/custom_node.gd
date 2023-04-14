@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("TransitionControl", "Control", 
			preload("transition_control.gd"), preload("control.png"))

func _exit_tree():
    remove_custom_type("TransitionControl")