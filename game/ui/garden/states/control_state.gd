class_name ControlState
extends RefCounted

func _init():
	Dispatcher.entity_highlighted.connect(_highlighted)
	Dispatcher.entity_selected.connect(_selected)

func _highlighted(e: Entity):
	prints('entity highlighted', e)

func _selected(e: Entity):
	prints('entity selected', e)
