extends TileMapLayer

# --------------------------------------------------------------------------- #
# we save the garden's terrain as a 2d array of integers, each representing a
# terrain type (grass, dirt, etc).  each of these corresponds with a y-index in
# the terrain atlas on the TileSet resource belonging to this TileMapLayer,
# which is simply a vertical png with one tile for each type of terrain in the
# game.  These tiles will hold properties relevant to each of those terrains,
# eg navigation, physics (friction?? idk), etc.

func set_terrain(coords: Vector2i, idx):
	set_cell(coords, tile_set.get_source_id(0), Vector2i(0, idx))

func get_terrain(coords: Vector2i):
	return get_cell_atlas_coords(coords).y

# --------------------------------------------------------------------------- #

func save_terrain():
	var grid_size = get_used_rect().size
	var data = []
	data.resize(grid_size.y)
	for y in range(grid_size.y):
		data[y] = []
		data[y].resize(grid_size.x)
		for x in range(grid_size.x):
			data[y][x] = get_terrain(Vector2i(x, y))
	return data

func load_terrain(data):
	print('source id:', tile_set.get_source_id(0))
	for y in data.size():
		for x in data[y].size():
			var idx = data[y][x]
			set_terrain(Vector2i(x, y), idx)
	# this _should_ be the size of a grid square but it might be weird -
	# from the docs: "A quadrant is a group of tiles to be drawn together on a
	# single canvas item, for optimization purposes"
	var size = Vector2(data[0].size(), data.size()) * rendering_quadrant_size
	Log.info(self, ["garden size: ", size])
	Log.info(self, ["terrain used rect: ", get_used_rect()])
#	Log.info(self, ["terrain used cells: ", get_used_cells(0)])
