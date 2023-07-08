@tool
extends Control

@export var title: String: set = _set_title
@export_multiline var value: String: set = _set_value

func _ready():
	child_entered_tree.connect(_on_add_child)
#	_set_title()
#	_set_value()

func _set_title(x = null):
	if x != null: title = x
	$title.text = str(" ", title.to_upper())

func _set_value(x = null):
	if x != null: value = x
	$container/label.text = value

func _on_add_child(node: Node):
	print('child entered tree:', node)
	node.reparent($container)
	node.owner = $container
