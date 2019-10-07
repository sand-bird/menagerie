extends KinematicBody2D

class_name Monster

#warning-ignore-all:unused_class_variable

var entity_type = Constants.EntityType.MONSTER
var garden

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
var mass = 40 # from entity definition
# position (Vector2): built-in property
var orientation = Vector2(0, 1) setget _update_orientation
# action properties:
# max_force (scalar), max_speed (scalar)

var collider # whatever we're about to hit next
var collision # whatever we've just hit

var destination
var max_speed = 20
var max_velocity = 0.5
var current_velocity = Vector2(0, 0)
var desired_velocity = Vector2(0, 0)
var arrival_radius = max_velocity * 4

var points = []
var next_point = 0

var dest

# =========================================================== #
#                        M E T H O D S                        #
# ----------------------------------------------------------- #

func _ready():
	Dispatcher.connect('tick_changed', self, '_update_drives', [])
	update_z()
	set_physics_process(true)
	choose_action()

# -----------------------------------------------------------

func get_position():
	return Vector2(
		position.x + $shape.shape.radius,
		position.y + $shape.shape.radius
	)

func set_position(pos):
	position.x = pos.x - $shape.shape.radius
	position.y = pos.y - $shape.shape.radius

# -----------------------------------------------------------

func initialize(data):
	deserialize(data)
	var size = Data.get([type, 'size'])
	$shape.shape.radius = size
	$shape.position.y -= size
	var anim_data = Data.get([type, 'morphs', morph, 'animations'])
	if anim_data:
		for anim_id in anim_data: $sprite/anim.add_anim(anim_id, anim_data[anim_id])
		play_animation(Constants.Anim.LIE_DOWN)
		queue_animation(Constants.Anim.SLEEP)

func play_animation(anim_id, loops = 0):
	$sprite/anim.play_anim(anim_id, loops)

func queue_animation(anim_id, loops = 0):
	$sprite/anim.queue_anim(anim_id, loops)

# -----------------------------------------------------------

# (temp) spin our monster to check that animations correctly
# update when facing direction changes
var time = 0
func _physics_process(delta):
	if !current_action or current_action.tick() != Constants.ActionStatus.RUNNING:
		choose_action()
	current_action.tick()
	time += delta

	$orientation.cast_to = orientation * 20
	$velocity.cast_to = current_velocity * 20
	$desired_velocity.cast_to = desired_velocity * 20
	position += current_velocity

#	var rad = time * 2
#	self.orientation = Vector2(cos(rad), sin(rad))
#	if rad > 2 * PI: time = 0
#	$orientation.cast_to = orientation * 20
#	if dest and position.distance_squared_to(dest) > 5:
#		move_and_slide((dest - position).normalized() * 40)
#	else:
#		dest = null

# -----------------------------------------------------------

# update the AnimationPlayer's `facing` vector when our
# `orientation` vector has changed enough to signify a new
# facing direction. running orientation through ceil() will
# result in either (1, 1), (0, 1), (1, 0), or (0, 0).
func _update_orientation(new_o):
	var old_o = orientation
	orientation = new_o
	if old_o.ceil() != new_o.ceil():
		$sprite/anim.facing = new_o.ceil()

# -----------------------------------------------------------

# update the z-index of our sprite so that monsters appear
# in front of or behind other entities according to their
# y-position in the garden
func update_z():
	pass
	# z_index = position.y + $sprite.texture.get_height() / 2

# -----------------------------------------------------------

func choose_action():
	current_action = Action.Walk.new(self, Vector2(0, 0))
#	randomize()
#	if randf() < 0.5:
#		current_action = Action.Move.new(self, Vector2(Utils.randi_to(200), Utils.randi_to(100)), 10)
#	else:
#		current_action = Action.Sleep.new(self, Utils.randi_range(1000, 5000))
	print("chose action: ", current_action)


# =========================================================== #
#                         D R I V E S                         #
# ----------------------------------------------------------- #

# updates the pet's drive meters (mood, hunger, etc). called
# once per "tick" unit of game time (~0.5 seconds)
func _update_drives() -> void:
	var delta_energy = calc_energy_delta()
	energy += delta_energy
	belly += calc_belly_delta(delta_energy)
#	social += calc_social_delta()
	emit_signal('drives_changed')

# -----------------------------------------------------------

const DEFAULT_ENERGY_DECAY = -0.005 # 0.5% per tick = 6%/hr

# actions are defined with `energy_cost` values that describe
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
	var has_energy_cost = current_action and 'energy_cost' in current_action
	var action_val = (current_action.energy_cost / Time.TICKS_IN_HOUR
			if has_energy_cost else DEFAULT_ENERGY_DECAY)
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
# D_ENERGY_FACTOR controls the strength of the effect.
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

func update_preferences(discipline_type):
	print(discipline_type)
	# updates pet's likes and dislikes via discipline
	pass

# -----------------------------------------------------------

func update_mood(discipline_type):
	print(discipline_type)
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
	update_mood(discipline_type)

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
	'monster_name', 'type', 'morph',
	'birthday', 'mother', 'father',
	'traits', 'preferences',
	'belly', 'mood', 'energy', 'social',
	'past_actions', 'current_action', 'next_action'
]

# -----------------------------------------------------------

func serialize():
	var data = {}
	for key in SAVE_KEYS:
		data[key] = get(key)
	data.position = {x = position.x, y = position.y}
	# if we decide to use objects for traits (and attributes),
	# we will need to give them serialize methods.
#	for i in traits:
#		data.traits[i.name] = i.serialize()
	return data

# -----------------------------------------------------------

func deserialize(data):
	for key in SAVE_KEYS:
		set(key, data[key])
	position.x = data.position.x
	position.y = data.position.y
