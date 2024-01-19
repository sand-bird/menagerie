extends Entity
class_name Monster

signal drives_changed

const Anim = {
	IDLE = "idle",
	LIE_DOWN = "lie_down",
	WALK = "walk",
	SLEEP = "sleep"
}

enum Sex { FEMALE, MALE }

# child nodes
# -----------
var anim: AnimationPlayer
var nav: NavigationAgent2D
var joint: PinJoint2D
var perception: Area2D
var debug_text: Label

# =========================================================================== #
#                             P R O P E R T I E S                             #
# --------------------------------------------------------------------------- #

# core properties
# ---------------
var monster_name: String # unfortunately "name" is a reserved property of Node
# id of the morph in the `morphs` object of monster's data definition.
# should be non-null
var morph: StringName
var birthday: Dictionary # serialized time object ({ tick, hour, day, month, year })
var age: int # in ticks. tracked separately from birthday in case of time travel
var sex = Sex.FEMALE

# memory
# ------
# TODO: memory should impact preference changes when we discipline monsters.
# stuff in memory should fade at a rate determined by iq; its freshness should
# multiply changes in the pet's preference for it when we discipline the pet.
# right now memory only stores past actions, and just keeps a certain max number
# rather than expiring.
var past_actions: Array[Action] = []
var current_action: Action
var next_action: Action # ?

# ids of action ids the monster knows.
# used for less-obvious actions like shaking trees.  pets should be able to
# learn actions by watching others do them, or by insight (low chance for the
# decider _not_ to filter out an unlearned available action, modified by iq).
#
# aside from intrisic, basic actions (idle/sleep/emote/move/eat), maybe _all_
# actions should be unlearned by default, with varying degrees of learnability?
var learned_actions: Array[StringName] = []

# drives
# ------
var belly_capacity: float # in kg, depends on the monster's mass (default 10%)
var belly_energy_density: float # in kcal / kg, digestion efficiency included
var belly: float = belly_capacity / 2.0:
	set(value): belly = clamp(value, 0, belly_capacity)

var energy_capacity: float
var energy: float = energy_capacity / 2.0:
	set(value): energy = clamp(value, 0, energy_capacity)

var social_capacity: float = 100
var social: float = social_capacity / 2.0:
	set(value): social = clamp(value, 0, social_capacity)

var mood_capacity: float = 100
var mood: float = mood_capacity / 2.0:
	set(value): mood = clamp(value, 0, mood_capacity)


# personality
# -----------
var attributes: Attributes

# preferences
# -----------
var preferences = {}

# movement
# --------
var orientation = Vector2(0, 1):
	# update the AnimationPlayer's `facing` vector when our `orientation` vector
	# has changed enough to signify a new facing direction. running orientation
	# through ceil() will result in either (1, 1), (0, 1), (1, 0), or (0, 0).
	set(new_o):
		var old_o = orientation
		orientation = new_o
		# anim is null the first time we set orientation, since we need to
		# deserialize before initializing children
		if old_o.ceil() != new_o.ceil() and anim != null:
			anim.facing = new_o.ceil()

var desired_velocity = Vector2(0, 0) # for debugging
var velocity = Vector2(0, 0)

func debug_vectors():
	var vecs = {
		vec_to_grabbed = [Color(0, 1, 0), func (): return vec_to_grabbed() * 5]
#		desired_velocity = [Color(0, 0, 1), func (): return desired_velocity],
#		velocity = [Color(1, 1, 0), func (): return velocity],
	}
	vecs.merge(super.debug_vectors())
	return vecs


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready():
	joint.node_a = get_path()
	Dispatcher.tick_changed.connect(_on_tick_changed)
	body_entered.connect(_on_collide)

# --------------------------------------------------------------------------- #

# monsters must be initialized in code because they depend on data definitions
# that are loaded at runtime.  this makes storing the node's children in a
# PackedScene (monster.tscn) counter-productive, because the scene would be
# incomplete/invalid without initialization at runtime.
#
# instead, we should create the entire scene programmatically.  this allows us
# to initialize monsters in a single step with `new`, rather than having to
# instantiate an incomplete scene and then initialize it in a separate step.
func _init(data_: Dictionary, garden_: Garden):
	super(data_, garden_)
	
	inertia = 10
	
	# check when we hit something so we can grab it
	max_contacts_reported = 1
	contact_monitor = true
	
	var script: Resource = get_script()
	var path: String = script.resource_path.get_base_dir()
	
	anim = load(path.path_join('anim.gd')).new()
	add_named_child(anim, 'anim')
	load_anims()

	nav = NavigationAgent2D.new()
#	nav.debug_enabled = true
	nav.radius = size
	nav.neighbor_distance = 500
	nav.avoidance_enabled = false
	nav.path_desired_distance = sqrt(size)
	nav.target_desired_distance = sqrt(size)
	nav.path_max_distance = size
	add_named_child(nav, 'nav')
	
	perception = Area2D.new()
	var perception_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 100
	perception_shape.shape = circle
	perception.add_child(perception_shape)
	add_named_child(perception, 'perception')
	
	joint = PinJoint2D.new()
	joint.softness = 0
#	joint.length = 1
#	joint.damping = 1
#	joint.bias = 0.9
	# for now, put the joint at the center of the collision shape
	add_named_child(joint, 'joint')
	
	debug_text = Label.new()
	debug_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_text.size.x = 64
	debug_text.position = Vector2(-32, 4)
	add_named_child(debug_text, 'debug_text')


# =========================================================================== #
#                           M I S C   M E T H O D S                           #
# --------------------------------------------------------------------------- #

func _physics_process(delta):
	super._physics_process(delta)
	if current_action:
		current_action.proc(delta)
	if is_grabbing() and vec_to_grabbed().length_squared() > (100 ** 2):
		release("was forced to let go of ")

# --------------------------------------------------------------------------- #

func _on_collide(_node: Node2D): pass

# --------------------------------------------------------------------------- #

func _on_tick_changed():
	age += 1
	metabolize()
	if current_action:
		debug_text.text = current_action.name
		current_action.tick()
	else: choose_action()

# --------------------------------------------------------------------------- #

# debug logging, shows up in garden ui
func announce(msg):
	var l = garden.get_node('ui/log')
	l.add_text('[' + monster_name + '] ' + msg + '\n')
	l.scroll_to_line(l.get_line_count() - 1)

# --------------------------------------------------------------------------- #

func get_display_name():
	return monster_name


# =========================================================================== #
#                               G R A B B I N G                               #
# --------------------------------------------------------------------------- #

var can_grab: bool = true

func disable_grab(cooldown: float = 10):
	can_grab = false
	get_tree().create_timer(cooldown).timeout.connect(enable_grab)

func enable_grab(): can_grab = true

# --------------------------------------------------------------------------- #

func grab(node: Entity):
	joint.node_b = node.get_path()
	announce(str("is grabbing ", get_grabbed_name()))

func release(msg: String = "released "):
	announce(msg + get_grabbed_name())
	joint.node_b = ""
	disable_grab()

# --------------------------------------------------------------------------- #

var grabbed: Entity:
	get: return get_node(joint.node_b) if is_grabbing() else null
	set(_x): return

func get_grabbed_name():
	return (
		"[NONE]" if grabbed == null else
		str("[", grabbed.monster_name, "]") if grabbed is Monster
		else str(grabbed.type)
	)

# if target is passed, returns true only if the monster is grabbing the target;
# if not, returns true if the monster is grabbing anything.
func is_grabbing(target = null):
	return (
		joint.node_b != NodePath("") and has_node(joint.node_b)
		and (!target or target == grabbed)
	)

func vec_to_grabbed() -> Vector2:
	return grabbed.position - position if grabbed != null else Vector2(0, 0)


# =========================================================================== #
#                                A C T I O N S                                #
# --------------------------------------------------------------------------- #

func set_current_action(action, queue_current = false):
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
	# TODO: we should just serialize them now, instead of keeping references
	# to action objects around
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
	return attributes.iq.ilerp(2, 8)


# =========================================================================== #
#                             A N I M A T I O N S                             #
# --------------------------------------------------------------------------- #

var morph_anims: Dictionary:
	get: return Data.fetch([type, 'morphs', morph, 'animations'])

# get the anim_info dict for a particular key and facing.
# uses the current values from $anim if arguments are null.
func get_sprite_info(_key = null, _facing = null) -> Dictionary:
	var key = _key if _key != null else anim.current
	var facing = _facing if _facing != null else anim.facing
	var anim_data = morph_anims.get(key, morph_anims.get('idle'))
	return anim.get_anim_info_for_facing(anim_data, facing)

# --------------------------------------------------------------------------- #

func load_anims():
	Log.verbose(self, ['morph anim data: ', morph_anims])
	# TODO: handle unexpected case where there is no anim_data
	for anim_id in morph_anims:
		anim.add_anim(anim_id, morph_anims[anim_id])
	Log.debug(self, ['animations: ', anim.get_animation_list()])
	play_anim(Anim.IDLE)

# --------------------------------------------------------------------------- #

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

# sugar for calling individual `update_x` methods
# TODO: emit signal
func update_drive(drive: StringName, delta: float) -> void:
	if not drive in Action.DRIVES:
		Log.error(self, ['called `estimate_drive` with an invalid drive: ', drive])
		return
	call(str('update_', drive), delta)

func update_drives(drive_diff: Dictionary) -> void:
	for drive in drive_diff: update_drive(drive, drive_diff[drive])

# --------------------------------------------------------------------------- #

# "energy" represents both literal stored calories and the abstract concept of
# vital energy.  thus energy changes are modified by vigor (physical fitness);
# pets with higher vigor use less energy to perform the same amount of activity
# as those with lower vigor, and can extract more energy from what they eat
# because their digestive processes are more efficient.
#
# the default vigor multiplier scale is 2, meaning maximum and minimum vigor
# will double or halve energy recovery, respectively (and vice versa for energy
# drain), but this can be tweaked using the second parameter.
func update_energy(delta: float, vigor_mod_scale: float = 2):
	energy += attributes.vigor.modify(delta, vigor_mod_scale)

# --------------------------------------------------------------------------- #

# note: appetite was originally supposed to modify delta belly in the same way
# that vigor modifies delta energy.  however, the current plan is for `belly` to
# represent the actual mass of the food which the monster has eaten but not yet
# digested, so it might be weird for appetite to modify that.
#
# appetite should still modify the capacity (max size) of the belly, and it can
# also modify the rate of digestion (more appetite means food digests faster).
func update_belly(delta: float, appetite_mod_scale: float = 1):
	# high appetite decreases filling and increases drain, and vice versa.
	belly += attributes.appetite.modify(delta, appetite_mod_scale, true)

# --------------------------------------------------------------------------- #

func update_social(delta: float, confidence_mod_scale: float = 2):
	# high confidence increases social gain and decreases loss, and vice versa.
	social += attributes.confidence.modify(delta, confidence_mod_scale)

# --------------------------------------------------------------------------- #

func update_mood(delta: float): mood += delta

# --------------------------------------------------------------------------- #

# target energy reflects the pet's preference for activity or rest, and is
# determined by the inverse of its pep attribute (which ranges from 0 to 1).
# high pep & low target energy means a more active pet, and vice versa.
func get_target_energy():
	return energy_capacity * attributes.pep.lerp(1, 0)

func get_target_social():
	return social_capacity * attributes.extraversion.lerp(1, 0)


# =========================================================================== #
#                             M E T A B O L I S M                             #
# --------------------------------------------------------------------------- #
# note: this is a lot of numbers to calibrate when creating a monster:
# - belly size (some fraction of mass)
# - digestion speed (some fraction of belly size? could also be function of BMR)
# - basal metabolic rate (function of mass)
# might be easier to have broader levers for these in data defs as enums rather
# than hard values, eg belly size is small/medium/large, bmr slow/medium/fast,
# etc.  the main concern is that the monster's ideal diet should always be able
# to provide it with enough energy - maybe we can ensure this somehow?

"""
further note on simulating digestion speed:

digestion speed in real life is measured as a) time to absorb nutrients (eg ~4
hours for a human to absorb glucose, depending on particle size) and b) time to
pass the indigestible matter all the way through and out the other end.

in other words, digestion speed depends on the contents of the belly, not just
their energy density - a belly full of pure glucose should theoretically take 4h
to digest (and yield very little poop, only what the body couldn't metabolize).

so the solution may be to (again) deepen the simulation: track the mass of each
energy source consumed in addition to the total mass.  on each tick, metabolize
(consume) an appropriate amount of each energy source, then "age" the rest.

how do we model stomach contents if they can comprise several different meals at
different times? maybe we just store each meal in the belly (combining multiple
bites from one eat action into a single meal), and digest each one accordingly
on each tick.
"""

# handle the monster's ongoing biological processes:
# - consume energy in proportion to the monster's basal metabolic rate
# - digest food:
#   - empty the belly
#   - produce energy
#   - update the nutrition attribute
# note that if the monster is asleep, we should reduce energy consumption.
# (not how BMR is supposed to work, but we can treat it as more of a "default"
# metabolic rate, and a monster's default state is awake)
func metabolize() -> void:
	const TICKS_PER_DAY = Clock.TICKS_IN_HOUR * Clock.HOURS_IN_DAY # 288
	var energy_upkeep = U.div(get_bmr(), TICKS_PER_DAY) / 3 # 1.5 for bunny
	# bunny belly cap is 0.3 kg, so amount to digest ~= 0.001 kg.
	var amount_to_digest = min(U.div(belly_capacity * 2, TICKS_PER_DAY), belly)
	# energy density of apple is 127.6 kcal / 0.2 kg = 638 kcal / kg.
	# yield for 0.001 kg = 0.6646
	var energy_yield = amount_to_digest * belly_energy_density
	update_belly(-amount_to_digest)
	update_energy(energy_yield - energy_upkeep)

# --------------------------------------------------------------------------- #

# returns the monster's base metabolic rate in kcal per day.
# if the data doesn't define a metabolic rate, calculate it using our mass and
# an "average" mass-specific metabolic rate of 7.
# we may be able to come up with a better average based on tags - eg, average
# mass-specific BMR for birds is 20+, while for reptiles it's less than 1.
func get_bmr() -> float:
	return data.get(&'metabolic_rate', mass * 7 * 20.65)

# --------------------------------------------------------------------------- #

const DEFAULT_ENERGY_SOURCE_EFFICIENCY = {
	protein = 1.0, carbs = 1.0, fat = 1.0,
	fiber = 0.1, mana = 0.0, light = 0.0
}
func get_energy_source_efficiency():
	var e = data.get(&'energy_source_efficiency', {})
	e.merge(DEFAULT_ENERGY_SOURCE_EFFICIENCY)
	return e


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
# see the `serialize` & `deserialize` functions on the parent class, Entity.
# `deserialize` is called from the Entity constructor, and `serialize` is
# called from the garden's `serialize` method.

# list of property names to persist and load.
# overrides `Entity.save_keys`, which returns the generic keys shared by all
# entities (uuid, type, and - for now - position).
# order matters for deserialization; some properties depend on others earlier
# in the list to already be loaded or generated (especially `type`).  this is
# why we start with the keys from `super` (Entity) and append our own keys.
func save_keys() -> Array[StringName]:
	var keys = super.save_keys()
	keys.append_array([
		&'sex', &'monster_name', &'morph', &'birthday', &'age', &'attributes',
		&'belly', &'mood', &'energy', &'social',
		&'orientation',
		# TODO: 'preferences',
		# TODO: 'past_actions', 'current_action', 'next_action', 'learned_actions'
	])
	return keys

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

func load_orientation(input):
	orientation = U.parse_vec(input, Vector2(1, 0))

func load_attributes(input):
	if not input is Dictionary: input = {}
	var attribute_overrides = Data.fetch([type, &'attributes'], {})
	attributes = Attributes.new(input, attribute_overrides)
	# initialize stateless propreties which depend on attributes (and data)
	belly_capacity = attributes.appetite.modify(
		data.get(&'belly_capacity', data.mass * 0.1), 2
	)
	energy_capacity = attributes.pep.modify(get_bmr() * 2, 2)
	social_capacity = attributes.extraversion.modify(100, 2)

# ideally we would fail to load a monster with an invalid morph.  i'm not sure
# how to fail out of the constructor though, so for now just pick a valid one
func load_morph(input):
	if Data.missing([type, &'morphs', input]): input = generate_morph()
	morph = input

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #

func generate_type(): return Data.by_type.monster.pick_random()
func generate_sex():
	return Sex.FEMALE if randf() < data.get(&'gender_ratio', 0.5) else Sex.MALE
# TODO: take into account condition and weight
func generate_morph(): return data.morphs.keys().pick_random()
func generate_birthday(): return Clock.get_dict()
func generate_age(): return 0

func generate_monster_name():
	var names = preload("res://addons/randomnamesgenerator/names_in_arrays.gd")
	return (
		names.v_RWFemaleFirstNames if sex == Sex.FEMALE
		else names.v_RWMaleFirstNames
	).pick_random()
