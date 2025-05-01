@tool
extends Control

# Example usage:
# var menu = $radial_menu
# menu.add_child(create_button("Option 1", preload("res://icon1.png"), func(): print("1")))
# menu.add_child(create_button("Option 2", preload("res://icon2.png"), func(): print("2")))

# Properties
@export var radius: float = 24.0:  # Distance from center to buttons
	set(x):
		radius = x
		position_children()

# Animation properties
@export var animation_duration: float = 0.2

# --------------------------------------------------------------------------- #

# Called when the node enters the scene tree
func _ready():
	child_entered_tree.connect(position_children)
	child_exiting_tree.connect(position_children)
	child_order_changed.connect(position_children)
	position_children()
	animate_enter()
	
	if Engine.is_editor_hint():
		process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		get_tree().paused = true
		tree_exiting.connect(_on_tree_exiting)

# --------------------------------------------------------------------------- #

func _on_tree_exiting(): pass
#	await animate_exit()
#	get_tree().paused = false

# --------------------------------------------------------------------------- #

# Position all children in a circle
func position_children(_child = null) -> void:
	var controls = get_children()
	var count = controls.size()
	if count == 0: return
	
	for i in range(count):
		var child = controls[i]
		
		# Calculate position in circle, starting from top (-PI/2)
		var angle = (-PI/2) + (2 * PI * i) / count
		var pos = Vector2(
			radius * cos(angle),
			radius * sin(angle)
		)
		
		# Center the child at the calculated position
		pos -= child.size / 2
		
		# Set position directly
		child.position = pos

# --------------------------------------------------------------------------- #

# Helper function to create a button with the given properties
static func create_button(label: String = "", icon: Texture2D = null, callback: Callable = Callable()) -> Button:
	var button = Button.new()
	button.text = label
	
	if icon:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
	
	if callback.is_valid():
		button.pressed.connect(callback)
		
	return button


# =========================================================================== #
#                             A N I M A T I O N S                             #
# --------------------------------------------------------------------------- #

func animate_enter() -> void:
	# Create parallel animations
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Add all animations
	animate_scale(tween)
	animate_rotation(tween)
#	animate_fade(tween)
#	animate_buttons_staggered(tween)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

# --------------------------------------------------------------------------- #

func animate_exit():
	# Animate to scale 0 before freeing
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Add all closing animations
	tween.tween_property(self, "scale", Vector2.ZERO, animation_duration)
	tween.tween_property(self, "modulate:a", 0.0, animation_duration)
	tween.tween_property(self, "rotation", -TAU, animation_duration)
	
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	await tween.finished

# --------------------------------------------------------------------------- #
# Animation functions

func animate_scale(tween: Tween) -> void:
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2.ONE, animation_duration)

func animate_fade(tween: Tween) -> void:
	modulate.a = 0
	tween.tween_property(self, "modulate:a", 1.0, animation_duration)

func animate_rotation(tween: Tween) -> void:
	rotation = - PI / 8.0
	tween.tween_property(self, "rotation", 0, animation_duration)

func animate_buttons_staggered(tween: Tween) -> void:
	var controls = get_children()
	var stagger_delay = (animation_duration * 0.7) / controls.size()
	for i in range(controls.size()):
		var child = controls[i]
		child.pivot_offset = child.size / 2.0
		child.scale = Vector2.ZERO
		var button_tween = tween.tween_property(child, "scale", Vector2.ONE, animation_duration)
		button_tween.set_delay(i * stagger_delay)
		button_tween.set_ease(Tween.EASE_OUT)
