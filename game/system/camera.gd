extends Camera2D

const ScrollMode = Globals.ScrollMode

# options used for drag scroll
var FLICK_DISTANCE = Options.camera_flick_distance
var FLICK_SPEED = Options.camera_flick_speed

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

# mouse info, used for both
var last_mouse_pos = get_local_mouse_pos()
var target_pos= Vector2()


func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	
	get_screen_settings()
	get_bounds()
	
	# let's start centered
	set_pos(center_pos)
	align()
	target_pos = center_pos
	
	set_fixed_process(true)
#	set_process_input(true) # we'll need this for joystick & button scroll (maybe)

# -----------------------------------------------------------

func _input(event): pass

# -----------------------------------------------------------

func _on_screen_resized():
	get_screen_settings()
	get_bounds()

# -----------------------------------------------------------

func get_screen_settings():
	screen_size = get_viewport_rect().size
	screen_radius = screen_size / 2.0
	edge_width = screen_size * EDGE_SIZE
	dead_zone_radius = screen_radius - edge_width

# -----------------------------------------------------------

func get_bounds():
	# set up our member vars
# 	base_pos = get_parent().get_global_pos() # i guess not???
	base_pos = Vector2(0, 0)
	parent_size = get_parent().get_size()
	parent_center = base_pos + Utils.vround(parent_size / 2)
	center_pos = parent_center - screen_radius
	
	# calculate pos values for our bounds
	var parent_min = base_pos
	var parent_max = base_pos + parent_size
	var bound_padding = Utils.vmin(parent_size * 0.2, screen_size * 0.25)
	min_pos = Utils.vmin(Utils.vround(parent_min - bound_padding), center_pos)
	max_pos = Utils.vmax(Utils.vround(parent_max + bound_padding - screen_size), center_pos)

# -----------------------------------------------------------

func do_drag_scroll():
	if Input.is_mouse_button_pressed(1):
		# calculate move delta
		var mouse_pos = get_local_mouse_pos()
		var move_delta = last_mouse_pos - mouse_pos
		# update target position
		var new_target_pos = get_pos() + move_delta * FLICK_DISTANCE
		target_pos.x = round(lerp(target_pos.x, new_target_pos.x, 0.5))
		target_pos.y = round(lerp(target_pos.y, new_target_pos.y, 0.5))

# -----------------------------------------------------------

func do_edge_scroll():
	# calculate move delta
	var heading = get_local_mouse_pos() - screen_radius
	var direction = Utils.vsign(heading)
	var abs_heading = Utils.vabs(heading)
	if abs_heading.x >= dead_zone_radius.x or abs_heading.y >= dead_zone_radius.y:
		var move_delta = abs_heading
		# update target position
		var new_target_pos = get_pos() + move_delta * direction * SCROLL_SPEED
		target_pos.x = round(lerp(target_pos.x, new_target_pos.x, 0.1))
		target_pos.y = round(lerp(target_pos.y, new_target_pos.y, 0.1))

# -----------------------------------------------------------

func do_key_scroll():
	pass

# -----------------------------------------------------------

func do_joystick_scroll():
	pass

# -----------------------------------------------------------

func _fixed_process(delta): pass
	# update target_pos via our scroll methods
	if Options.is_scroll_enabled(ScrollMode.EDGE_SCROLL): do_edge_scroll()
	if Options.is_scroll_enabled(ScrollMode.DRAG_SCROLL): do_drag_scroll()
	if Options.is_scroll_enabled(ScrollMode.KEY_SCROLL): do_button_scroll()
	if Options.is_scroll_enabled(ScrollMode.JOYSTICK_SCROLL): do_joystick_scroll()
	
	# clamp target to camera bounds
	target_pos = Utils.vround(Utils.vclamp(target_pos, min_pos, max_pos))
	
	# lerp camera to target position
	if get_pos() != target_pos:
		var new_x = round(lerp(get_pos().x, target_pos.x, FLICK_SPEED / FLICK_DISTANCE))
		var new_y = round(lerp(get_pos().y, target_pos.y, FLICK_SPEED / FLICK_DISTANCE))
		set_pos(Vector2(new_x, new_y))
		align()
	
	# update saved cursor position (for drag scroll)
	last_mouse_pos = get_local_mouse_pos()