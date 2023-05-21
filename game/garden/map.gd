extends TileMap

const TERRAIN_LAYER = 0
const TERRAIN_ATLAS_ID = 0

# --------------------------------------------------------------------------- #
# we save the garden's terrain as a 2d array of integers, each representing a
# terrain type (grass, dirt, etc).  currently, each of these corresponds with a
# y-index in the terrain atlas, which is simply a vertical png with 3 different
# colors of tiles.
#
# later on, we'll want to use godot 4 terrains (the new autotiling) instead.
# this involves adding a "terrain" to the tileset for each terrain type, and
# setting each terrain up with its own atlas texture.  we will still serialize
# only the terrain ids, though.

func set_terrain_cell(coords: Vector2i, idx):
	set_cell(TERRAIN_LAYER, coords, TERRAIN_ATLAS_ID, Vector2i(0, idx))

func get_terrain_cell(coords: Vector2i):
	return get_cell_atlas_coords(TERRAIN_LAYER, coords).y

# --------------------------------------------------------------------------- #

func save_terrain():
	var grid_size = get_used_rect().size
	var data = []
	data.resize(grid_size.y)
	for y in range(grid_size.y):
		data[y] = []
		data[y].resize(grid_size.x)
		for x in range(grid_size.x):
			data[y][x] = get_terrain_cell(Vector2i(x, y))
	return data

func load_terrain(data):
	for y in data.size():
		for x in data[y].size():
			var idx = data[y][x]
			set_terrain_cell(Vector2i(x, y), idx)
	var size = Vector2(data[0].size(), data.size()) * cell_quadrant_size
	Log.info(self, ["garden size: ", size])
	Log.info(self, ["terrain used rect: ", get_used_rect()])
	Log.info(self, ["terrain used cells: ", get_used_cells(0)])
