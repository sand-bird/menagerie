extends Node

class Trait:
	signal value_changed
	
	var name
	var orig_value setget _invalid
	var max_value
	var value setget set_value
	
	func set_value(val):
		value = val
		emit_signal("value_changed", name, val)
		print(name, ", ", val)
	
	func _invalid(val): 
		print("Error: can't change original value! (", orig_value, ")")
		pass
	
	func serialize():
		return {
			orig_value = orig_value,
			value = value
		}

class Size extends Trait:
	func _ready():
		max_value = 100
		name = "size"
		
	func _init(val):
		orig_value = val
		value = val

class Iq extends Trait:
	func _ready():
		max_value = 150
		name = "iq"

	func _init(val):
		orig_value = val
		value = val

