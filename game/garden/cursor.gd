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
var curr_body

# for lerping the cursor graphic
var graphic_dest = Vector2()
var lerp_val = 0.3

# var is_enabled = true

# --------------------------------------------------------------------------- #
func _ready():
	$anim.play("cursor_bob")
	connect("item_rect_changed", self, "reset_anim")
	$stick_area.connect("body_entered", self, "stick")
	$unstick_area.connect("body_exited", self, "unstick")
	# Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
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
	if (curr_body and curr_body != body): unstick(curr_body)
	curr_body = body
	# var sprite_size = body.get_node("sprite").texture.get_size()
	graphic_dest = body.position
	var shape_node = body.get_node('shape')
	if shape_node:
		var sprite_size = shape_node.shape.radius * 2
		hand_height = sprite_size + VERTICAL_HAND_OFFSET
		Dispatcher.emit_signal("entity_highlighted", body)

# --------------------------------------------------------------------------- #
func unstick(body):
	if body == curr_body:
		hand_height = DEFAULT_HAND_HEIGHT
		curr_body = null
		Dispatcher.emit_signal("entity_unhighlighted", body)

# --------------------------------------------------------------------------- #
#warning-ignore:unused_argument
func _process(delta):
	$stick_area.position = get_global_mouse_position()

	$unstick_area.position = $stick_area.position
	graphic_dest = $stick_area.position

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
