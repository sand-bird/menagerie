# script: perfect_scale

extends Node

# set screen size constraints here.
# IDEAL_SIZE determines the zoom level used in large 
# resolutions, where multiple levels of zoom are valid
const IDEAL_SIZE = Vector2(460, 320)
# TOFIX: screen clipping in fullscreen when min sizes
# are inconsistent with the aspect ratio constraints
const MIN_SIZE = Vector2(320, 196)
const MAX_SIZE = Vector2(480, 360)

const MIN_ASPECT = 0.5 # 9.0/16.0
const MAX_ASPECT = 1 # 3.0/4.0

const MIN_SCALE = 2

var scale = 3
var base_size = Vector2()
var win_size = OS.get_window_size()

onready var viewport = get_tree().get_root()

func _ready():
	get_tree().connect("screen_resized", self, "update_screen")
	update_screen()
	Log.info(self, ["ready! window size: ", win_size, ", base size: ", base_size])

# for pixel perfect, the window size must exactly equal the 
# base_size times the scale (the scaled_size), or else there 
# must be a gutter of a few black pixels. here we resize the 
# window if possible, or render with a gutter if not.
func update_screen():
	win_size = OS.get_window_size()
	get_new_size()
	var scaled_size = base_size * scale
	Log.debug(self, ["resizing viewport: ", viewport.size, " -> ", base_size])
	viewport.set_size(base_size)
	if OS.is_window_maximized() or OS.is_window_fullscreen():
		var gutter = ((OS.get_window_size() - scaled_size) / 2).floor()
		viewport.set_attach_to_screen_rect(Rect2(gutter, scaled_size))
	else: OS.set_window_size(scaled_size)

# sets `base_size` according to the new window dimensions and 
# our constraints. also sets `scale` through get_scale().
func get_new_size():
	var new_x
	var new_y
	if win_size.y / win_size.x < MIN_ASPECT: # scale by height
		get_scale("y")
		new_y = get_primary("y")
		new_x = get_secondary("x", new_y / MAX_ASPECT, new_y / MIN_ASPECT)
	else: # scale by width (default)
		get_scale("x")
		new_x = get_primary("x")
		new_y = get_secondary("y", new_x * MIN_ASPECT, new_x * MAX_ASPECT)
	base_size = Vector2(round(new_x), round(new_y))

# the scale is found using IDEAL_SIZE, then clamped to
# the minimum and maximum possible scale just in case.
func get_scale(i):
	scale = max(clamp(round(win_size[i] / IDEAL_SIZE[i]), 
					  ceil(win_size[i] / MAX_SIZE[i]), 
					  floor(win_size[i] / MIN_SIZE[i])), 
				MIN_SCALE)

# get primary and secondary dimensions
# ------------------------------------
# if the window is wider than the minimum aspect ratio, 
# we must calculate base_size from the window's height; 
# same with width if it's taller than the maximum. here 
# we use width by default, and height when necessary.

func get_primary(i):
	return max(win_size[i] / scale, 
			   MIN_SIZE[i])

func get_secondary(i, low_val, high_val):
	return clamp(floor(win_size[i] / scale),
				 max(low_val, MIN_SIZE[i]),
				 min(high_val, MAX_SIZE[i]))
