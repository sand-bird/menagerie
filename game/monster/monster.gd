extends KinematicBody2D

var entity_type = Constants.EntityType.MONSTER

signal drives_changed

# =========================================================== #
#                     P R O P E R T I E S                     #
# ----------------------------------------------------------- #

var id
var monster_name
var type
var morph
var birthday
var mother
var father
#var facing = "front"

# memory
# ------
var past_actions = []
var current_action
var next_action

# drives  
# ------
var belly
var mood
var energy
var social


# personality
# -----------
var attributes = {
	intelligence = 0,
	vitality = 0,
	constitution = 0,
	charm = 0,
	amiability = 0,
	spirit = 0
}
var traits = {
	# INT
	iq = 0,
	learning = 0,
	# VIT
	size = 0,
	strength = 0,
	vigor = 0,
	# CON
	composure = 0,
	patience = 0,
	# CHA
	confidence = 0,
	beauty = 0,
	poise = 0,
	# AMI
	kindness = 0,
	empathy = 0,
	humility = 0,
	aggressiveness = 0,
	# SPI
	happiness = 0,
	loyalty = 0,
	actualization = 0,
	# N/A
	openness = 0,
	appetite = 0,
	pep = 0,
	sociability = 0
}

# preferences
# -----------
var preferences = {}


# =========================================================== #
#                        M E T H O D S                        #
# ----------------------------------------------------------- #

func _ready():
#	connect("draw", self, "update_z")
	Dispatcher.connect("tick_changed", self, "update_drives")
	update_z()

# -----------------------------------------------------------

#func play_animation(anim_id):
#	if !$sprite/anim.has_animation(anim_id + "_" + facing):
#		add_animation(anim_id, facing)
#	$sprite/anim.play(anim_id + "_" + facing)

# -----------------------------------------------------------

func initialize(data):
	deserialize(data)
	var anim_data = Data.get([type, "morphs", morph, "animations"])
	for anim in anim_data:
		add_animation(anim, "front")
		add_animation(anim, "back")
	
	$sprite/anim.play("idle_front", 5.0)
	$sprite/anim.play("walk_front")

# -----------------------------------------------------------

func add_animation(anim_id, facing):
	var anim_info = Data.get([type, "morphs", morph, 
			"animations", anim_id, facing])
#	$sprite_old.hframes = anim_info.frames
#	$sprite_old.texture = spritesheet

	var anim = Animation.new()
	anim.step = 1.0 / anim_info.fps
	anim.length = anim.step * anim_info.frames
	anim.loop = anim_info.loop if anim_info.has("loop") else true
	
	anim.add_track(0)
	anim.track_set_path(0, ".:texture")
	var spritesheet = ResourceLoader.load(anim_info.sprites)
	anim.track_insert_key(0, 0.0, spritesheet)
	
	anim.add_track(0)
	anim.track_set_path(1, ".:hframes")
	anim.track_insert_key(1, 0.0, anim_info.frames)
	
	anim.add_track(0)
	anim.track_set_path(2, ".:frame")
	anim.track_set_interpolation_loop_wrap(2, false)
	for frame in range(anim_info.frames + 1):
		var time = anim.step * frame
		anim.track_insert_key(2, time, frame)
	
	$sprite/anim.add_animation(anim_id + "_" + facing, anim)

# -----------------------------------------------------------

func update_z():
	pass
	# z_index = position.y + $sprite.texture.get_height() / 2

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


# =========================================================== #
#                         D R I V E S                         #
# ----------------------------------------------------------- #

func update_drives(tick):
	# updates the pet's drive meters (mood, hunger, etc)
	var delta_energy = calc_energy_delta()
	energy += delta_energy
	belly += calc_belly_delta(delta_energy)
#	social += calc_social_delta()
	emit_signal("drives_changed")

# -----------------------------------------------------------

func calc_energy_delta():
	var action_val = (current_action.energy_mod / 12.0
			if current_action else -0.005)
	var vig_mod = traits.vigor * 2
	var delta_energy = 0.0
	if action_val > 0: 
		delta_energy = action_val * vig_mod
	else: 
		delta_energy = action_val * (2.0 - vig_mod)
	return delta_energy

# -----------------------------------------------------------

func calc_belly_delta(delta_energy):
	var base_rate = -0.28 # full to starving in ~30h
	var app_mod = traits.appetite * 2.0
	# if energy is increasing, decrease belly decay rate.
	# divide by max energy, then factor in a multiplier
	var energy_mod = 1 - ((delta_energy / 100.0) * 50.0)
	var delta_belly = base_rate * app_mod * energy_mod
	return delta_belly

# -----------------------------------------------------------

func calc_social_delta():
	pass

# -----------------------------------------------------------

func update_preferences(): 
	# updates pet's likes and dislikes via discipline
	pass

# -----------------------------------------------------------

func update_attributes(): 
	# INT, VIT, CON... these are supposed to depend directly
	# on the traits that feed into them
	pass


# =========================================================== #
#                    I N T E R A C T I O N                    #
# ----------------------------------------------------------- #

func highlight():
	# possibly a third (or rather first) interaction state:
	# the highlight, for when the cursor is in "snapping"
	# range of the monster but the focus delay hasn't elapsed
	# yet (or for players using a "careful" (or whatever) 
	# targeting scheme, where they must press action to focus
	# and then again to select)
	print("hi im highlighted")
	pass

# -----------------------------------------------------------

func focus():
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

func select():
	# touch: second tap
	# gamepad: push select button; mouse: click
	
	# hud: show interaction buttons
	pass

# -----------------------------------------------------------

func unfocus():
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


# =========================================================== #
#                  S E R I A L I Z A T I O N                  #
# ----------------------------------------------------------- #

func serialize():
	var keys = [
		"monster_name", "type", "morph", 
		"birthday", "mother", "father",
		"traits", "preferences",
		"belly", "mood", "energy", "social",
		"past_actions", "current_action", "next_action"
	]
	var data = {}
	for key in keys:
		data[key] = self[key]
	data.position = {x = position.x, y = position.y}
	# if we decide to use objects for traits (and attributes),
	# we will need to give them serialize methods.
#	for i in traits:
#		data.traits[i.name] = i.serialize()
	return data

# -----------------------------------------------------------

func deserialize(data):
	var keys = [
		"monster_name", "type", "morph", 
		"birthday", "mother", "father",
		"traits", "preferences",
		"belly", "mood", "energy", "social",
		"past_actions", "current_action", "next_action"
	]
	for key in keys:
		self[key] = data[key]
	position.x = data.position.x
	position.y = data.position.y
