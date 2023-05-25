extends SubViewport
"""
Forces the viewport to render at a multiple of a valid pixel resolution, so that
all displayed pixels appear perfectly square.  If the window is resizable, this
will resize it to the nearest valid resolution; if not, it will add gutters to
the edges of the viewport.
"""

# switch: 1280 × 720 -> (426,240) @ 3x + (2,0)
# 3ds: 400 × 240 (top), 320 × 240 (bottom) -> 1x
# ds: 256 × 192 (both screens) -> too small
# gba: 240 × 160  -> too small

# set screen size constraints here. IDEAL_SIZE determines the zoom level used
# in large resolutions, where multiple levels of zoom are valid.
const IDEAL_SIZE = Vector2i(400, 320)
# TOFIX: screen clipping in fullscreen when min sizes are inconsistent with the
# aspect ratio constraints
const MIN_SIZE = Vector2i(320, 208)
const MAX_SIZE = Vector2i(480, 360)

# superceded by the maximum and minimum size constraints
const MIN_ASPECT = 9.0/19.5 # 0.46
const MAX_ASPECT = 3.0/4.0  # 0.75

const MIN_SCALE = 1

# DEBOUNCE_TIME represents how long we wait for resize signals to stop coming
# before we do our thing, while the timer keeps track of this for us.
const DEBOUNCE_TIME = 0.1
var timer: SceneTreeTimer

# exposed for configuration i guess? sometimes multiple scales are valid at a
# given resolution (if the resolution is high enough)
var current_scale

var window: Window # the window viewport
var parent: SubViewportContainer # this viewport's parent container

# for debug logging.  x is calls to `update_screen`, y is calls to `debounce`
var counter = Vector2i(0, 0)

# set when update_screen starts and unset when it ends.
# prevents us from thrashing because of changes made during update_screen
var updating = false

func _ready():
	parent = get_parent()
	# as of godot 4, we no longer get a signal when the OS window size changes,
	# so we need to listen for a size change on the window viewport.
	# consequently, we need to configure the window viewport to scale, so that
	# its size will change when the OS window size changes.
	window = get_window()
	window.set_content_scale_mode(Window.CONTENT_SCALE_MODE_DISABLED)
	window.set_content_scale_aspect(Window.CONTENT_SCALE_ASPECT_EXPAND)
	window.size_changed.connect(debounce)
	var base_size = update_screen(Vector2i(0, 0))
	Log.info(self, ["ready! window size: ", get_window().size,
			", base size: ", base_size])

# --------------------------------------------------------------------------- #

# manually resizing the window sends a bunch of resize events, so we need to
# debounce to avoid thrash.
func debounce():
	counter.y += 1
	var c = Vector2i(counter)
	Log.verbose(self, [c, "[debounce] window size:", window.size, "| updating:", updating])
	# do not queue any more updates if we are already updating
	if updating:
		Log.verbose(self, [c, "[debounce]", "clearing timer" if timer else "no timer to clear"])
		timer = null
	else:
		timer = get_tree().create_timer(DEBOUNCE_TIME)
		await timer.timeout
		update_screen(c)

# --------------------------------------------------------------------------- #

# for pixel perfect, the viewport size must be an exact multiple of the base
# size, which depends on the window size and our size constraints defined in
# the constants above.  first we calculate the proper base size, then scale
# the viewport container to match, then finally offset it by the gutter so the
# viewport is centered in the window.
func update_screen(source_counter):
	updating = true
	counter.x += 1
	var c = Vector2i(counter)
	
	current_scale = get_scale(window.size)
	var base_size = get_new_size(window.size, current_scale)
	var scaled_size = base_size * current_scale
	
	var gutter = (window.size - scaled_size) / 2
	if gutter.x < 0 or gutter.y < 0:
		prints(c, source_counter, "[update_screen] WARNING, negative gutter!", gutter,
			"| window size:", window.size,
			"| scaled size:", scaled_size,
			"| base size:", base_size,
			"| scale:", current_scale
		)
	parent.position = gutter
	parent.set_deferred('size', scaled_size)
	parent.stretch_shrink = current_scale
	
	Log.verbose(self, [c, source_counter,
		"[update_screen] done! window size:", window.size,
		"| scaled size:", scaled_size,
		"| base size:", base_size,
		"| scale:", current_scale
	])
	updating = false
	return base_size

# --------------------------------------------------------------------------- #

# just some sugar to floating-point divide our many ints
func div(a: int, b: int) -> float: return float(a) / float(b)

# the scale is found using IDEAL_SIZE, then clamped to the minimum and maximum
# possible scale just in case. if the window's width exceeds the maximum aspect
# ratio, we must calculate the scale using its height.
func get_scale(win_size) -> int:
	var scale_x = div(win_size.x, IDEAL_SIZE.x)
	var scale_y = div(win_size.y, IDEAL_SIZE.y)
	
	Log.verbose(self, ['x:', scale_x, 'y:', scale_y])
	
	var aspect = div(win_size.y, win_size.x)
	# if the window's aspect ratio is closer to the minimum (wider), use height
	# to calculate scale; if closer to the maximum (taller), use width
	var weight = inverse_lerp(MIN_ASPECT, MAX_ASPECT, aspect)
	var i = 'y' if weight < 0.5 else 'x'
	Log.verbose(self, ['[get_scale] aspect:', aspect, 'weight:', weight, 'i:', i])
	Log.verbose(self, ['[get_scale] win:', win_size[i],
		'ideal:', IDEAL_SIZE[i], 'min:', MIN_SIZE[i], 'max:', MAX_SIZE[i]
	])
	var scale_basis = div(win_size[i], IDEAL_SIZE[i])
	var scale_min = ceil(div(win_size[i], MAX_SIZE[i]))
	var scale_max = floor(div(win_size[i], MIN_SIZE[i]))
	
	var result = clamp(round(scale_basis), scale_min, scale_max)
	
	Log.verbose(self, ['[get_scale]',
		'scale_basis:', scale_basis,
		'scale_min:', scale_min,
		'scale_max:', scale_max,
		'result:', result,
	])
	return max(result, MIN_SCALE)

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
	return Vector2i(new_x, new_y) # implicit floor

# --------------------------------------------------------------------------- #

func get_primary(i, win_size, scale):
	return max(
		win_size[i] / scale,
		MIN_SIZE[i]
	)

func get_secondary(i, win_size, scale, low_val, high_val):
	return clamp(
		win_size[i] / scale,
		max(low_val, MIN_SIZE[i]),
		min(high_val, MAX_SIZE[i])
	)
