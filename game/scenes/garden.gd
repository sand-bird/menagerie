extends TextureFrame

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var m = get_node("monster")
	
	var j = m.serialize().to_json()
	var data = {}
	data.parse_json(j)
	
	print(data)
	m.deserialize(data)
	
	# m.serialize()
	#var test = utils.weighted_average([[100, 1], [1, 3]])
	#print("test weighted average: ", test)
	#print("iq: ", m.iq.value, " | size: ", m.size)
	pass