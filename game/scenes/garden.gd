extends TextureFrame

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var m = get_node("monster")
	
	# print(m.serialize().to_json())
	# m.serialize()
	var test = utils.weighted_average([[100, 1], [1, 3]])
	print("test weighted average: ", test)
	print("iq: ", m.iq, " | size: ", m.size)
	pass