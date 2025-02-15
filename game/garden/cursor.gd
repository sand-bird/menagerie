extends Control

# the cursor has two parts: a collsion circle that tracks the mouse cursor
# (or is moved via joystick/keyboard input), and the hand graphic. when the
# circle overlaps an entity, the cursor becomes "stuck" to that entity.
# when stuck:
# - both parts of the cursor should follow that entity around
# - the camera should probably center on the entity (or save this for when the
#   entity is "selected"?)
# - (maybe) when the entity is too close to the edge of the garden for the
#   camera to center on it, we should update the actual mouse position
@onready var hand = $graphic/hand

const HAND_X = 3
const DEFAULT_HAND_HEIGHT = 16
# used for positioning the cursor hand graphic when it's stuck to an entity.
# the entity's sprite should be taller than its shape (the shape represents the
# part that touches the ground).  for quick & dirty positioning, we multiply
# the shape's height by this magic number.
const SHAPE_HEIGHT_MULTIPLIER = 1.2
var hand_height: int = DEFAULT_HAND_HEIGHT

var selecting = false
# holds a pointer to the entity the cursor is currently stuck to, if one exists
var curr_body: Node2D = null
# time in seconds to wait since the mouse was last moved before we warp the
# mouse cursor on top of the entity it's stuck to (if one exists). we do this
# to keep the cursor stuck to a moving monster until the player moves it away.
const MOUSE_FOLLOW_DELAY = 0.1

# for lerping the cursor graphic
var graphic_dest = Vector2()
const lerp_val = 0.3

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

# hide the actual cursor when the garden is paused, because we replace it with
# a hand graphic. unhide it for menus until we implement a custom menu cursor.
func _notification(n: int):
	if n == NOTIFICATION_UNPAUSED:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if n == NOTIFICATION_PAUSED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --------------------------------------------------------------------------- #

func maybe_stick(body: Node2D):
	if selecting: return
	if curr_body:
		if body == curr_body: return
		else: unstick(curr_body)
	if body is Entity:
		stick(body)

# --------------------------------------------------------------------------- # 

func stick(body: Entity):
	curr_body = body
	var shape_node = body.shape.shape
	if shape_node:
		var shape_height = 8
		if shape_node is CircleShape2D:
			shape_height = shape_node.radius * 2
		elif shape_node is RectangleShape2D:
			shape_height = shape_node.size.y
		hand_height = shape_height * SHAPE_HEIGHT_MULTIPLIER
		get_parent().highlight(body)

# --------------------------------------------------------------------------- #

func unstick(body: Node2D):
	if body != curr_body: return
	hand_height = DEFAULT_HAND_HEIGHT
	curr_body = null
	get_parent().unhighlight(body)

# --------------------------------------------------------------------------- #

var last_mouse_speed = Vector2()
var time_since_mouse_moved = 0.0

func measure_mouse_movement(delta):
	var current_mouse_speed = Input.get_last_mouse_velocity()
	if current_mouse_speed != last_mouse_speed:
		last_mouse_speed = current_mouse_speed
		time_since_mouse_moved = 0.0
	else:
		time_since_mouse_moved += delta

# --------------------------------------------------------------------------- #

func _process(delta):
	if curr_body: $graphic/debug.text = str(curr_body)
	else: $graphic/debug.text = str(Vector2i($graphic.position))
	measure_mouse_movement(delta)
	# decide whether to follow a highlighted entity. if player has moved the
	# mouse recently, then stop following so we don't get stuck.
#	if curr_body && time_since_mouse_moved > MOUSE_FOLLOW_DELAY and !selecting:
#		print('this is where we would stick to the body')
#		Player.garden.set_mouse_position(curr_body.position)
		# get_global_mouse_position doesn't update until the player moves the
		# mouse manually, so we have to set this separately
#		$stick_area.position = curr_body.position
#	else:
	$stick_area.position = get_local_mouse_position()
	$unstick_area.position = $stick_area.position
	graphic_dest = curr_body.position if curr_body else $stick_area.position

	var new_graphic_pos = $graphic.position.lerp(graphic_dest, lerp_val).round()

	$graphic.position = graphic_dest if (
		new_graphic_pos == $graphic.position.round()
		and new_graphic_pos != graphic_dest
	) else new_graphic_pos

	var new_hand_y = lerp(hand.position.y, float(-hand_height), lerp_val)
	hand.position = Vector2(HAND_X, new_hand_y).round()
