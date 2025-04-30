extends Control

## the cursor can read input from three distinct sources.  we continually listen
## for input from all of these sources, but can only be in one "mode" at a time.
## input mode determines some nuances of cursor behavior.
enum InputMode { MOUSE, ACTION, TOUCH }

var stick_radius: float:
	set(x): $stick_area/shape.shape.radius = x
	get: return $stick_area/shape.shape.radius

var unstick_radius: float:
	set(x): $unstick_area/shape.shape.radius = x
	get: return $unstick_area/shape.shape.radius

var input_mode: InputMode = InputMode.MOUSE:
	set(x):
		input_mode = x
		if x == InputMode.ACTION:
			stick_radius = 5
			unstick_radius = 6
		if x == InputMode.MOUSE:
			stick_radius = 3
			unstick_radius = 6

## holds a pointer to the entity the cursor is currently stuck to, if one exists
var curr_body: Entity = null

# --------------------------------------------------------------------------- #

func _ready():
	$anim.play("cursor_bob")
	item_rect_changed.connect(reset_anim)
	$stick_area.body_entered.connect(maybe_stick)
	$unstick_area.body_exited.connect(unstick)
	set_process(true)

# --------------------------------------------------------------------------- #

func reset_anim():
	$anim.seek(0)

# --------------------------------------------------------------------------- #

## hide the actual cursor when the garden is paused, because we replace it with
## a hand graphic. unhide it for menus until we implement a custom menu cursor.
func _notification(n: int):
	if n == NOTIFICATION_UNPAUSED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if n == NOTIFICATION_PAUSED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --------------------------------------------------------------------------- #

## we can only detect touches using InputEventScreenTouch, so we must handle
## touch input in `_input` rather than in `_process`.
## similarly for mouse, when `Input.mouse_mode` is CAPTURED, we must handle
## mouse motion events with InputEventMouseMotion.relative. (since we sometimes
## have to programmatically move the cursor, this is probably a friendlier
## solution than force-moving the mouse cursor in those cases.)
func _input(e: InputEvent):
	handle_touch_input(e)
	handle_mouse_input(e)
	debug_radius_control(e)

# --------------------------------------------------------------------------- #

func _process(_delta):
	handle_action_input()
	move_graphic()
	if curr_body: $graphic/debug.text = str(curr_body)
	else: $graphic/debug.text = str(Vector2i($graphic.position))

# --------------------------------------------------------------------------- #

func debug_radius_control(e: InputEvent):
	const label_offset = 48
	if e is InputEventKey and e.is_released():
		for i in 10:
			if e.keycode - label_offset == i:
				if e.shift_pressed: unstick_radius = i
				else: stick_radius = i
		print('-----------------------------')
		print('stick: ', stick_radius, ' unstick: ', unstick_radius)
		print('-----------------------------')

# =========================================================================== #
#                               M O V E M E N T                               #
# --------------------------------------------------------------------------- #

## move the invisible part of the cursor: the stick and unstick areas.
## these should always move together. when the stick area overlaps an entity,
## we attach the cursor graphic to it while allowing the areas to continue
## moving freely. this creates the impression that the cursor is attracted to
## entities, in proportion to the size of the stick area.
func move(vec: Vector2, diff = false):
	if diff: $stick_area.position += vec
	else: $stick_area.position = vec
	$unstick_area.position = $stick_area.position

# --------------------------------------------------------------------------- #

## move the visible part of the cursor: the hand and shadow.
func move_graphic():
	var graphic_dest = curr_body.position if curr_body else $stick_area.position
	$graphic.position = $graphic.position.lerp(graphic_dest, 0.3)
	
	var new_hand_y: float = curr_body.size * 2 if curr_body else stick_radius
	# print(new_hand_y)
	$graphic/hand_anchor.position.y = -new_hand_y
	$graphic/shadow_anchor.position.y = curr_body.size - 1 if curr_body else stick_radius


# =========================================================================== #
#                     T A R G E T   I N T E R A C T I O N                     #
# --------------------------------------------------------------------------- #

func maybe_stick(body: Node2D):
	if curr_body and body == curr_body: return
	if body is Entity: stick(body)

# --------------------------------------------------------------------------- # 

func stick(body: Entity):
	if curr_body and curr_body != body: unstick(curr_body)
	curr_body = body
	get_parent().highlight(body)

# --------------------------------------------------------------------------- #

func unstick(body: Node2D):
	if body != curr_body: return
	curr_body = null
	get_parent().unhighlight(body)


# =========================================================================== #
#                         I N P U T   H A N D L I N G                         #
# --------------------------------------------------------------------------- #

func handle_touch_input(e: InputEvent):
	if e is InputEventScreenTouch and !e.canceled and !e.pressed:
		input_mode = InputMode.TOUCH
		move(make_canvas_position_local(e.position))

# --------------------------------------------------------------------------- #

func handle_mouse_input(e: InputEvent):
	if e is InputEventMouseMotion:
		input_mode = InputMode.MOUSE
		move(e.relative, true)

# --------------------------------------------------------------------------- #

## controls how fast key inputs move the cursor.
## this should be a configurable option but we can use a const for now.
const BASE_SPEED_MULT: float = 2.5
const FAST_SPEED_MULT: float = 1.8
var max_speed: float = 0.0

## handles both keypad and joystick input; whatever is bound to the four
## `cursor_{direction}` actions.
func handle_action_input():
	var speed_mult = BASE_SPEED_MULT
	if Input.is_action_pressed(&'cursor_accel'):
		speed_mult *= FAST_SPEED_MULT
	
	# calculates a normalized vector from our direction actions.
	# if key input, this is always max length (1) or 0 since keys don't have
	# action strength. if axis input, the length can be less than 1.
	var vector: Vector2 = Input.get_vector(
			&'cursor_left', &'cursor_right', &'cursor_up', &'cursor_down'
		) * speed_mult
	# 
	max_speed = min(max_speed, vector.length())
	
	if !vector.is_zero_approx():
		max_speed = lerpf(max_speed, speed_mult, 0.1)
		vector = vector.limit_length(max_speed)
		input_mode = InputMode.ACTION
		move(vector, true)
