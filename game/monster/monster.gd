extends CharacterBody2D
class_name Monster

var entity_type = Constants.EntityType.MONSTER
var garden

signal drives_changed

const MAX_BELLY = 100.0
const MAX_ENERGY = 100.0
const MAX_SOCIAL = 100.0
const MAX_MOOD = 200.0

enum Sex { FEMALE, MALE }

var anim: AnimationPlayer
var nav: NavigationAgent2D
var sprite: Sprite2D
var shape: CollisionShape2D
# var perception: Area2D
# var vel_text: Label

# =========================================================================== #
#                             P R O P E R T I E S                             #
# --------------------------------------------------------------------------- #

# core properties
# ---------------
var id # unique id of the monster
var type # id of the monster's data definition
var monster_name # unfortunately "name" is a reserved property of Node
# id of the morph in the `morphs` object of monster's data definition.
# should be non-null
var morph
var birthday # serialized time object ({ tick, hour, day, month, year })
var sex = Sex.FEMALE

# memory
# ------
var past_actions = []
var current_action: Action
var next_action: Action # ?

# ids of action ids the monster knows.
# used for less-obvious actions like shaking trees.  pets should be able to
# learn actions by watching others do them, or by insight (low chance for the
# decider _not_ to filter out an unlearned available action, modified by iq).
#
# aside from intrisic, basic actions (idle/sleep/emote/move/eat), maybe _all_
# actions should be unlearned by default, with varying degrees of learnability?
var learned_actions = []

# drives
# ------
var belly: float = MAX_BELLY / 2.0:
	get: return belly
	set(value): belly = clamp(value, 0, MAX_BELLY)
var mood: float = MAX_MOOD / 2.0:
	get: return mood
	set(value): mood = clamp(value, 0, MAX_MOOD)
var energy: float = MAX_ENERGY / 2.0:
	get: return energy
	set(value): energy = clamp(value, 0, MAX_ENERGY)
var social: float = MAX_SOCIAL / 2.0:
	get: return social
	set(value): social = clamp(value, 0, MAX_SOCIAL)

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
	# ---
	# heritable, sticky trait governing how quickly a pet learns skills and how
	# likely it is to undertake complex actions.
	iq = 0.5,
	# accumulative trait reflecting how much a pet has learned over its lifetime.
	# exists to boost the INT attribute.
	learning = 0.0,
	
	# VIT
	# ---
	# 
	size = 0.5,
	strength = 0.5,
	vigor = 0.5,
	
	# CON
	# ---
	# governs the success of composure rolls (overcoming a mood hit).
	# increased by encouraging a pet during a composure rol or praising it after
	# a successful roll.
	composure = 0.3,
	# governs how long it takes for a pet to start suffering mood hits as a
	# result of unmet needs (drives out of equilibrium).
	# increased by correcting drives after patience procs but before a mood hit.
	patience = 0.4,
	
	# CHA
	# ---
	# governs how likely a pet is to undertake social actions (via utility mods).
	# increased by performing social actions with positive results.
	confidence = 0.4,
	# boosts CHA attribute. maybe also affects other pets' preferences.
	# heritable and can be modified (maybe temporarily) by items.
	beauty = 0.5,
	# accumulative trait. affects mood losses from social events, and mood-based
	# utility modifiers on social actions. ("A high POISE monster will be less
	# likely to take out its bad mood on others, and won't let negative inter-
	# actions affect its MOOD as much.")
	poise = 0.1,
	
	# AMI
	# ---
	# range from -1 to 1. sticky. affects preference for actions that raise or
	# lower other pets' moods.
	kindness = 0.0,
	# multiplies mood gains for actions that affect other pets' mood.
	empathy = 0.5,
	humility = 0.5,
	aggressiveness = 0.5,
	
	# SPI
	happiness = 0.5,
	loyalty = 0.5,
	actualization = 0.5,
	
	# N/A
	openness = 0.5,
	appetite = 0.5,
	pep = 0.5,
	extraversion = 0.5
}

# preferences
# -----------
var preferences = {}

# movement
# --------
var orientation = Vector2(0, 1):
	get: return orientation
	# update the AnimationPlayer's `facing` vector when our `orientation` vector
	# has changed enough to signify a new facing direction. running orientation
	# through ceil() will result in either (1, 1), (0, 1), (1, 0), or (0, 0).
	set(new_o):
		var old_o = orientation
		orientation = new_o
		if old_o.ceil() != new_o.ceil():
			anim.facing = new_o.ceil()

var desired_velocity = Vector2(0, 0) # for debugging


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready():
	motion_mode = MOTION_MODE_FLOATING
	Dispatcher.tick_changed.connect(_on_tick_changed)


# monsters must be initialized in code because they depend on data definitions
# that are loaded at runtime.  this makes storing the node's children in a
# PackedScene (monster.tscn) counter-productive, because the scene would be
# incomplete/invalid without initialization at runtime.
#
# instead, we should create the entire scene programmatically.  this allows us
# to initialize monsters in a single step with `new`, rather than having to
# instantiate an incomplete scene and then initialize it in a separate step.
#
# note: it's nicer to use vars for children because of typing, but we name them
# so other nodes can get them with `get_node`.  this is also necessary for $anim
# since it takes a NodePath to $sprite (the target of all animations).
func _init(data):
	deserialize(data)
	
	var script: Resource = get_script()
	var path: String = script.resource_path.get_base_dir()
	
	anim = load(path.path_join('anim.gd')).new()
	add_named_child(anim, 'anim')
	load_anims()
	
	sprite = load(path.path_join('sprite.gd')).new()
	sprite.texture = load('res://data/monsters/bunny/idle_front.png')
	sprite.hframes = 4
	add_named_child(sprite, 'sprite')
	
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	var size = Data.fetch([type, 'size'])
	shape.shape.radius = size
	shape.position.y -= size
	add_named_child(shape, 'shape')
	
	nav = NavigationAgent2D.new()
	nav.avoidance_enabled = true
	nav.path_desired_distance = 1.0
	nav.target_desired_distance = 1.0
	nav.path_max_distance = 1.0
	add_named_child(nav, 'nav')
	
	# debug
	for n in ['orientation', 'velocity', 'desired_velocity']:
		add_named_child(RayCast2D.new(), n)

# --------------------------------------------------------------------------- #

func add_named_child(node: Node, n: String):
	node.name = n
	add_child(node)


# =========================================================================== #
#                           M I S C   M E T H O D S                           #
# --------------------------------------------------------------------------- #

func _physics_process(delta):
	if current_action:
		current_action.proc(delta)
	
	update_z()

	# debug
	$orientation.target_position = orientation * 20
	$velocity.target_position = velocity * 20
#	$vel_text.set_text(String.num(velocity.length(), 2))
	$desired_velocity.target_position = desired_velocity * 20
	
	$orientation.visible = false
	$velocity.visible = true
	$velocity.enabled = true
	$desired_velocity.visible = true

# --------------------------------------------------------------------------- #

func _on_tick_changed():
	if current_action:
		var action_result = current_action.tick()
		update_drives(action_result)
	else: choose_action()

# --------------------------------------------------------------------------- #

# update the z-index of our sprite so that monsters appear in front of or
# behind other entities according to their y-position in the garden
func update_z():
	z_index = position.y + sprite.texture.get_height() / 2

# --------------------------------------------------------------------------- #

# debug logging, shows up in garden ui
func announce(msg):
	var l = garden.get_node('ui/log')
	l.add_text('[' + monster_name + '] ' + msg + '\n')
	l.scroll_to_line(l.get_line_count() - 1)


# =========================================================================== #
#                                A C T I O N S                                #
# --------------------------------------------------------------------------- #

func set_current_action(action, queue_current = false):
	prints('setting current action',action,queue_current)
	if current_action:
		if queue_current and !next_action:
			next_action = current_action
			next_action.status = Action.Status.PAUSED
		else:
			current_action.exit(Action.Status.FAILED)
	current_action = action
	current_action.exited.connect(_on_action_exit)

# --------------------------------------------------------------------------- #

func choose_action():
	set_current_action(Decider.choose_action(self))
	Log.info(self, '(choose_action) ' + current_action.name)

# --------------------------------------------------------------------------- #

func _on_action_exit(status):
	Log.debug(self, ['action exited with status ', status, ': ', current_action])
	current_action.exited.disconnect(_on_action_exit)
	past_actions.append(current_action)
	current_action = null
	
	if past_actions.size() > get_memory_size():
		past_actions.pop_front().queue_free()
	if next_action:
		set_current_action(next_action, false)
		next_action = null
	else:
		choose_action()

# --------------------------------------------------------------------------- #

# number of past actions to remember: 2-8 depending on pet iq.
func get_memory_size():
	return 2 + int(6.0 * traits.iq)


# =========================================================================== #
#                             A N I M A T I O N S                             #
# --------------------------------------------------------------------------- #

func load_anims():
	var anim_data = Data.fetch([type, 'morphs', morph, 'animations'])
	Log.verbose(self, ['anim data: ', anim_data])
	# TODO: handle unexpected case where there is no anim_data
	for anim_id in anim_data:
		anim.add_anim(anim_id, anim_data[anim_id])
	Log.debug(self, ['animations: ', anim.get_animation_list()])
	play_anim(Constants.Anim.IDLE)


func play_anim(anim_id, speed = 1.0, loops = 0):
	anim.set_speed_scale(speed)
	anim.play_anim(anim_id, loops)


func queue_anim(anim_id, loops = 0):
	anim.queue_anim(anim_id, loops)


func set_anim_speed(speed):
	anim.set_speed_scale(speed)


# =========================================================================== #
#                                 D R I V E S                                 #
# --------------------------------------------------------------------------- #

#const BASE_ENERGY_DECAY = -0.05 # 0.5% per tick = 6%/hr
const BASE_BELLY_DECAY = -0.28 # full to starving in ~30h
const D_ENERGY_FACTOR = 0.5

# updates the pet's drive meters (mood, belly, energy, and social).
# called once per "tick" unit of game time (~0.5 seconds).
#
# `diff` is a hash of drive names to float amounts by which to modify the drive.
# these are "base deltas", which are passed through the appropriate
# `calc_x_delta` function to compute a final delta modified by the pet's traits.
#
# there are several possible sources of drive updates:
# - action results: Action's `tick` method returns a summary of drive updates
#    generated by the action on that tick (`action_result`). actions could just
#    modify drives directly, but we should let pets handle their own affairs.
# - drive decay: the creeping hegemony of entropy. drives should decay by a
#    static base amount per tick.
# - event and interactions: basically TODO.
func update_drives(diff):
	var modded_diff = apply_drive_mods(diff if diff else {})
	energy = clamp(energy + modded_diff.energy, 0.0, MAX_ENERGY)
	belly = clamp(belly + modded_diff.belly, 0.0, MAX_BELLY)
	
	emit_signal('drives_changed')

# --------------------------------------------------------------------------- #

func apply_drive_mods(diff):
	return {
		energy = _mod_energy_delta(diff.get('energy', 0.0)),
		belly = _mod_belly_delta(diff.get('belly', 0.0)),
	}

# --------------------------------------------------------------------------- #

# given a base delta energy value (per tick), modifies it by the pet's vigor.
# vigor is stored as a float from 0 to 1; we translate it to 0 to 2 so we can
# use it as a multiplier. vigor has a positive effect on energy recovery and an
# inverse effect on energy drain, so we must invert the multiplier if the delta
# energy will be negative.
func _mod_energy_delta(base_delta: float):
	var vig_mod = traits.vigor * 2.0
	if base_delta > 0: return base_delta * vig_mod
	else: return base_delta * (2.0 - vig_mod)


# delta belly is modified by our appetite trait (converted to a multiplier, as
# with vigor) - higher appetite causes belly to drain faster and fill slower.
#
# if delta energy is positive (recovery), our d_energy_mod multiplier is < 1,
# causing belly to drain slower; if it's negative, the modifier is > 1, which
# will drain it faster. D_ENERGY_FACTOR controls the strength of the effect.
func _mod_belly_delta(base_delta: float, delta_energy: float = 0.0):
	var app_mod = traits.appetite * 2.0
	# if energy is increasing, decrease belly decay rate.
	var d_energy_mod = 1.0 - (delta_energy * D_ENERGY_FACTOR)
	var delta_belly = base_delta * app_mod * d_energy_mod
	return delta_belly


func _mod_social_delta():
	pass

# --------------------------------------------------------------------------- #

# target energy reflects the pet's preference for activity or rest, and is
# determined by the inverse of its pep trait (which ranges from 0 to 1).
# high pep & low target energy means a more active pet, and vice versa.
func get_target_energy():
	return MAX_ENERGY * (1.0 - traits.pep)

func get_target_social():
	return MAX_SOCIAL * (1.0 - traits.extraversion)


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

const SAVE_KEYS = [
	'monster_name', 'type', 'morph',
	'birthday', 'mother', 'father',
	'traits', 'preferences',
	'belly', 'mood', 'energy', 'social',
	# 'past_actions', 'current_action', 'next_action'
]

# --------------------------------------------------------------------------- #

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

# --------------------------------------------------------------------------- #

func deserialize(data):
	for key in SAVE_KEYS:
		set(key, data[key])
	position.x = data.position.x
	position.y = data.position.y
