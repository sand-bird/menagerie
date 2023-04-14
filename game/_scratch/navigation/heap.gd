extends Node

# not actually a heap (yet); pushes in O(1) and pops in O(n),
# as opposed to O(log n) for both in a real heap. todo later

var list = []

func push(node):
	list.push_back(node)

func pop():
	var min_f = INF
	var min_i = -1
	for i in list.size():
		if list[i].f < min_f:
			min_f = list[i].f
			min_i = i
	var node = list[min_i]
	list.remove(min_i)
	return node

func is_empty():
	return list.is_empty()
