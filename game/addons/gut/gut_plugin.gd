tool
extends EditorPlugin

# A class member to hold the dock during the plugin lifecycle
var gut_control

func _enter_tree():
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
#	add_custom_type("Gut", "WindowDialog", preload("gut.gd"), preload("icon.png"))

	# Initialization of the plugin goes here
	# Load the dock scene and instance it
	gut_control = preload("res://addons/gut/gut_control.tscn").instance()

	add_control_to_bottom_panel(gut_control, "Gut")
	# Note that LEFT_UL means the left of the editor, upper-left dock

func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove it from the engine when deactivated
#	remove_custom_type("Gut")

	# Clean-up of the plugin goes here
	# Remove the dock
	remove_control_from_bottom_panel(gut_control)
	 # Erase the control from the memory
	gut_control.free()
