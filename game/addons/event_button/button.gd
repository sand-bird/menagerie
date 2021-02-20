tool
extends BaseButton
# SignalButton
# ------------
# calls on an emitter node to emit a signal when the button is pressed.
# the emitter node, signal name, and arguments (packed into an array) can be
# set in the inspector panel.

export(String) var emitter = "Dispatcher"
export(String) var signal_name

# this will have to be an object, defined manually for each button that needs
# it (since we can't define vararg functions)
export(Array) var args

onready var emitter_node = get_node("/root/" + emitter)
onready var use_signal_name = signal_name if (signal_name != null) else self.name

# we have to explicitly emit an argumentless signal if args is null (meaning we
# want no arguments), because:
# - exporting a variable (args) defaults it to null
# - passing null still counts as an argument to the callee
# - signals can only accept their predefined number of args
func _pressed():
	print(emitter_node.name, ": ", use_signal_name, " (", args, ")")
	emitter_node.emit(use_signal_name, args)
