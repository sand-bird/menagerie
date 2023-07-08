@tool
extends HBoxContainer

@export var full_texture: Texture2D
@export var half_texture: Texture2D
@export var empty_texture: Texture2D

@export var value: float: set = _update_value
@export var max_value: int:
	set(x):
		max_value = x
		_update_value(value)

func _update_value(x: float):
#	print('_update_value ', x, ' max: ', max_value)
	value = clamp(x, 0, max_value)
	render_textures()

func add_point(texture: Texture2D):
	var point = TextureRect.new()
	point.texture = texture
	add_child(point)

func render_textures():
	for child in get_children(true): child.queue_free()
	
	var has_half_point = half_texture != null
	var full_points: int = floor(value) if has_half_point else round(value)
	var use_half_point = has_half_point and (value - full_points) > 0.5
	var filled_points = full_points + (1 if use_half_point else 0)
	var empty_points: int = (
		0 if empty_texture == null else
		max_value - filled_points
	)
	
	prints('full', full_points, 'half', use_half_point, 'empty', empty_points)
	
	for i in full_points: add_point(full_texture)
	if use_half_point: add_point(half_texture)
	for i in empty_points: add_point(empty_texture)


func _ready():
	render_textures()
	pass # Replace with function body.

func _process(delta):
	pass
