extends StaticBody2D

var entity_type = Constants.EntityType.OBJECT
var garden

var id
var type = "fat_palm"
var coordinates = Vector2()

func initialize(data):
	deserialize(data)
	$sprite.texture = Data.fetch_res([data.type, 'sprite'])
	# $shape.shape.radius = 8
	update_z()

func _physics_process(_delta):
	z_index = int(position.y) + 16

# --------------------------------------------------------------------------- #

# update the z-index of our sprite so that monsters appear in front of or
# behind other entities according to their y-position in the garden
func update_z():
	pass

# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #

const SAVE_KEYS = ['type']

# --------------------------------------------------------------------------- #

func serialize():
	var data = {}
	for key in SAVE_KEYS:
		data[key] = get(key)
	data.coordinates = [coordinates.x, coordinates.y]
	return data

# --------------------------------------------------------------------------- #

func deserialize(data):
	print(data)
	for key in SAVE_KEYS:
		set(key, data[key])
	coordinates = Vector2(data.coordinates[0], data.coordinates[1])
