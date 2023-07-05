extends Entity
class_name Monster

# TODO: remove. this is currently used for the garden's "select hud".
# we should rewrite that component to add different child nodes based on the
# target's class instead.
const entity_type = Constants.EntityType.MONSTER

signal drives_changed

const MAX_BELLY = 100.0
const MAX_ENERGY = 100.0
const MAX_SOCIAL = 100.0
const MAX_MOOD = 200.0

enum Sex { FEMALE, MALE }

# child nodes
# -----------
var anim: AnimationPlayer
var nav: NavigationAgent2D
var joint: PinJoint2D
# var perception: Area2D
# var vel_text: Label

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
var belly: float = MAX_BELLY / 2.0:
	set(value): belly = clamp(value, 0, MAX_BELLY)
var mood: float = MAX_MOOD / 2.0:
	set(value): mood = clamp(value, 0, MAX_MOOD)
var energy: float = MAX_ENERGY / 2.0:
	set(value): energy = clamp(value, 0, MAX_ENERGY)
var social: float = MAX_SOCIAL / 2.0:
	set(value): social = clamp(value, 0, MAX_SOCIAL)

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
func _init(_data: Dictionary, _garden: Garden):
	super(_data, _garden)
	
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
	var size = data.size
	nav.radius = size
	nav.neighbor_distance = 500
	nav.avoidance_enabled = false
	nav.path_desired_distance = sqrt(size)
	nav.target_desired_distance = sqrt(size)
	nav.path_max_distance = size
	add_named_child(nav, 'nav')
	
	joint = PinJoint2D.new()
	joint.softness = 0
#	joint.length = 1
#	joint.damping = 1
#	joint.bias = 0.9
	# for now, put the joint at the center of the collision shape
	add_named_child(joint, 'joint')


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
		&'sex', &'monster_name', &'morph', &'birthday',
		&'belly', &'mood', &'energy', &'social',
		&'orientation',
		&'attributes', # TODO: 'preferences',
		# TODO: 'past_actions', 'current_action', 'next_action', 'learned_actions'
	])
	return keys

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

func load_orientation(_orientation):
	orientation = U.parse_vec(_orientation, Vector2(1, 0))

func load_attributes(_attributes):
	if not _attributes is Dictionary: _attributes = {}
	var attribute_overrides = Data.fetch([type, &'attributes'], {})
	attributes = Attributes.new(_attributes, attribute_overrides)

# ideally we would fail to load a monster with an invalid morph.  i'm not sure
# how to fail out of the constructor though, so for now just pick a valid one
func load_morph(_morph):
	if Data.missing([type, &'morphs', _morph]): _morph = generate_morph()
	morph = _morph

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #

func generate_type(): return Data.by_type.monster.pick_random()
# todo: this should be weighted by `data.gender_ratio` if provided
func generate_sex(): return Sex.values().pick_random()
func generate_morph(): return data.morphs.keys().pick_random()
func generate_birthday(): return Clock.get_dict()

func generate_monster_name():
	var names = preload("res://addons/randomnamesgenerator/names_in_arrays.gd")
	return (
		names.v_RWFemaleFirstNames if sex == Sex.FEMALE
		else names.v_RWMaleFirstNames
	).pick_random()


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

var can_grab: bool = true

func _on_collide(node: Node2D):
	if node is Entity and !is_grabbing() and can_grab: grab(node)

# --------------------------------------------------------------------------- #

func _on_tick_changed():
	if current_action:
		var action_result = current_action.tick()
		update_drives(action_result)
	else: choose_action()

# --------------------------------------------------------------------------- #

# debug logging, shows up in garden ui
func announce(msg):
	var l = garden.get_node('ui/log')
	l.add_text('[' + monster_name + '] ' + msg + '\n')
	l.scroll_to_line(l.get_line_count() - 1)


# =========================================================================== #
#                               G R A B B I N G                               #
# --------------------------------------------------------------------------- #

func disable_grab(cooldown: float):
	announce(str("cannot grab for ", cooldown, " seconds"))
	can_grab = false
	get_tree().create_timer(10).timeout.connect(enable_grab)

func enable_grab():
	can_grab = true
	announce("can now grab")

# --------------------------------------------------------------------------- #

func grab(node: Entity):
	joint.node_b = node.get_path()
	var grab_duration = randi_range(10, 120)
	announce(str(
		"is grabbing ", get_grabbed_name(), " for ", grab_duration, " seconds"
	))
	get_tree().create_timer(grab_duration).timeout.connect(release)

func release(msg: String = "released "):
	announce(msg + get_grabbed_name())
	joint.node_b = ""
	disable_grab(randi_range(5, 10))

# --------------------------------------------------------------------------- #

var grabbed: Entity:
	get: return get_node(joint.node_b) if is_grabbing() else null
	set(_x): return

func get_grabbed_name():
	return (
		"[NONE]" if grabbed == null else
		str("[", grabbed.monster_name, "]") if grabbed is Monster
		else grabbed.type
	)

func is_grabbing():
	return joint.node_b != NodePath("") and has_node(joint.node_b)

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

# updates the monster's drive meters (mood, belly, energy, and social).
# called once per "tick" unit of game time (~0.5 seconds).
#
# `diff` is a hash of drive names to float amounts by which to modify the drive.
# these are "base deltas", which are passed through the appropriate `calc_x_delta`
# function to compute a final delta modified by the monster's attributes.
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
	var vig_mod = attributes.vigor.value * 2.0
	if base_delta > 0: return base_delta * vig_mod
	else: return base_delta * (2.0 - vig_mod)


# delta belly is modified by our appetite attribute (converted to a multiplier,
# as with vigor) - higher appetite causes belly to drain faster and fill slower.
#
# if delta energy is positive (recovery), our d_energy_mod multiplier is < 1,
# causing belly to drain slower; if it's negative, the modifier is > 1, which
# will drain it faster. D_ENERGY_FACTOR controls the strength of the effect.
func _mod_belly_delta(base_delta: float, delta_energy: float = 0.0):
	var app_mod = attributes.appetite.value * 2.0
	# if energy is increasing, decrease belly decay rate.
	var d_energy_mod = 1.0 - (delta_energy * D_ENERGY_FACTOR)
	var delta_belly = base_delta * app_mod * d_energy_mod
	return delta_belly


func _mod_social_delta():
	pass

# --------------------------------------------------------------------------- #

# target energy reflects the pet's preference for activity or rest, and is
# determined by the inverse of its pep attribute (which ranges from 0 to 1).
# high pep & low target energy means a more active pet, and vice versa.
func get_target_energy():
	return MAX_ENERGY * attributes.pep.lerp(1, 0)

func get_target_social():
	return MAX_SOCIAL * attributes.extraversion.lerp(1, 0)
