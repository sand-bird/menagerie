# script: perfect_scale

extends Node

# set screen size constraints here. IDEAL_SIZE determines the zoom level used
# in large resolutions, where multiple levels of zoom are valid.
const IDEAL_SIZE = Vector2i(460, 320)
# TOFIX: screen clipping in fullscreen when min sizes are inconsistent with the
# aspect ratio constraints
const MIN_SIZE = Vector2i(320, 208)
const MAX_SIZE = Vector2i(480, 360)

# superceded by the maximum and minimum size constraints
const MIN_ASPECT = 9.0/19.5
const MAX_ASPECT = 3.0/4.0

const MIN_SCALE = 1

# DEBOUNCE_TIME represents how long we wait for resize signals to stop coming
# before we do our thing, while the timer keeps track of this for us.
const DEBOUNCE_TIME = 0.5
#var timer: SceneTreeTimer = null

var current_scale

var viewport: Viewport
var vp_rid: RID
var window: Window

# store the window size to see if it actually changed
var win_size: Vector2i

func _ready():
	viewport = get_viewport()
	vp_rid = viewport.get_viewport_rid()
	window = get_window()
	window.set_content_scale_mode(0)
	RenderingServer.viewport_set_render_direct_to_screen(vp_rid, true)
	window.size_changed.connect(_on_window_resize)
	var base_size = update_screen()
#	Log.info(self, ["ready! window size: ", get_window().size,
#			", base size: ", base_size])

# --------------------------------------------------------------------------- #

var time_since_last_update = 0
var permit_updates = true

func _physics_process(delta):
	time_since_last_update += delta

func _on_window_resize():
	print('window size changed! old: ', win_size, ' new: ', window.size)
	print('_on_window_resize ', permit_updates, ' | ', time_since_last_update)
	if permit_updates: #and time_since_last_update >= DEBOUNCE_TIME:
		update_screen()
		time_since_last_update = 0
		permit_updates = true


# manually resizing the window sends a bunch of resize events, natch, but we
# only want to rescale once, so we wait until the signals stop coming. 
# note that SceneTreeTimer does not free itself right away, so we must manually
# clear our timer pointer inside update_screen().
#func debounce():
#	print('window size changed! old: ', win_size, ' new: ', window.size)
#	if !timer:
#		timer = get_tree().create_timer(DEBOUNCE_TIME)
#		timer.timeout.connect(update_screen)
#	else:
#		timer.time_left = DEBOUNCE_TIME

# --------------------------------------------------------------------------- #

# for pixel perfect, the window size must exactly equal the base_size times the
# scale (the scaled_size), or else there must be a gutter of a few pixels.
# here we resize the window if possible, or render with a gutter if not.
func update_screen():
	print('update_screen | permit_updates: ', permit_updates, ' | win_size: ', window.size, ', prev: ', win_size)
	var old_win_size = win_size
	win_size = window.size
	
	current_scale = get_scale(win_size)
	window.set_content_scale_factor(current_scale)
	
	var base_size = get_new_size(win_size, current_scale)
	window.set_content_scale_size(base_size)
	var scaled_size = base_size * current_scale
	
	# resizing the viewport also resizes the window (or at least attempts to),
	# which triggers the size_changed signal.  if the window cannot actually be
	# resized, we will just keep attempting it over and over in an endless loop.
#	window.size_changed.disconnect(debounce)
	
	if win_size == old_win_size:
		print('window does not seem to be resizable, adding gutter')
		permit_updates = false
		var gutter = ((win_size - scaled_size) / 2)
		print('gutter: ', gutter)
		RenderingServer.viewport_attach_to_screen(vp_rid, Rect2(gutter, scaled_size))
	
	viewport.set_size(scaled_size)
	
	Log.info(self, ["window size: ", win_size,
			" | scaled size: ", scaled_size,
			" | base size: ", base_size, " | viewport size: ",
			viewport.size, " | scale: ", current_scale])
	
	#window.size_changed.connect(debounce)
	return base_size

# --------------------------------------------------------------------------- #

# the scale is found using IDEAL_SIZE, then clamped to the minimum and maximum
# possible scale just in case. if the window's width exceeds the maximum aspect
# ratio, we must calculate the scale using its height.
func get_scale(win_size) -> int:
	var i = 'y' if win_size.y / win_size.x < MIN_ASPECT else 'x'
	return max(
		clamp(
			round(float(win_size[i]) / float(IDEAL_SIZE[i])),
			ceil(float(win_size[i]) / float(MAX_SIZE[i])),
			floor(float(win_size[i]) / float(MIN_SIZE[i]))
		),
		MIN_SCALE
	)

# --------------------------------------------------------------------------- #

# sets `base_size` according to the new window dimensions and our constraints.
# if the window is wider than the minimum aspect ratio, we must calculate
# base_size from the window's height; same with width if it's taller than the
# maximum. here we use width by default, and height when necessary.
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
	return Vector2i(round(new_x), round(new_y))

# --------------------------------------------------------------------------- #

func get_primary(i, win_size, scale):
	return max(win_size[i] / scale,
			MIN_SIZE[i])

func get_secondary(i, win_size, scale, low_val, high_val):
	return clamp(floor(win_size[i] / scale),
				max(low_val, MIN_SIZE[i]),
				min(high_val, MAX_SIZE[i]))
