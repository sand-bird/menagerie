extends Entity
class_name Item

# TODO: remove. this is currently used for the garden's "select hud".
# we should rewrite that component to add different child nodes based on the
# target's class instead.
const entity_type = Constants.EntityType.ITEM

var traits: Array[Trait] = []

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready():
	sprite.offset_texture()
	Dispatcher.tick_changed.connect(_on_tick_changed)

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
	mass = data.get('mass', 1)
	
	sprite.update_texture({ spritesheet = data.sprite, frames = 1 })
	#sprite.texture = ResourceLoader.load(data.sprite)


# =========================================================================== #
#                           M I S C   M E T H O D S                           #
# --------------------------------------------------------------------------- #

func _on_tick_changed():
	# call on_tick_change methods on traits
	pass

func get_sprite_info(_key = null, _facing = null):
	return { spritesheet = data.sprite }


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
# see the `serialize` & `deserialize` functions on the parent class, Entity.
# `deserialize` is called from the Entity constructor, and `serialize` is
# called from the garden's `serialize` method.

#                                l o a d e r s                                #
# --------------------------------------------------------------------------- #

#                             g e n e r a t o r s                             #
# --------------------------------------------------------------------------- #

func generate_type(): return Data.by_type.item.pick_random()
