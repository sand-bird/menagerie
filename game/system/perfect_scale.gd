# script: perfect_scale
extends Node

const IDEAL_WIDTH = 400
const MIN_WIDTH = 320
const MAX_WIDTH = 480

const IDEAL_HEIGHT = 280
const MIN_HEIGHT = 240
const MAX_HEIGHT = 360

const MIN_ASPECT = 9.0/16.0
const MAX_ASPECT = 3.0/4.0

const MIN_SCALE = 3

var scale = 2
var base_size = Vector2()

onready var viewport = get_tree().get_root()
onready var game = viewport.get_child(viewport.get_child_count() - 1)

func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")
#	game.set_area_as_parent_rect(0)
	update_screen()

func _on_screen_resized():
	update_screen()
	print(scale)

func update_screen():
	get_new_size(OS.get_window_size())
	var scaled_size = base_size * scale
	viewport.set_rect(Rect2(Vector2(0, 0), base_size))
	if OS.is_window_maximized() or OS.is_window_fullscreen():
		var gutter = utils.vfloor((OS.get_window_size() - scaled_size) / 2)
		viewport.set_render_target_to_screen_rect(Rect2(gutter, base_size * scale))
	else: OS.set_window_size(scaled_size)


func get_new_size(window_size):
	if window_size.y / window_size.x < MIN_ASPECT: # scale by height
		scale = max(clamp(floor(window_size.y / IDEAL_HEIGHT), 
				ceil(window_size.y / MAX_HEIGHT), 
				floor(window_size.y / MIN_HEIGHT)), MIN_SCALE)
		var new_y = max(window_size.y / scale, MIN_HEIGHT)
		var min_width = max(new_y / MAX_ASPECT, MIN_WIDTH)
		var max_width = min(new_y / MIN_ASPECT, MAX_WIDTH)
		base_size = utils.vfloor(Vector2(clamp(window_size.x / scale, 
				min_width, max_width), new_y))
	else: # scale by width (default)
		scale = max(clamp(floor(window_size.x / IDEAL_WIDTH), 
				ceil(window_size.x / MAX_WIDTH),
				floor(window_size.x / MIN_WIDTH)), MIN_SCALE)
		var new_x = max(window_size.x / scale, MIN_WIDTH)
		var min_height = max(new_x * MIN_ASPECT, MIN_HEIGHT)
		var max_height = min(new_x * MAX_ASPECT, MAX_HEIGHT)
		base_size = utils.vfloor(Vector2(new_x, clamp(window_size.y / scale, 
				min_height, max_height)))