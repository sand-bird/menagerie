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
onready var hand = $graphic/hand_anchor

const HAND_X = 4
const DEFAULT_HAND_HEIGHT = 16
const VERTICAL_HAND_OFFSET = 8
var hand_height = DEFAULT_HAND_HEIGHT

var selecting = false
# holds a pointer to the entity the cursor is currently stuck to, if one exists
var curr_body = null
# time in seconds to wait since the mouse was last moved before we warp the
# mouse cursor on top of the entity it's stuck to (if one exists). we do this
# to keep the cursor stuck to a moving monster until the player moves it away.
const MOUSE_FOLLOW_DELAY = 0.1

# for lerping the cursor graphic
var graphic_dest = Vector2()
var lerp_val = 0.3

# var is_enabled = true

# --------------------------------------------------------------------------- #

func _ready():
	$anim.play("cursor_bob")
	connect("item_rect_changed", self, "reset_anim")
	$stick_area.connect("body_entered", self, "stick")
	$unstick_area.connect("body_entered", self, "stick")
	$unstick_area.connect("body_exited", self, "unstick")
	set_process(true)

# --------------------------------------------------------------------------- #

func reset_anim():
	$anim.seek(0)

# --------------------------------------------------------------------------- #

func _notification(n):
	if n == NOTIFICATION_UNPAUSED:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if n == NOTIFICATION_PAUSED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --------------------------------------------------------------------------- #

func stick(body):
	if selecting: return
	if curr_body:
		if body == curr_body: return
		else: unstick(curr_body)
	curr_body = body
	var shape_node = body.get_node('shape')
	if shape_node:
		var sprite_size = 8
		if shape_node is CircleShape2D:
			sprite_size = shape_node.shape.radius * 2
		elif shape_node is RectangleShape2D:
			sprite_size = shape_node.extents.y * 2
		hand_height = sprite_size + VERTICAL_HAND_OFFSET
		Dispatcher.emit_signal("entity_highlighted", body)

# --------------------------------------------------------------------------- #

func unstick(body):
	if body == curr_body:
		hand_height = DEFAULT_HAND_HEIGHT
		curr_body = null
		Dispatcher.emit_signal("entity_unhighlighted", body)

# --------------------------------------------------------------------------- #

var last_mouse_speed = Vector2()
var time_since_mouse_moved = 0.0

func measure_mouse_movement(delta):
	var current_mouse_speed = Input.get_last_mouse_speed()
	if current_mouse_speed != last_mouse_speed:
		last_mouse_speed = current_mouse_speed
		time_since_mouse_moved = 0.0
	else:
		time_since_mouse_moved += delta

# --------------------------------------------------------------------------- #

func _input(e):
	if e is InputEventMouseButton and e.is_pressed():
		if curr_body:
			Dispatcher.emit_signal("entity_selected", curr_body)
			print('clicked target')
			selecting = true
			unstick(curr_body)
		else:
			Dispatcher.emit_signal("entity_unselected")
			selecting = false
		# get_tree().set_input_as_handled()

# --------------------------------------------------------------------------- #

func _process(delta):
	measure_mouse_movement(delta)
	# decide whether to follow a highlighted entity. if player has moved the
	# mouse recently, then stop following so we don't get stuck.
	if curr_body && time_since_mouse_moved > MOUSE_FOLLOW_DELAY and !selecting:
		Player.garden.set_mouse_position(curr_body.position)
		# get_global_mouse_position doesn't update until the player moves the
		# mouse manually, so we have to set this separately
		$stick_area.position = curr_body.position
	else:
		$stick_area.position = get_local_mouse_position()
	
	$unstick_area.position = $stick_area.position
	graphic_dest = curr_body.position if curr_body else $stick_area.position

	var new_graphic_pos = Utils.vlerp(
			$graphic.rect_position, graphic_dest, lerp_val).round()

	if (new_graphic_pos == $graphic.rect_position.round()
			and new_graphic_pos != graphic_dest):
		$graphic.rect_position = graphic_dest
	else:
		$graphic.rect_position = new_graphic_pos

	var new_hand_y = lerp(hand.rect_position.y,
			-hand_height, lerp_val)
	hand.rect_position = Vector2(HAND_X, new_hand_y).round()
