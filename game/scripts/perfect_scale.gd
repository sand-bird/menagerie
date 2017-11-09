# script: perfect_scale
extends Node

const MIN_WIDTH = 320
const MAX_WIDTH = 480
const IDEAL_WIDTH = 384

var scale = Vector2(2, 2)
var size = Vector2(1152, 648)

onready var viewport = get_tree().get_root()
onready var game = viewport.get_child(viewport.get_child_count() - 1)

func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	game.set_area_as_parent_rect(0)

func _on_screen_resized():
	var old_size = size
	var old_scale = scale
	get_new_size(OS.get_window_size())	
	OS.set_window_size(size)
	viewport.set_rect(Rect2(0, 0, size.x / scale.x, size.y / scale.y));
	
func get_new_size(window_size):
	var new_scale = round(window_size.x / IDEAL_WIDTH)
	var new_x = clamp(round(window_size.x / new_scale), MIN_WIDTH, MAX_WIDTH)
	var new_y = clamp(round(window_size.y / new_scale), round(new_x * 9/16), round(new_x * 3/4))
	size = Vector2(new_x * new_scale, new_y * new_scale)
	scale = Vector2(new_scale, new_scale)
	