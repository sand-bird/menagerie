extends KinematicBody2D

# =========================================================== #
#                     P R O P E R T I E S                     #
# ----------------------------------------------------------- #

var id
var monster_name
var species
var morph
var birthday
var mother
var father

# attributes
# ----------
# intelligence, vitality, constitution, charm, amiability, 
# and spirit. full names are used because "int" is reserved
var attributes = {}

# memory
# ------
var past_actions
var current_action
var next_action

# drives  
# ------
var belly
var mood
var energy
var social

# traits
# ------
# iq, learning, size, strength, health, composure, willpower, 
# patience, confidence, beauty, poise, independence, empathy, 
# kindness, arrogance, aggressiveness, happiness, loyalty,
# actualization, openness, appetite, sociability
var traits = {}

# preferences
# -----------
var preferences = {}


# =========================================================== #
#                        M E T H O D S                        #
# ----------------------------------------------------------- #

func _ready():
	$sprite.texture = Data.data.monsters[species].sprite

# ----------------------------------------------------------- #

func serialize():
	var data = {
		monster_name = monster_name,
		species = species,
		morph = morph,
		birthday = birthday,
		traits = {}
	}
	for i in traits:
		data.traits[i.name] = i.serialize()
	return data

# -----------------------------------------------------------

func deserialize(data):
	for i in data:
		print(i, ": ", data[i])

# -----------------------------------------------------------

func update_z():
	set_z(get_pos().y + get_item_rect().size.y)

# -----------------------------------------------------------

func _fixed_process(delta): 
	if current_action: 
		var action_status = current_action.execute()
#		if action_status == Action.FINISHED:
#			_on_action_finished()

# -----------------------------------------------------------

func choose_action():
	# logic to select current and next action(s)
	# var stomach_priority = (max_status.stomach - status.stomach) 
	#   / (max_status.stomach * 30) * 100
	# var duration = 12
	# current_action = Action.new(Action.IDLE_ACTION, duration)
	randomize()
#	current_action = Action.new(Utils.randi_range(2, 8) * 100)
	pass

# -----------------------------------------------------------

func update_drives():
	# updates the pet's drive meters (mood, hunger, etc)
	pass

# -----------------------------------------------------------

func update_preferences(): 
	# updates pet's likes and dislikes via discipline
	pass

# -----------------------------------------------------------

func recalc_attributes(): 
	# INT, VIT, CON... these are supposed to depend directly
	# on the traits that feed into them
	pass

# -----------------------------------------------------------

func _on_highlight():
	# possibly a third (or rather first) interaction state:
	# the highlight, for when the cursor is in "snapping"
	# range of the monster but the focus delay hasn't elapsed
	# yet (or for players using a "careful" (or whatever) 
	# targeting scheme, where they must press action to focus
	# and then again to select)
	pass

# -----------------------------------------------------------

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

# -----------------------------------------------------------

func _on_select(): 
	# touch: second tap
	# gamepad: push select button; mouse: click
	
	# hud: show interaction buttons
	pass

# -----------------------------------------------------------

func _on_unfocus():
	# touch: tap outside of pet
	# mouse and keyboard: hover off after delay
	
	# -----
	# game.focused_pet = null
	pass

# -----------------------------------------------------------

func _on_discipline(discipline_type):
	# triggered by the ui button (PRASE, SCOLD, PET, HIT)
	
	update_preferences(discipline_type)
	update_status(discipline_type)
	
	# decide whether to stop current action
	pass

# -----------------------------------------------------------

func _on_action_finished():
	print("action finished!")
	past_actions.append(current_action)
	if past_actions.size() > 5:
		past_actions.pop_front()
	if (next_action):
		current_action = next_action
		next_action = null
	else: choose_action()