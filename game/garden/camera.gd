extends Camera2D

var ScrollMode = Constants.ScrollMode

# so we can turn off drag scrolling if we are using
# drag for something else, such as laying tiles.
var drag_action = "scroll"

# options used for drag scroll
var FLICK_DISTANCE = Options.camera_flick_distance
var FLICK_SPEED = Options.camera_flick_speed # 1.0

# options used for edge scroll
var EDGE_SIZE = Options.camera_edge_size
var SCROLL_SPEED = Options.camera_scroll_speed
var SCROLL_ACCEL = Options.camera_scroll_acceleration
var SCROLL_LERP = 0.05

# viewport properties
var screen_size
var screen_radius
var edge_width # used for edge scroll
var dead_zone_radius # used for edge scroll

# parent properties
var base_pos # global pos of parent - this is our (0, 0), even if parent is offset
var parent_size # parent dimensions (for clamping the view)
var parent_center # global pos of parent's center
var center_pos # global pos to center the view on the parent's center

# parent boundaries so we can't scroll forever
var min_pos
var max_pos

# mouse info, used for edge and drag scroll
onready var last_mouse_pos = get_local_mouse_position()
var target_pos = Vector2()

# -----------------------------------------------------------

func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	$"..".connect("resized", self, "_on_screen_resized")
	
	_on_screen_resized()
	
	set_physics_process(true)
#	set_process_input(true) # we'll need this for joystick & button scroll (maybe)

# -----------------------------------------------------------

func _input(event): pass

# -----------------------------------------------------------

func _on_screen_resized():
	get_screen_settings()
	get_bounds()
	center()


# -----------------------------------------------------------

func get_screen_settings():
	screen_size = get_viewport_rect().size
	screen_radius = screen_size / 2.0
	edge_width = screen_size * EDGE_SIZE
	dead_zone_radius = screen_radius - edge_width

# -----------------------------------------------------------

# calculates and stores the properties of the camera's parent 
# node (the garden) so we can initialize it to the center and 
# stop it from scrolling too far past the parent's boundaries.
# no relation to the screen size properties.
#
# for now, lets us view a fifth of the parent's size or a
# quarter of the screen size, whichever's smaller, of space 
# outside the bounds of the parent (magic numbers below).
func get_bounds():
	# set up our member vars
# 	base_pos = get_parent().get_global_pos() # i guess not???
	base_pos = Vector2(0, 0)
	parent_size = get_parent().get_size()
	parent_center = base_pos + parent_size.floor() / 2
	center_pos = parent_center - screen_radius
	
	# calculate pos values for our bounds
	var parent_min = base_pos
	var parent_max = base_pos + parent_size
	var bound_padding = Utils.vmin(parent_size * 0.2, screen_size * 0.25)
	min_pos = Utils.vmin(Utils.vround(parent_min - bound_padding), center_pos)
	max_pos = Utils.vmax(Utils.vround(parent_max + bound_padding - screen_size), center_pos)

# -----------------------------------------------------------

func center():
	position = center_pos
	target_pos = center_pos
	align()

# -----------------------------------------------------------

# scroll based on touch (or click) input. moves the camera
# opposite the drag direction and magnitude to create the
# impression of dragging the screen.
func do_drag_scroll():
	if Input.is_mouse_button_pressed(1) && drag_action == "scroll":
		# calculate move delta
		var mouse_pos = get_local_mouse_position()
		var move_delta = last_mouse_pos - mouse_pos
		# update target position
		var new_target_pos = position + move_delta * FLICK_DISTANCE
		target_pos.x = round(lerp(target_pos.x, new_target_pos.x, 0.5))
		target_pos.y = round(lerp(target_pos.y, new_target_pos.y, 0.5))

# -----------------------------------------------------------

# RTS-style scroll based on cursor position, only suitable
# for mouse input. scrolls the camera when the cursor reaches
# EDGE_SIZE from the edge of the window, proportionate to
# the cursor's distance from the absolute edge.
func do_edge_scroll():
	# calculate move delta
	var heading = get_local_mouse_position() - screen_radius
	var direction = Utils.vsign(heading)
	var abs_heading = heading.abs()
	if abs_heading.x >= dead_zone_radius.x or abs_heading.y >= dead_zone_radius.y:
		var move_delta = abs_heading
		# update target position
		var new_target_pos = position + move_delta * direction * SCROLL_SPEED
		target_pos.x = round(lerp(target_pos.x, new_target_pos.x, 0.1))
		target_pos.y = round(lerp(target_pos.y, new_target_pos.y, 0.1))

# -----------------------------------------------------------

# moves the camera up, down, left, and/or right based on key
# input. suitable for mouse-and-keyboard or keyboard only
# input schemes. naturally also works for joypad buttons, 
# since the primary purpose of key-only is for all inputs to 
# be externally remappable to an unrecognized controller.
func do_key_scroll():
	pass

# -----------------------------------------------------------

# scrolls based on joystick axis (-1.0 to 1.0 vertical and
# horizontal). hopefully identifying joystick axes won't be too bad :(
func do_joystick_scroll():
	pass

# -----------------------------------------------------------

func _physics_process(delta):
	# update target_pos via our scroll methods
	if Options.is_scroll_enabled(ScrollMode.EDGE_SCROLL): do_edge_scroll()
	if Options.is_scroll_enabled(ScrollMode.DRAG_SCROLL): do_drag_scroll()
	# (not sure if these will be here or in _process_input)
	if Options.is_scroll_enabled(ScrollMode.KEY_SCROLL): do_key_scroll()
	if Options.is_scroll_enabled(ScrollMode.JOYSTICK_SCROLL): do_joystick_scroll()
	
	# clamp target to camera bounds
	target_pos = Utils.vround(Utils.vclamp(target_pos, min_pos, max_pos))
	
	# lerp camera to target position
	if position != target_pos:
#		var new_x = round(lerp(position.x, target_pos.x, FLICK_SPEED / FLICK_DISTANCE))
#		var new_y = round(lerp(position.y, target_pos.y, FLICK_SPEED / FLICK_DISTANCE))
#		position = Vector2(new_x, new_y)
		position = Utils.vlerp(position, target_pos, FLICK_SPEED / FLICK_DISTANCE)
		align()
	
	# update saved cursor position (for drag scroll)
	last_mouse_pos = get_local_mouse_position()

# -----------------------------------------------------------

func deserialize(data):
	for i in ["x", "y"]: 
		position[i] = data[i]
		target_pos[i] = data[i]
		align()

func serialize():
	return { "x": position.x, "y": position.y }