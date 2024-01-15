extends PagedList

func initialize():
	data = ["foo","bar","baz"]

func load_items(data_slice: Array[Variant]) -> Array[Control]:
	var result = [] as Array[Control]
	for data in data_slice:
		var l = Button.new()
		l.text = str(data)
		result.push_back(l)
	return result
