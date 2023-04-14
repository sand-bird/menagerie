extends CharacterBody2D

# =========================================================== #
#                     P R O P E R T I E S                     #
# ----------------------------------------------------------- #

var mother
var father

var pet_name
var species
var color
var birthday


# =========================================================== #
#                     A T T R I B U T E S                     #
# ----------------------------------------------------------- #

var intelligence
var vitality
var constitution
var charm
var amiability
var spirit

var attributes = [
	intelligence, vitality, constitution,
	charm, amiability, spirit
]

# =========================================================== #
#                         M E M O R Y                         #
# ----------------------------------------------------------- #
var Action = preload("res://monster/action.gd")

var past_actions = []
var current_action
var next_action

# =========================================================== #
#                         D R I V E S                         #
# ----------------------------------------------------------- #

var belly
var mood
var energy
var social

# =========================================================== #
#                         T R A I T S                         #
# ----------------------------------------------------------- #
const Trait = preload("res://monster/traits.gd")

# INT -------------------------------------------------------
var iq = Trait.Iq.new()
var learning = Trait.Learning.new()
# VIT -------------------------------------------------------
var size = Trait.Size.new()
var strength = Trait.Strength.new()
var health = Trait.Health.new()
# CON -------------------------------------------------------
var composure = Trait.Composure.new()
var willpower = Trait.Willpower.new()
var patience = Trait.Patience.new()
# CHA -------------------------------------------------------
var confidence = Trait.Confidence.new()
var beauty = Trait.Beauty.new()
var poise = Trait.Poise.new()
# AMI -------------------------------------------------------
var independence = Trait.Independence.new()
var empathy = Trait.Empathy.new()
var kindness = Trait.Kindness.new()
var arrogance = Trait.Arrogance.new()
var aggressiveness = Trait.Aggressiveness.new()
# SPR -------------------------------------------------------
var happiness = Trait.Happiness.new()
var actualization = Trait.Actualization.new()
var loyalty = Trait.Loyalty.new()
# N/A -------------------------------------------------------
var openness = Trait.Openness.new()
var appetite = Trait.Appetite.new()
var sociability = Trait.Sociability.new()

var traits = [
	iq, learning, 
	size, strength, health, 
	composure, willpower, patience, 
	confidence, beauty, poise, 
	independence, empathy, kindness, 
	arrogance, aggressiveness, 
	happiness, actualization, loyalty,
	openness, appetite, sociability
]

# =========================================================== #
#                        M E T H O D S                        #
# ----------------------------------------------------------- #

func _ready(): 
	add_to_group("monsters", true)
	connect("item_rect_changed", Callable(self, "update_z"))
	set_fixed_process(true)
	update_z()
	choose_action()

# -----------------------------------------------------------

func serialize():
	var data = {
		name = name,
		species = species,
		color = color,
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

#func _init(dad, mom):
#	if dad: self.father = dad
#	if mom: self.mother = mom
#	birth()
#	pass

# -----------------------------------------------------------

func update_z():
	set_z(get_pos().y + get_item_rect().size.y)

# -----------------------------------------------------------

func highlight(): pass
#	print("i am selected!")

# -----------------------------------------------------------

func _fixed_process(delta): 
	if current_action: 
		var action_status = current_action.execute()
		if action_status == Action.FINISHED:
			_on_action_finished()
	# if !Utils.veq(get_pos(), dest): walk(dest)
	# else: wait(time)

# -----------------------------------------------------------

func birth():
	print("A NEW BABY IS BORN!")
	for trait in traits:
		trait.calc_initial_value(self)
	print("----------------------")
	pass

# -----------------------------------------------------------

func choose_action():
	# logic to select current and next action(s)
	# var stomach_priority = (max_status.stomach - status.stomach) 
	#   / (max_status.stomach * 30) * 100
	# var duration = 12
	# current_action = Action.new(Action.IDLE_ACTION, duration)
	randomize()
	current_action = Action.new(Utils.randi_range(2, 8) * 100)
	pass

# -----------------------------------------------------------

func update_status():
	# updates the pet's status meters (mood, hunger, etc)
	pass

# -----------------------------------------------------------

func update_preferences(): 
	# updates pet's likes and dislikes via discipline
	pass

# -----------------------------------------------------------

func update_attributes(): 
	# INT, VIT, CON... via all sorts of stuff
	pass

# -----------------------------------------------------------

func walk(dest):
	move(Utils.vlerp(get_pos(), dest, 0.5))

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
#	print("action finished!")
#	update_status()
#	update_attributes()
	past_actions.append(current_action)
	if past_actions.size() > 5:
		past_actions.pop_front()
	if (next_action):
		current_action = next_action
		next_action = null
	else: choose_action()

# -----------------------------------------------------------

func _on_state_changed(state):
	update_status()
	pass

# -----------------------------------------------------------
	
func _on_status_changed():
	# here we will probably have to decide if we need to
	# stop actions or enter some special state, if action
	# falls below certain trigger
	pass
