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

# movement
# --------
var mass # from entity definition
# position (Vector2): built-in property
var orientation = Vector2(0, 0) setget _update_orientation
var velocity = Vector2(0, 0) # action property?
# action properties:
# max_force (scalar), max_speed (scalar)


# =========================================================== #
#                        M E T H O D S                        #
# ----------------------------------------------------------- #

func _ready():
#	connect("draw", self, "update_z")
	Dispatcher.connect("tick_changed", self, "update_drives")
	update_z()
	$orientation.cast_to = Vector2(-0, 20)
	set_physics_process(true)
	# left: -x
	# right: +x
	# back: -y
	# front: +y

var time = 0
func _physics_process(delta):
	time += delta
	var rad = time * 2
	self.orientation = Vector2(cos(rad), sin(rad))
	if rad > 2 * PI: time = 0
	$orientation.cast_to = orientation * 20

func _update_orientation(new_o):
	var old_o = orientation
	orientation = new_o
	if old_o.ceil() != new_o.ceil(): 
		update_animation()

# -----------------------------------------------------------

func initialize(data):
	deserialize(data)
	var anim_data = Data.get([type, "morphs", morph, "animations"])
	for anim_id in anim_data: add_animation(anim_id)
	play_animation("idle")


# =========================================================== #
#                     A N I M A T I O N S                     #
# ----------------------------------------------------------- #

var current_animation

func update_animation():
	var facing = orientation.ceil()
#	$sprite/anim.current_animation = str(current_animation, "_1_0")
	var anim_pos = $sprite/anim.current_animation_position
	$sprite/anim.current_animation = str(current_animation, "_", facing.y, "_", facing.x)
	$sprite/anim.seek(anim_pos)

func play_animation(anim_id = null):
	current_animation = anim_id
	var facing = orientation.ceil()
#	$sprite/anim.play(str(anim_id, "_1_0"))
	$sprite/anim.play(str(anim_id, "_", facing.y, "_", facing.x))

# -----------------------------------------------------------

# creates four animations for a given `anim_id` - one in each
# facing direction - which are added to the AnimationPlayer
# for our sprite. the resulting animations are identified by
# a string in "{anim_id}_{y}_{x}" format, where y and x are
# either 0 or 1, and represent the monster's front-back and
# left-right orientation, respectively.
func add_animation(anim_id):
	var anims = Data.get([type, "morphs", morph, 
			"animations", anim_id])
	
	for y in anims.size():
		var anim = anims[y]
		if typeof(anim) == TYPE_ARRAY:
			for x in anim:
				create_animation(anim[x], str(anim_id, "_", y, "_", x))
		else:
			create_animation(anim, str(anim_id, "_", y, "_0"))
			create_animation(anim, str(anim_id, "_", y, "_1"), true)

# -----------------------------------------------------------

# creates an animation for a specific facing direction, using
# an `anim_info` object from the monster's data definition,
# and adds it to the AnimationPlayer for our sprite.
func create_animation(anim_info, anim_name, flip = false):
	# set the step and length parameters of the new animation
	# depending on the frame count and fps specified in the
	# data definition. the `step` parameter will determine the
	# delay between frames when we insert them.
	var anim = Animation.new()
	anim.step = 1.0 / anim_info.fps
	anim.length = anim.step * anim_info.frames
	anim.loop = anim_info.loop if anim_info.has("loop") else true
	
	# add a track to set our texture to the spritesheet
	# specified in the data definition
	anim.add_track(0)
	anim.track_set_path(0, ".:texture")
	var spritesheet = ResourceLoader.load(anim_info.sprites)
	anim.track_insert_key(0, 0.0, spritesheet)
	
	# add a track to set the hframes value of our texture
	anim.add_track(0)
	anim.track_set_path(1, ".:hframes")
	anim.track_insert_key(1, 0.0, anim_info.frames)
	
	# add a track to set whether our sprite is h-flipped (for 
	# right-facing animations without unique spritesheets).
	# the data definition can optionally also specify whether
	# the sprite should be flipped - in that case, a true value
	# for the `flip` argument will cancel it out (boolean XOR).
	var should_flip = (anim_info.flip != flip 
			if anim_info.has("flip") else flip)
	anim.add_track(0)
	anim.track_set_path(1, ".:flip_h")
	anim.track_insert_key(1, 0.0, should_flip)
	
	# add the animation track, with a keyframe for each frame
	# in the spritesheet at intervals determined by the `step`
	# parameter we calculated earlier
	anim.add_track(0)
	anim.track_set_path(2, ".:frame")
	anim.track_set_interpolation_loop_wrap(2, false)
	for frame in range(anim_info.frames + 1):
		var time = anim.step * frame
		anim.track_insert_key(2, time, frame)
	
	$sprite/anim.add_animation(anim_name, anim)

# -----------------------------------------------------------

func update_z():
	pass
	# z_index = position.y + $sprite.texture.get_height() / 2

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

# updates the pet's drive meters (mood, hunger, etc). called
# once per "tick" unit of game time (~0.5 seconds)
func update_drives(tick):
	var delta_energy = calc_energy_delta()
	energy += delta_energy
	belly += calc_belly_delta(delta_energy)
#	social += calc_social_delta()
	emit_signal("drives_changed")

# -----------------------------------------------------------

const DEFAULT_ENERGY_DECAY = -0.005 # 0.5% per tick = 6%/hr

# actions are defined with `energy_mod` values that describe
# how fast a pet loses (or recovers) energy while performing
# the action. these are in delta energy PER HOUR (positive
# for recovery, negative for drain), but since the drive is
# updated every tick, we must first translate `energy_mod`
# to its per-tick equivalent.
#
# vigor is stored as a float from 0 to 1; we translate it to
# 0 to 2 so we can use it as a multiplier. vigor has a
# positive effect on energy recovery and an INVERSE effect on
# energy drain, so we must invert the multiplier if the delta
# energy will be negative.
func calc_energy_delta():
	var action_val = (current_action.energy_mod / Time.TICKS_IN_HOUR
			if current_action else DEFAULT_ENERGY_DECAY)
	var vig_mod = traits.vigor * 2.0
	var delta_energy = 0.0
	if action_val > 0: 
		delta_energy = action_val * vig_mod
	else: 
		delta_energy = action_val * (2.0 - vig_mod)
	return delta_energy

# -----------------------------------------------------------

const BASE_BELLY_DECAY = -0.28 # full to starving in ~30h
const D_ENERGY_FACTOR = 0.5

# unlike delta energy, delta belly is always negative (pets
# recover belly in chunks, via EAT actions on food items).
#
# delta belly is modified by our appetite trait (converted to
# a multiplier, as with vigor) and our current delta energy,
# which means delta energy must always be calculated first.
#
# if delta energy is positive (recovery), our d_energy_mod
# multiplier is < 1, causing belly to drain slower; if it's
# negative, the modifier is > 1, which will drain it faster.
# we use a magic number to adjust the strength of the effect.
func calc_belly_delta(delta_energy):
	var base_rate = BASE_BELLY_DECAY
	var app_mod = traits.appetite * 2.0
	# if energy is increasing, decrease belly decay rate.
	var d_energy_mod = 1.0 - (delta_energy * D_ENERGY_FACTOR)
	var delta_belly = base_rate * app_mod * d_energy_mod
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

const SAVE_KEYS = [
	"monster_name", "type", "morph", 
	"birthday", "mother", "father",
	"traits", "preferences",
	"belly", "mood", "energy", "social",
	"past_actions", "current_action", "next_action"
]

# -----------------------------------------------------------

func serialize():
	var data = {}
	for key in SAVE_KEYS:
		data[key] = self[key]
	data.position = {x = position.x, y = position.y}
	# if we decide to use objects for traits (and attributes),
	# we will need to give them serialize methods.
#	for i in traits:
#		data.traits[i.name] = i.serialize()
	return data

# -----------------------------------------------------------

func deserialize(data):
	for key in SAVE_KEYS:
		self[key] = data[key]
	position.x = data.position.x
	position.y = data.position.y
