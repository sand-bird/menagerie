extends Camera2D

## so we can turn off drag scrolling if we are using drag for something else,
## such as laying tiles.
var drag_action = "scroll"


# viewport properties
var screen_size
var screen_radius
var edge_width ## used for edge scroll
var dead_zone_radius ## used for edge scroll

# parent properties
var base_pos ## global pos of parent - this is our (0, 0), even if parent is offset
var parent_size ## parent dimensions (for clamping the view)
var parent_center ## global pos of parent's center
var center_pos ## global pos to center the view on the parent's center

# parent boundaries so we can't scroll forever
var min_pos = Vector2(-INF, -INF)
var max_pos = Vector2(INF, INF)

# mouse info, used for edge and drag scroll
@onready var last_mouse_pos = get_local_mouse_position()
var target_pos = Vector2()

var stick_target = null

# --------------------------------------------------------------------------- #

func _ready():
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	get_tree().get_root().size_changed.connect(_on_screen_resized)
	$"..".resized.connect(_on_screen_resized)

	_on_screen_resized()

	set_process(true)
#	set_process_input(true) # we'll need this for joystick & button scroll (maybe)

# --------------------------------------------------------------------------- #

# func _input(event): pass

# --------------------------------------------------------------------------- #

func _on_screen_resized():
	get_screen_settings()
	get_bounds()
	center()

# --------------------------------------------------------------------------- #

func get_screen_settings():
	screen_size = get_viewport_rect().size
	screen_radius = screen_size / 2.0
	edge_width = screen_size * Options.edge_scroll_edge_size
	dead_zone_radius = screen_radius - edge_width

# --------------------------------------------------------------------------- #

## calculates and stores the properties of the camera's parent node (the garden)
## so we can initialize it to the center and stop it from scrolling too far past
## the parent's boundaries. no relation to the screen size properties.
##
## for now, lets us view a fifth of the parent's size or a quarter of the screen
## size, whichever's smaller, of space outside the bounds of the parent (magic
## numbers below).
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
	var bound_padding = U.vmax(
		Vector2(200, 200),
		U.vmin(parent_size * 0.2, screen_size * 0.25)
	)
	min_pos = U.vmin((parent_min - bound_padding).round(), center_pos)
	max_pos = U.vmax((parent_max + bound_padding - screen_size).round(), center_pos)

# --------------------------------------------------------------------------- #

func center():
	position = center_pos
	target_pos = center_pos
	align()

func stick(target):
	print('camera stick | to: ', target.position, ' | target_pos: ', target_pos)
	# target_pos = target.position - screen_radius
	stick_target = target
	align()

# --------------------------------------------------------------------------- #

## scroll based on touch (or click) input. moves the camera opposite the drag
## direction and magnitude to create the impression of dragging the screen.
func do_drag_scroll():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && drag_action == "scroll":
		# calculate move delta
		var mouse_pos = get_local_mouse_position()
		var move_delta = last_mouse_pos - mouse_pos
		# update target position
		var new_target_pos = position + move_delta * Options.drag_scroll_flick_distance
		target_pos.x = round(lerp(target_pos.x, new_target_pos.x, 0.5))
		target_pos.y = round(lerp(target_pos.y, new_target_pos.y, 0.5))

# --------------------------------------------------------------------------- #

## RTS-style scroll based on cursor position.
## scrolls the camera when the cursor reaches `Options.camera_edge_size` percent
## of the window's width or height from the edge of the window, with a speed
## proportionate to the cursor's distance from the absolute edge.
func do_edge_scroll():
	if !Options.edge_scroll_enabled: return
	# calculate move delta
	var heading = get_local_mouse_position() - screen_radius
	var direction = heading.sign()
	var abs_heading = heading.abs()
	if abs_heading.x >= dead_zone_radius.x or abs_heading.y >= dead_zone_radius.y:
		var move_delta = abs_heading
		# update target position
		var new_target_pos = position + move_delta * direction * Options.edge_scroll_speed
		target_pos.x = round(lerp(target_pos.x, new_target_pos.x, 0.1))
		target_pos.y = round(lerp(target_pos.y, new_target_pos.y, 0.1))

# --------------------------------------------------------------------------- #

## moves the camera up, down, left, and/or right based on key input. suitable
## for mouse-and-keyboard or keyboard only input schemes. naturally also works
## for joypad buttons, since the primary purpose of key-only is for all inputs
## to be externally remappable to an unrecognized controller.
func do_key_scroll():
	pass

# --------------------------------------------------------------------------- #

## scrolls based on joystick axis (-1.0 to 1.0 vertical and horizontal).
## hopefully identifying joystick axes won't be too bad :(
func do_joystick_scroll():
	pass

# --------------------------------------------------------------------------- #

func _process(_delta):
	target_pos = $'../cursor/stick_area'.position.round()
	# handle all our different scroll behaviors
	#for scroll_type in ['drag', 'edge', 'key', 'joystick']:
		#call('_'.join(['do', scroll_type, 'scroll']))
#
	#if stick_target:
		#target_pos = stick_target.position - screen_radius
#
	# clamp target to camera bounds
#	target_pos = target_pos.clamp(min_pos, max_pos).round()
#
	# lerp camera to target position
	if position.round() != target_pos:
		position = position.lerp(target_pos, 0.1)
		align()

	## update saved cursor position (for drag scroll)
	#last_mouse_pos = get_local_mouse_position()

# --------------------------------------------------------------------------- #

func deserialize(data):
	var pos = U.parse_vec(data)
	position = pos
	target_pos = pos
	align()

func serialize():
	return U.format_vec(position)
