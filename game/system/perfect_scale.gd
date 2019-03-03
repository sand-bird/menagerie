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
const MAX_ASPECT = 0.75 # 3.0/4.0

const MIN_SCALE = 2

# DEBOUNCE_TIME represents how long we wait for resize
# signals to stop coming before we do our thing, while the
# timer keeps track of this for us.
const DEBOUNCE_TIME = 0.05
var timer: SceneTreeTimer = null

func _ready():
	print(get_tree().connect("screen_resized", self, "debounce"))
	var base_size = update_screen()
	Log.info(self, ["ready! window size: ", OS.window_size,
			", base size: ", base_size])

# -----------------------------------------------------------

# manually resizing the window sends a bunch of resize
# events, natch, but we only want to rescale once, so we wait
# until the signals stop coming. note that SceneTreeTimer
# does not free itself right away, so we must manually clear
# our timer pointer inside `update_screen`.
func debounce():
	if !timer:
		timer = get_tree().create_timer(DEBOUNCE_TIME)
		timer.connect("timeout", self, "update_screen")
	else:
		timer.time_left = DEBOUNCE_TIME

# -----------------------------------------------------------

# for pixel perfect, the window size must exactly equal the
# base_size times the scale (the scaled_size), or else there
# must be a gutter of a few black pixels. here we resize the
# window if possible, or render with a gutter if not.
func update_screen():
	timer = null

	var viewport = get_tree().get_root()

	var new_win_size = OS.window_size
	var new_scale = get_scale(new_win_size)
	var base_size = get_new_size(new_win_size, new_scale)
	var scaled_size = base_size * new_scale

	if OS.is_window_maximized() or OS.is_window_fullscreen():
		var gutter = ((OS.window_size - scaled_size) / 2).floor()
		viewport.set_attach_to_screen_rect(Rect2(gutter, scaled_size))
	else:
		OS.window_size = scaled_size

	viewport.set_size(base_size)

	Log.debug(self, ["base size: ", base_size, " | scaled size: ",
			scaled_size, " | window size: ", OS.window_size])
	print("base: ", base_size, " | scaled: ", scaled_size,
			" | viewport: ", viewport.size, " | window: ", OS.window_size)

	return base_size

# -----------------------------------------------------------

# sets `base_size` according to the new window dimensions and
# our constraints. also sets `scale` through get_scale().
func get_new_size(win_size, scale):
	var new_x
	var new_y
	if win_size.y / win_size.x < MIN_ASPECT: # scale by height
		new_y = get_primary("y", win_size, scale)
		new_x = get_secondary("x", win_size, scale,
				new_y / MAX_ASPECT, new_y / MIN_ASPECT)
	else: # scale by width (default)
		new_x = get_primary("x", win_size, scale)
		new_y = get_secondary("y", win_size, scale,
				new_x * MIN_ASPECT, new_x * MAX_ASPECT)
	return Vector2(round(new_x), round(new_y))

# -----------------------------------------------------------

# the scale is found using IDEAL_SIZE, then clamped to
# the minimum and maximum possible scale just in case.
func get_scale(win_size):
	var i = 'y' if win_size.y / win_size.x < MIN_ASPECT else 'x'
	return max(
		clamp(
			round(win_size[i] / IDEAL_SIZE[i]),
			ceil(win_size[i] / MAX_SIZE[i]),
			floor(win_size[i] / MIN_SIZE[i])
		),
		MIN_SCALE
	)

# -----------------------------------------------------------

# getting primary and secondary dimensions
# -----------------------------------------
# if the window is wider than the minimum aspect ratio, we
# must calculate base_size from the window's height; same
# with width if it's taller than the maximum. here we use
# width by default, and height when necessary.

func get_primary(i, win_size, scale):
	return max(win_size[i] / scale,
			   MIN_SIZE[i])

func get_secondary(i, win_size, scale, low_val, high_val):
	return clamp(floor(win_size[i] / scale),
				 max(low_val, MIN_SIZE[i]),
				 min(high_val, MAX_SIZE[i]))
