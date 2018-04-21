tool
extends BaseButton

export(String) var event_emitter = "EventManager"
export(String) var signal_name

# this will have to be an object, defined manually for each 
# button that needs it (since we can't define vararg functions)
var args

onready var event_emitter_node = get_node("/root/" + event_emitter)
onready var use_signal_name = signal_name if (signal_name != null) else self.name 

func _pressed():
	print("pressed: ", use_signal_name, " | arg: ", args)
	if args: event_emitter_node.emit_signal(use_signal_name, args)
	else: event_emitter_node.emit_signal(use_signal_name)