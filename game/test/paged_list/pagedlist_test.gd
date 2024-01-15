extends Control
"""
a demo for what happens when we have multiple PagedLists at once.
in short, they both try to handle input at the same time, but the "top" one
(lower in the scene tree) receives the input first.
"""

func _ready():
	for i in [1, 2]:
		var list = get_node(str(i))
		list.selected_changed.connect(update_selected.bind(i))
		update_selected(list.selected, null, i)

func update_selected(selected, _data, i):
	get_node(str(i, '_selected')).text = str(selected)
