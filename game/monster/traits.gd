extends Node

class Trait:
	signal value_changed
	
	# defaults for trait properties
	var name = ""
	var max_value = 100
	var min_value = 0
	var title_high = ""
	var high_threshold = 80
	var title_low = ""
	var low_threshold = 20
	
	var orig_value = 0 setget _set_orig
	var value = 0 setget _set_value
	
	func get_portion ():
		return round(value / max_value)
	
	func get_increase ():
		return value - orig_value
	
	func init_value ():
		pass
	
	func load_value (data):
		value = data.value
		orig_value = data.orig_value
	
	func _set_value (val):
		value = val
		emit_signal("value_changed", name, val)
		print(name, ", ", val)
	
	func _set_orig (val): 
		print("Error: can't change original value! (", orig_value, ")")
		pass
	
	func serialize():
		return {
			orig_value = orig_value,
			value = value
		}



# +-----+--------------+
# | INT | intelligence |
# +-----+--------------+


class Iq extends Trait:
	func _init():
		name = "iq"
		max_value = 200
		min_value = 0
		title_high = "perspicacious"
		high_threshold = 150
		title_low = "dim-witted"
		low_threshold = 50
	
	func init_value():
		pass


class Learning extends Trait:
	func _init():
		name = "learning"
		max_value = 100
		min_value = 0
		title_high = "worldly"
		high_threshold = 80
		title_low = "callow"
		low_threshold = 20
	
	func init_value():
		value = 0
		orig_value = 0



# +-----+--------------+
# | VIT |   vitality   |
# +-----+--------------+


class Size extends Trait:
	func _init():
		name = "size"
		max_value = 100
		min_value = 0
		title_high = "massive"
		high_threshold = 80
		title_low = "shrimpy"
		low_threshold = 20


class Strength extends Trait:
	func _init():
		name = "strength"
		max_value = 100
		min_value = 0
		title_high = "brawny"
		high_threshold = 80
		title_low = "wimpy"
		low_threshold = 20


class Health extends Trait:
	func _init():
		name = "health"
		max_value = 100
		min_value = 0
		title_high = "hearty"
		high_threshold = 80
		title_low = "frail"
		low_threshold = 20



# +-----+--------------+
# | CON | constitution |
# +-----+--------------+


class Composure extends Trait:
	func _init():
		name = "composure"
		max_value = 100
		min_value = 0
		title_high = "composed"
		high_threshold = 80
		title_low = "neurotic"
		low_threshold = 20


class Willpower extends Trait:
	func _init():
		name = "willpower"
		max_value = 100
		min_value = 0
		title_high = "determined"
		high_threshold = 80
		title_low = "lazy"
		low_threshold = 20


class Patience extends Trait:
	func _init():
		name = "patience"
		max_value = 100
		min_value = 0
		title_high = "stoic"
		high_threshold = 80
		title_low = "antsy"
		low_threshold = 20



# +-----+--------------+
# | CHA |    charm     |
# +-----+--------------+


class Confidence extends Trait:
	func _init():
		name = "confidence"
		max_value = 100
		min_value = 0
		title_high = "gregarious"
		high_threshold = 80
		title_low = "timid"
		low_threshold = 20


class Beauty extends Trait:
	func _init():
		name = "beauty"
		max_value = 100
		min_value = 0
		title_high = "lustrous"
		high_threshold = 80
		title_low = "unsightly"
		low_threshold = 20


class Poise extends Trait:
	func _init():
		name = "poise"
		max_value = 100
		min_value = 0
		title_high = "poised"
		high_threshold = 80
		title_low = "histrionic"
		low_threshold = 20



# +-----+--------------+
# | AMI |  amiability  |
# +-----+--------------+


class Independence extends Trait:
	func _init():
		name = "independence"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20


class Arrogance extends Trait:
	func _init():
		name = "arrogance"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20


class Aggressiveness extends Trait:
	func _init():
		name = "aggressiveness"
		max_value = 100
		min_value = 0
		title_high = "bellicose"
		high_threshold = 80
		title_low = "zen"
		low_threshold = 20


class Empathy extends Trait:
	func _init():
		name = "empathy"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20


class Kindness extends Trait:
	func _init():
		name = "kindness"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20



# +-----+--------------+
# | SPR |    spirit    |
# +-----+--------------+


class Happiness extends Trait:
	func _init():
		name = "happiness"
		max_value = 0
		high_threshold = 0
		low_threshold = 0
	
	func get_portion():
		# this needs to be special since we don't really have a max happiness
		pass
	
	func init_value():
		value = 0
		orig_value = 0


class Actualization extends Trait:
	func _init():
		name = "actualization"
		max_value = 0
		high_threshold = 0
		low_threshold = 0
	
	func init_value():
		value = 0
		orig_value = 0


class Loyalty extends Trait:
	func _init():
		name = "loyalty"
		max_value = 10
		high_threshold = 0
		low_threshold = 0
	
	func init_value():
		value = 0
		orig_value = 0



# +-----+--------------+
# | N/A | no attribute |
# +-----+--------------+


class Appetite extends Trait:
	func _init():
		name = "appetite"
		max_value = 100
		title_high = "gluttonous"
		high_threshold = 80
		title_low = "ascetic"
		low_threshold = 20


class Openness extends Trait:
	func _init():
		name = "openness"
		max_value = 100
		title_high = "adventurous"
		high_threshold = 80
		title_low = "closed-minded"
		low_threshold = 20


class Sociability extends Trait:
	func _init():
		name = "sociability"
		max_value = 100
		title_high = "outgoing"
		high_threshold = 80
		title_low = "reclusive"
		low_threshold = 20

