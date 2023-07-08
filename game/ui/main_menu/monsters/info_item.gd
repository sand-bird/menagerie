@tool
extends Control

@export var title: String: set = _set_title
@export_multiline var value: String: set = _set_value

func _ready():
	_set_title()
	_set_value()

func _set_title(x = null):
	if x != null: title = x
	if $title != null: $title.text = str(" ", title.to_upper())

func _set_value(x = null):
	if x != null: value = x
	if $value != null: $value.text = value
