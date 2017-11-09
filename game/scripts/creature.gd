extends KinematicBody2D

var Action = load("res://scripts/action.gd")

# action pointers
var past_actions = []
var current_action
var next_action

# status (meters)
var hunger
var mood
var energy
var social

# attributes
var intelligence
var vitality
var constitution
var charm
var amiability
var spirit

func _ready():
	set_process(true)
	pass

func _process(delta):
	walk()
	pass
	
func walk(): pass

func _on_focus():
	# touch input: first tap
	# mouse and gamepad: hover (make sure to add a short delay)
	# cursor will snap to pet - this effect should be greater for
	# gamepad than for mouse (and the delay greater to compensate)
	
	# alternately, focus immediately (should be good to see the
	# focus highlight & hud on no delay), but some delay before 
	# centering camera
	
	# hud: show basic pet info (name, status)
	# camera: keep pet centered
	# self: give pet selection highlight
	
	
	# game.focused_pet = self
	pass

func _on_select(): 
	# touch: second tap
	# gamepad: push select button; mouse: click
	
	# hud: show interaction buttons
	pass

func _on_unfocus():
	# touch: tap outside of pet
	# mouse and keyboard: hover off after delay
	
	# -----
	# game.focused_pet = null
	pass

func _on_discipline(discipline_type):
	# triggered by the ui button (PRASE, SCOLD, PET, HIT)
	
	update_preferences(discipline_type)
	update_status(discipline_type)
	
	# decide whether to stop current action
	pass

func _on_action_finished(action):
	update_status()
	update_attributes()
	past_actions.append(action)
	if past_actions.size() > 5:
		past_actions.pop_front()
	if (next_action):
		current_action = next_action
		next_action = null
	else: choose_action()

func _on_state_changed(state):
	update_status()
	pass
	
func _on_status_changed():
	# here we will probably have to decide if we need to
	# stop actions or enter some special state, if action
	# falls below certain trigger
	pass

func choose_action():
	# logic to select current and next action(s)
	var duration = 12
	current_action = Action.new(Action.IDLE_ACTION, duration)
	pass

func update_status():
	# updates the pet's status meters (mood, hunger, etc)
	pass
	
func update_preferences(): 
	# updates pet's likes and dislikes via discipline
	pass

func update_attributes(): 
	# INT, VIT, CON... via all sorts of stuff
	pass