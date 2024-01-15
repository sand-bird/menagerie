extends PagedList

func initialize():
	data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

func load_items(data_slice: Array[Variant]) -> Array[Control]:
	var result = [] as Array[Control]
	for data in data_slice:
		var l = Button.new()
		l.text = str(data)
		result.push_back(l)
	return result
