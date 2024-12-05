class_name Monster
extends Entity

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
# belly is in kg (like mass)
var belly_capacity: float: # depends on mass and belly_size from data
	set(value):
		belly_capacity = value
		belly = minf(belly, belly_capacity)
var belly: float = belly_capacity:
	set(value): belly = clampf(value, 0, belly_capacity)
var target_belly: float:
	get: return belly_capacity
	set(_x): return

# nutrition sources, catabolized into energy per tick
var porps: float = 0: # protein
	set(value): porps = maxf(0, value)
var scoses: float = 0: # carbs
	set(value): scoses = maxf(0, value)
var fobbles: float = 0: # fats
	set(value): fobbles = maxf(0, value)
var lumens: float = 0: # sunlight
	set(value): lumens = maxf(0, value)

# energy is in "kcal"
var energy_capacity: float: # depends on mass and metabolism rate
	set(value):
		energy_capacity = value
		energy = minf(energy, energy_capacity)
var energy: float = energy_capacity:
	set(value): energy = clampf(value, 0, energy_capacity)
# target energy reflects the pet's preference for activity or rest, and is
# determined by the inverse of its pep attribute (which ranges from 0 to 1).
# high pep & low target energy means a more active pet, and vice versa.
var target_energy: float:
	get: return energy_capacity * attributes.pep.lerp(0.8, 0.2)
	set(_x): return

var social_capacity: float = 100:
	set(value):
		social_capacity = value
		social = minf(social, social_capacity)
var social: float = social_capacity:
	set(value): social = clampf(value, 0, social_capacity)
var target_social: float:
	get: return social_capacity * attributes.extraversion.lerp(1, 0)
	set(_x): return

var mood_capacity: float = 100:
	set(value):
		mood_capacity = value
		mood = minf(mood, mood_capacity)
var mood: float = mood_capacity:
	set(value): mood = clampf(value, 0, mood_capacity)
var target_mood: float:
	get: return mood_capacity
	set(_x): return

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
		vec_to_grabbed = [Color(0, 1, 0), func (): return vec_to_grabbed()]
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
	Dispatcher.hour_changed.connect(debug_energy_spend)
	body_entered.connect(_on_collide)


var last_energy: float = energy
func debug_energy_spend():
	Log.debug(self, ['===== energy spent (', id, '): ', last_energy - energy, ' ====='])
	last_energy = energy

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
	nav.debug_enabled = true
	nav.radius = size
	nav.neighbor_distance = 500
	nav.avoidance_enabled = false
	nav.path_desired_distance = size
	nav.target_desired_distance = size
	nav.path_max_distance = size
	add_named_child(nav, 'nav')
	
	perception = Area2D.new()
	var perception_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 100
	perception_shape.shape = circle
	perception.add_child(perception_shape)
	add_named_child(perception, 'perception')
	perception.hide()
	
	joint = PinJoint2D.new()
	joint.softness = 0
#	joint.length = 1
#	joint.damping = 1
#	joint.bias = 0.9
	# for now, put the joint at the center of the collision shape
	add_named_child(joint, 'joint')
	
	debug_text = Label.new()
	debug_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	else: await choose_action()

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
		else str(grabbed.id)
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
	set_current_action(await Decider.choose_action(self))
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
		await choose_action()

# --------------------------------------------------------------------------- #

# number of past actions to remember: 2-8 depending on pet iq.
func get_memory_size():
	return attributes.iq.ilerp(2, 8)

# --------------------------------------------------------------------------- #

# note: `is_sleeping` is already a method on RigidBody2D
func is_asleep(): return (
	current_action is SleepAction
	and current_action.status == Action.Status.RUNNING
)


# =========================================================================== #
#                             A N I M A T I O N S                             #
# --------------------------------------------------------------------------- #

var morph_anims: Dictionary:
	get: return Data.fetch([id, 'morphs', morph, 'animations'])

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

# pets with higher vigor use less energy to perform the same amount of activity
# as those with lower vigor, and can extract more energy from stored energy
# sources.  the default vigor multiplier scale is 2, meaning maximum and minimum
# vigor will double or halve energy recovery, respectively (and vice versa for
# energy drain), but this can be tweaked using the second parameter.
func update_energy(delta: float, vigor_mod_scale: float = 2):
	energy += attributes.vigor.modify(delta, vigor_mod_scale)

# --------------------------------------------------------------------------- #

# belly changes are modified by appetite in the same way that energy is modified
# by vigor, but inverted, so that higher appetite values will increase belly
# loss (causing the pet to become hungry faster) by up to 2x, and decrease gain
# (causing it to be less sated when it eats food) by up to half.
func update_belly(delta: float, appetite_mod_scale: float = 2):
	belly += attributes.appetite.modify(delta, appetite_mod_scale, true)

# --------------------------------------------------------------------------- #

# high confidence increases social gain and decreases loss, and vice versa.
func update_social(delta: float, confidence_mod_scale: float = 2):
	social += attributes.confidence.modify(delta, confidence_mod_scale)

# --------------------------------------------------------------------------- #

# mood is unmodified by attributes (for now)
func update_mood(delta: float): mood += delta


# =========================================================================== #
#                             M E T A B O L I S M                             #
# --------------------------------------------------------------------------- #

# amount of energy each unit of each energy source is worth
const energy_source_values = {
	porps = 4.0, scoses = 3.0, fobbles = 9.0, lumens = 2.0
}
# handle the monster's ongoing biological processes:
# - digest food, reducing `belly` (eventually we should turn this into poop)
# - catabolize stored energy (porps/scoses/fobbles/lumens)
# - burn energy for metabolism
func metabolize() -> void:
	var belly_attrition = (belly_capacity / 300.0)
	update_belly(-belly_attrition)
	
	# decay (catabolize) energy sources and calculate the total energy yield
	var food_energy := 0.0
	for source in energy_source_values:
		# TODO: maybe vary decay rate by energy source (eg fobbles decay slower)
		var decay_amount = get(source) * 0.05
		self[source] -= decay_amount
		food_energy += decay_amount * energy_source_values[source]
	# cap usable food energy by a portion of the monster's mass.
	# anything over this amount is wasted.
	var max_food_energy := mass ** 0.8 # why not
	var scale := clampf(food_energy / max_food_energy, 0, 1)
	# the multiplier needs to dip below 0 to force monsters with no food energy
	# reserves out of energy equilibrium - otherwise, they may get stuck in an
	# idle loop.  we can always still recover energy by sleeping.
	var multiplier := lerpf(-0.2, 1.5, scale)
	# TODO: DRY this (also used in SleepAction)
	var base_energy_recovery := energy_capacity / 200.0
	var energy_recovery := base_energy_recovery * multiplier
	
	prints('(metabolize) recovery:', U.str_num(energy_recovery),
		'| total:', U.str_num(food_energy),
		'| max:', U.str_num(max_food_energy),
		'| monster:', id, monster_name)
	update_energy(energy_recovery)


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
# see the `serialize` & `deserialize` functions on the parent class, Entity.
# `deserialize` is called from the Entity constructor, and `serialize` is
# called from the garden's `serialize` method.

# list of property names to persist and load.
# overrides `Entity.save_keys`, which returns the generic keys shared by all
# entities (uuid, id, and - for now - position).
# order matters for deserialization; some properties depend on others earlier
# in the list to already be loaded or generated (especially id`).  this is
# why we start with the keys from `super` (Entity) and append our own keys.
func save_keys() -> Array[StringName]:
	var keys = super.save_keys()
	keys.append_array([
		&'sex', &'monster_name', &'morph', &'birthday', &'age',
		&'attributes',
		&'belly', &'mood', &'energy', &'social',
		&'scoses', &'porps', &'fobbles', &'lumens',
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
	var attribute_overrides = data.get(&'attributes', {})
	attributes = Attributes.new(input, attribute_overrides)
	# initialize stateless propreties which depend on attributes (and data)
	belly_capacity = attributes.appetite.modify(
		data.get(&'belly_capacity', data.mass * 0.1), 2
	)
	energy_capacity = attributes.pep.modify(data.mass * 10, 2)
	social_capacity = attributes.extraversion.modify(100, 2)

# ideally we would fail to load a monster with an invalid morph.  i'm not sure
# how to fail out of the constructor though, so for now just pick a valid one
func load_morph(input):
	if Data.missing([id, &'morphs', input]): input = generate_morph()
	morph = input

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #

func generate_id(): return Data.by_type.monster.pick_random()
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

# start the monster off with full drives
func generate_belly(): return belly_capacity
func generate_energy(): return energy_capacity
func generate_mood(): return mood_capacity
func generate_social(): return social_capacity
