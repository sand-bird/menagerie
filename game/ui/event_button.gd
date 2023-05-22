extends Button
# SignalButton
# ------------
# calls on an emitter node to emit a signal when the button is pressed.
# the emitter node, signal name, and arguments (packed into an array) can be
# set in the inspector panel.

var signal_name

# this will have to be an object, defined manually for each button that needs
# it (since we can't define vararg functions)
var args

# we have to explicitly emit an argumentless signal if args is null (meaning we
# want no arguments), because:
# - exporting a variable (args) defaults it to null
# - passing null still counts as an argument to the callee
# - signals can only accept their predefined number of args
func _pressed():
	var use_signal_name = signal_name if signal_name else self.name
	Log.debug(self, ["dispatching signal: ", use_signal_name,
			", args: ", args if args else "(none)"])
	Dispatcher.emit(use_signal_name, args)
