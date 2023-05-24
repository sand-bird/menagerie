extends Node
"""
Forces the viewport to render at a multiple of a valid pixel resolution, so that
all displayed pixels appear perfectly square.  If the window is resizable, this
will resize it to the nearest valid resolution; if not, it will add gutters to
the edges of the viewport.
"""

# switch: 1280 × 720
# ds: 256 × 192 (both screens)
# gba: 240 × 160
# 3ds: 400 × 240 (top), 320 × 240 (bottom)

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
const DEBOUNCE_TIME = 0.1
var timer: SceneTreeTimer

# exposed for configuration i guess? sometimes multiple scales are valid at a
# given resolution (if the resolution is high enough)
var current_scale

var window: Window # the parent viewport
var rid: RID # rid of the parent viewport
var window_id: int # id used by DisplayServer to identify the OS window

# stored at the _beginning_ of update_screen so that it captures the window
# size as it was before we attempted to mess with it.
# if the OS does not actually permit the window to be resized (eg, in i3wm if
# the window is docked), `window.set_size` will result in 2 rapid size changes,
# from the actual size to the set size, and then back.  each of these fires a
# `size_changed` signal and triggers a call to `debounce`.
var last_size: Vector2i

# for debug logging.  x is calls to `update_screen`, y is calls to `debounce`.
var counter = Vector2i(0, 0)

# set when update_screen starts and unset when it ends.
# prevents us from queuing more updates because of changes made by update_screen.
var updating = false

func _ready():
	# in godot 4, the root viewport is a Window, and `get_window` returns the
	# same thing as `get_viewport` (unless `get_viewport` is called on a node in
	# a sub-viewport, i guess).
	window = get_window()
	rid = window.get_viewport_rid()
	window_id = get_window_id(window)
	
	# as of godot 4, we no longer get a signal when the OS window size changes,
	# so we need to listen for a size change on the window viewport.
	# consequently, we need to configure the window viewport to scale, so that
	# its size will change when the OS window size changes.
	window.set_content_scale_mode(Window.CONTENT_SCALE_MODE_VIEWPORT)
	window.set_content_scale_aspect(Window.CONTENT_SCALE_ASPECT_EXPAND)
	
	var viewport = get_viewport()
	if viewport == window: prints('**** viewport is window ****')
	else: prints('**** VIEWPORT IS *NOT* WINDOW ****')
	
	window.size_changed.connect(debounce)
	var base_size = update_screen(Vector2i(0, 0))
#	Log.info(self, ["ready! window size: ", get_window().size,
#			", base size: ", base_size])

# --------------------------------------------------------------------------- #

# manually resizing the window sends a bunch of resize events, natch, but we
# only want to rescale once, so we wait until the signals stop coming. 
# note that SceneTreeTimer does not free itself right away, so we must manually
# clear our timer pointer inside update_screen().
func debounce():
	counter.y += 1
	var c = Vector2i(counter)
	# if old == last_resize.old and new == last_resize.new:
	# 	this is our attempted resize, skip
	# if old == new == last_resize.old:
	# 	resize failed, add gutter
	prints(c, "[debounce] old:", last_size, "new:", window.size, "last resize:", last_resize_attempt, "| updating:", updating)
	# do not queue any more updates if we are already updating, or if the
	# new window size is the same as the window size before the last update
	# (to prevent thrashing if the window cannot be resized).
	if updating or (last_size == window.size and last_size != last_resize_attempt.position):
		var msg = 'clearing timer' if timer else 'no timer to clear'
		print(c, ' [debounce] ', msg)
		timer = null
	else:
		timer = get_tree().create_timer(DEBOUNCE_TIME)
		await timer.timeout
		update_screen(c)

# --------------------------------------------------------------------------- #

var last_resize_attempt: Rect2i

# for pixel perfect, the window size must exactly equal the base_size times the
# scale (the scaled_size), or else there must be a gutter of a few pixels.
# here we resize the window if possible, or render with a gutter if not.
func update_screen(source_counter):
	updating = true
	timer = null
	counter.x += 1
	var c = Vector2i(counter)
	prints(c, source_counter, "[update_screen] size:", window.size, "prev:", last_size,
		"| last_resize_attempt:", last_resize_attempt)
	last_size = Vector2i(window.size)
	
	current_scale = get_scale(window.size)
	var base_size = get_new_size(window.size, current_scale)
	var scaled_size = base_size * current_scale
	
	# seems functionally equivalent to base_size and 1
	window.set_content_scale_size(scaled_size)
	window.set_content_scale_factor(current_scale)
	
	var gutter = (last_size - scaled_size) / 2
	prints(c, "[update_screen] scaled_size:", scaled_size, "gutter:", gutter)
	
	if window.size != scaled_size: # we need to resize the window
		if window.size == last_resize_attempt.position:
			# this technically works, but the window viewport just snaps back to
			# the forced window size, so it only works for like a frame.  (if we
			# do not reset last_resize_attempt, it will keep working, but lag
			# the game.)
			# the proper solution here is definitely a sub-viewport.
			prints(c, "[update_screen] last resize failed, adding gutter")
			window.set_size(scaled_size)
			last_resize_attempt = Rect2i()
			RenderingServer.viewport_set_render_direct_to_screen(rid, true)
			RenderingServer.viewport_attach_to_screen(rid, Rect2(gutter, scaled_size))
		else:
			last_resize_attempt = Rect2i(window.size, scaled_size)
			window.set_size(scaled_size)
			prints(c, "[update_screen] resized window:", last_resize_attempt)
	else:
		prints(c, "[update_screen] no need to resize")
	
	prints(c, "[update_screen] done! last size:", last_size,
			"| window size:", window.size,
			"| scaled size:", scaled_size,
			"| base size:", base_size,
			"| scale:", current_scale)
	
	updating = false
	return base_size

# --------------------------------------------------------------------------- #

# the scale is found using IDEAL_SIZE, then clamped to the minimum and maximum
# possible scale just in case. if the window's width exceeds the maximum aspect
# ratio, we must calculate the scale using its height.
func get_scale(win_size) -> int:
	var i = 'y' if float(win_size.y) / float(win_size.x) < MIN_ASPECT else 'x'
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
	if float(win_size.y) / float(win_size.x) < MIN_ASPECT: # scale by height
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
	return clamp(win_size[i] / scale,
				max(low_val, MIN_SIZE[i]),
				min(high_val, MAX_SIZE[i]))

# --------------------------------------------------------------------------- #

# gets the DisplayServer window id for the main Menagerie window.
# this should pretty much always be 0 (there is only one window), but hopefully
# this will stop it from blowing up if we create a popup window or something.
# we don't actually do anything with this right now though, since manipulating
# the OS window separate from the viewport window seems to be impossible.
func get_window_id(instance):
	var ids = DisplayServer.get_window_list()
	for id in ids:
		if instance.get_instance_id() == DisplayServer.window_get_attached_instance_id(id):
			return id
	push_error('did not find the window!')
