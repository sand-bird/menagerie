class_name Entity
extends RigidBody2D
"""
base class for "garden entities": monsters, objects/sessiles, and items.

defines common parameters (including child nodes; all entities should have at
minimum a sprite and a collision shape) and the core logic for initialization,
serialization, and deserialization.

entity subclasses can override the `save_keys` function to add their own keys
to serialize and deserialize, and define custom deserialization behavior by
adding new `load_` and `generate_` functions.

during initialization, input data must be deserialized first before any child
nodes are created.  thus entity subclasses should always call `super()` at the
*start* of their `_init` function, *then* initialize whatever extra child nodes
they need.

see `data/system/entity.schema` for the corresponding schema (which should be
extended using `"$ref": "entity"` in the schema for each entity subclass).
all properties which are required here should be required in the schema.
"""

var garden: Garden

# child nodes
# -----------
# var anim: AnimationPlayer
var cg: CanvasGroup
var sprite: Sprite2D
var shape: CollisionShape2D
var shadow: TextureRect

# core properties
# ---------------
var uuid: StringName # unique id of the entity
var id: StringName # id of the entity's data definition
var size: int # radius of the entity's collision shape

var data:
	get: return Data.fetch(id)
	set(_x): return

# modular behavior implementations (not currently used for monsters)
var traits: Dictionary = {}


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

# entities must be initialized in code because they depend on data definitions
# that are loaded at runtime.  this makes storing the node's children in a
# PackedScene (entity.tscn) counter-productive, because the scene would be
# incomplete/invalid without initialization at runtime.
#
# instead, we should create the entire scene programmatically.  this allows us
# to initialize entities in a single step with `new`, rather than having to
# instantiate an incomplete scene and then initialize it in a separate step.
func _init(data_: Dictionary, garden_: Garden):
	garden = garden_
	deserialize(data_)
	
	var script: Script = get_script()
	# if this is called from a subclass of Entity, `base_script` is `entity.gd`,
	# otherwise it's null.  this ensures we get the right directory for generic
	# Entity child nodes (they should live in the same folder as their parent).
	var base_script: Script = script.get_base_script()
	var path: String = (
			base_script if base_script else script
		).resource_path.get_base_dir()
	
	size = data.size
	mass = data.mass
	# rotation looks bad at low res so we turn it off.
	# it can be reenabled for specific entities via traits 
#	lock_rotation = true

	cg = CanvasGroup.new()
	cg.material = preload("res://cg_material.tres")
	add_named_child(cg, 'cg')
	
	sprite = load(path.path_join('sprite.gd')).new()
	sprite.name = 'sprite'
	cg.add_child(sprite)
#	sprite.position = Vector2(0, size)
	
	shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = size
#	shape.position.y -= size
	add_named_child(shape, 'shape')
	
	shadow = TextureRect.new()
	shadow.texture = preload("res://assets/garden/shadow.png")
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.size.x = size * 2.5
	shadow.position.x = -(shadow.size.x * 0.5)
	shadow.pivot_offset = shadow.size / 2
	shadow.size.y = size * 1
	shadow.position.y = 0
	shadow.show_behind_parent = true
	add_named_child(shadow, 'shadow')
	
	# debugging
	var d_vecs = debug_vectors()
	for n in d_vecs:
		var ray = RayCast2D.new()
		ray.visible = true
		ray.enabled = false
		ray.modulate = d_vecs[n][0]
		add_named_child(ray, n)

# --------------------------------------------------------------------------- #

# it's nicer to use vars for children because of typing, but we name them so
# other nodes can get them with `get_node`.  this is also necessary for $anim
# since it takes a NodePath to $sprite (the target of all animations).
func add_named_child(node: Node, n: String):
	node.name = n
	add_child(node)


# =========================================================================== #
#                           M I S C   M E T H O D S                           #
# =========================================================================== #
#                               a b s t r a c t                               #
# --------------------------------------------------------------------------- #

# returns a sprite_info dict from the entity's data.  used for portraits.
func get_sprite_info(_key = null, _facing = null) -> Dictionary:
	return { spritesheet = "res://assets/ui/icons/monster.png" } # placeholder

# returns a name suitable for display in menus.
func get_display_name() -> String:
	return U.trans(data.name)

# returns the actions the given monster can perform on this entity.
func get_actions(m: Monster) -> Array[Action]:
	var actions = [] as Array[Action]
	for t in traits.values():
		actions.append_array(t.get_actions(m))
	return actions

#                                p h y s i c s                                #
# --------------------------------------------------------------------------- #

# truncate linear velocity so that janky grab physics can't rocket things
# across the map
func _integrate_forces(state: PhysicsDirectBodyState2D):
	state.linear_velocity = state.linear_velocity.limit_length(100)

# --------------------------------------------------------------------------- #

func _physics_process(_delta):
	for child in get_children():
		if 'rotation' in child: child.rotation = -rotation
	var d_vecs = debug_vectors()
	for key in d_vecs:
		(get_node(NodePath(key)) as RayCast2D).target_position = (d_vecs[key][1] as Callable).call()

#                                  d e b u g                                  #
# --------------------------------------------------------------------------- #
# configuration for raycasts to show for debug purposes.
# need to reload when adding/uncommenting one since we set these up in _init.
# can add more in subclasses by overriding the `debug_vectors` fn.
func debug_vectors():
	return {
		linear_velocity = [Color(1, 0, 0), func (): return linear_velocity * 3],
		rotation = [Color(1, 0, 1), func (): return Vector2.from_angle(rotation + (PI / 2)) * 25]
	}


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

# list of property names to persist and load.
# order matters for deserialization; some properties depend on others earlier
# in the list to already be loaded or generated (especially id`).
func save_keys() -> Array[StringName]:
	return [&'uuid', &'id', &'position', &'traits'] as Array[StringName]

# --------------------------------------------------------------------------- #

func serialize() -> Dictionary:
	var serialized = {}
	for key in save_keys():
		serialized[key] = U.serialize_value(get(key), key)
	return serialized

# --------------------------------------------------------------------------- #

func deserialize(serialized = {}) -> void:
	for key in save_keys():
		U.deserialize_value(self, serialized.get(key), key)
	# need to deserialize `type` before loading trait data
	var trait_data = Data.fetch([id, &'traits'], {})
	for key in trait_data:
		if key in Traits.valid_traits:
			traits[key] = Traits.load(key).new(
				trait_data.get(key), serialized, self
			)

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

func load_position(input) -> void:
	position = U.parse_vec(input, generate_position())

# ideally we would fail to load an entity with an invalid id.  i'm not sure
# how to fail out of the constructor though, so for now just pick a valid one
func load_id(input) -> void:
	if input == null or Data.missing(input): input = generate_id()
	id = input

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #

func generate_uuid(): return Uuid.v4()
func generate_id(): return Data.data.keys().pick_random()

func generate_position():
	var garden_size = garden.get_map_size()
	return Vector2(
		randi_range(0, garden_size.x),
		randi_range(0, garden_size.y)
	)
