extends Control
onready var anim = get_node("anim")
onready var area = get_node("area")
onready var graphic = get_node("graphic")
onready var hand = get_node("graphic/hand_anchor")

const HAND_X = 4
const DEFAULT_HAND_HEIGHT = 16
var hand_height = DEFAULT_HAND_HEIGHT
var curr_body

# for lerping the cursor graphic
var graphic_dest = Vector2()
var lerp_val = 0.3

var is_free = true
var is_enabled = true

func _ready():
	anim.play("cursor_bob")
	connect("item_rect_changed", self, "reset_anim")
	area.connect("body_enter", self, "stick")
	area.connect("body_exit", self, "unstick")
	grab_mouse()

func grab_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_process(true)

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	set_process(false)

func stick(body):
	is_free = false
	curr_body = body
#	var body_size = body.get_node("sprite").get_item_rect().size
#	graphic_dest = body.get_pos() + Vector2(ceil(body_size.x / 2), body_size.y).floor()
#	hand_height = body_size.y + 8
	var shape_size = body.get_shape(0).get_extents()
	graphic_dest = body.get_pos() + Vector2(0, shape_size.y)
	hand_height = shape_size.y * 4 + 8

func unstick(body):
	if body == curr_body:
		hand_height = DEFAULT_HAND_HEIGHT
		is_free = true

func reset_anim():
	anim.seek(0)

func _input_event(event):
	if (event.type == InputEvent.MOUSE_BUTTON) and event.is_pressed():
		anim.play("click")
		anim.queue("cursor_bob")

func _process(delta):
	area.set_pos(get_global_mouse_pos())
	if is_free: graphic_dest = get_global_mouse_pos()
	var new_graphic_pos = Utils.vlerp(graphic.get_pos(), graphic_dest, lerp_val)
	graphic.set_pos(new_graphic_pos)
	var new_hand_y = lerp(hand.get_pos().y, -hand_height, lerp_val)
	hand.set_pos(Vector2(HAND_X, new_hand_y))
#	print(new_graphic_pos, "\t", graphic_dest)