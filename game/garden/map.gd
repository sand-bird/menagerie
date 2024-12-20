extends TileMapLayer

const peering_bit_mapping = {
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: 1,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: 2,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: 4,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: 8
}

# display tiles are offset from data tiles by half a tile left and up, meaning
# the display tile at (1, 1) will have the data tile at (1, 1) as its bottom
# right corner, the data tile at (0, 0) as its top left corner, and so on.
const display_to_data_offset_mapping = {
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: Vector2i(0, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: Vector2i(-1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: Vector2i(-1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: Vector2i(0, -1)
}

var terrain_to_layer_mapping = {
	0: 'dirt',
	1: 'grass',
#	2: 'water'
}

var tile_index = {}

func _ready():
	for idx in terrain_to_layer_mapping:
		var layer_name = terrain_to_layer_mapping[idx]
		var layer = get_node(layer_name)
		if !layer: continue
		var atlas = get_first_tilesetsource(layer)
		tile_index[idx] = build_tile_index(atlas)


# --------------------------------------------------------------------------- #
# we save the garden's terrain as a 2d array of integers, each representing a
# terrain type (grass, dirt, etc).  each of these corresponds with a y-index in
# the terrain atlas on the TileSet resource belonging to this TileMapLayer,
# which is simply a vertical png with one tile for each type of terrain in the
# game.  These tiles will hold properties relevant to each of those terrains,
# eg navigation, physics (friction?? idk), etc.

func set_cell_terrain(coords: Vector2i, idx):
	set_cell(coords, tile_set.get_source_id(0), Vector2i(0, idx))

func get_cell_terrain(coords: Vector2i):
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
			data[y][x] = get_cell_terrain(Vector2i(x, y))
	return data

func load_terrain(data):
	debug_peering()
	print('source id:', tile_set.get_source_id(0))
	for y in data.size():
		for x in data[y].size():
			var idx = data[y][x]
			set_cell_terrain(Vector2i(x, y), idx)
	# this _should_ be the size of a grid square but it might be weird -
	# from the docs: "A quadrant is a group of tiles to be drawn together on a
	# single canvas item, for optimization purposes"
	var size = Vector2(data[0].size(), data.size()) * rendering_quadrant_size
	Log.info(self, ["garden size: ", size])
	Log.info(self, ["terrain used rect: ", get_used_rect()])
	var terrain_size = get_used_rect().size
	# render display cells. the display maps should be one tile larger than the
	# data map since they are offset outside the data map by half a tile.
	for y in range(terrain_size.y + 1):
		for x in range(terrain_size.x + 1):
			render_display_cell(Vector2i(x, y))
#	Log.info(self, ["terrain used cells: ", get_used_cells(0)])

# --------------------------------------------------------------------------- #

# get the four data cells surrounding a display cell, mapped to the appropriate
# TileSet.CellNeighbor.
func get_data_cells(coords: Vector2i) -> Dictionary:
	var cells = {}
	for corner in display_to_data_offset_mapping:
		cells[corner] = coords + display_to_data_offset_mapping[corner]
	return cells

# get the four display cells surrounding a data cell. when we update the terrain
# on a data cell, we should update the display cells affected by the change.
func get_display_cells(coords: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(2): for y in range(2):
		cells.append(coords + Vector2i(x, y))
	return cells

# --------------------------------------------------------------------------- #

# first, find the terrain id for each corner of the display cell using the
# four data cells which overlap this display cell.
# then, on each display layer, set the cell to the tile in that layer's first 
# tileset (there should only be one tileset for each layer) whose peering bits
# match the bitmask value for the corresponding terrain. 
func render_display_cell(coords: Vector2i):
	var corners = get_data_cells(coords)
	for idx in terrain_to_layer_mapping:
		var layer: TileMapLayer = get_node(terrain_to_layer_mapping[idx])
		if !layer: return
		var tileset = get_first_tilesetsource(layer)
		# for the bottom layer, just fill it with tiles
		var bitmask = 15 if idx == 0 else calc_bitmask_for_layer(idx, corners)
		var valid_tiles: Array = tile_index[idx][bitmask]
		if valid_tiles.is_empty(): continue
		var tile = pick_tile_for_cell(coords, valid_tiles)
		layer.set_cell(coords, layer.tile_set.get_source_id(0), tile.coords)

# chooses randomly from a weighted array of valid tile options using a seed
# determined by the given cell coords. this ensures we always use the same tile
# option per layer per cell.
static func pick_tile_for_cell(coords: Vector2i, options: Array):
	var rng = RandomNumberGenerator.new()
	rng.seed = coords.x**5 + coords.y**3
	var idx = rng.rand_weighted(options.map(func (x): return x.probability))
	return options[idx]


func calc_bitmask_for_layer(layer: int, corners: Dictionary) -> int:
	var bitmask = 0
	for corner in corners:
		var data_cell = corners[corner]
		var terrain = get_cell_terrain(data_cell)
		if terrain == layer:
			bitmask += peering_bit_mapping[corner]
	return bitmask


# --------------------------------------------------------------------------- #

static func get_first_tilesetsource(layer: TileMapLayer) -> TileSetSource:
	var source_id = layer.tile_set.get_source_id(0)
	return layer.tile_set.get_source(source_id)

# returns a mapping from a marching squares bitmask value (0 to 15) to an array
# of tiles from the TileSetAtlasSource that are valid for that bitmask.
static func build_tile_index(atlas: TileSetAtlasSource):
	var grid_size = atlas.get_atlas_grid_size()
	var tile_index = {}
	for i in range(16): tile_index[i] = []
	for y in grid_size.y:
		for x in grid_size.x:
			var tile_data: TileData = atlas.get_tile_data(Vector2i(x, y), 0)
			if !tile_data: continue
			var bitmask = 0
			for corner in peering_bit_mapping:
				if tile_data.get_terrain_peering_bit(corner) > -1:
					bitmask += peering_bit_mapping[corner]
			tile_index[bitmask].append({
				coords = Vector2i(x, y),
				probability = tile_data.probability
			})
	return tile_index

# --------------------------------------------------------------------------- #

func debug_peering():
	print("======= debug peering ==========================================")
	var grass_tileset: TileSet = $grass.tile_set
	var sid = grass_tileset.get_source_id(0)
	print("source id ", sid)
	var grass_atlas: TileSetAtlasSource = grass_tileset.get_source(sid)
	var grid_size = grass_atlas.get_atlas_grid_size()
	print("grass atlas ", grass_atlas, " | grid size: ", grid_size)
	for x in grid_size.x:
		for y in grid_size.y:
			var tile_data = grass_atlas.get_tile_data(Vector2i(x, y), 0)
			print("tile data for (", x, ", ", y, "): ", tile_data)
			if !tile_data: continue
			var bits = []
			var bitmask = 0
			for neighbor in peering_bit_mapping:
				var bit_value = peering_bit_mapping[neighbor]
				var peering_bit = tile_data.get_terrain_peering_bit(neighbor)
				print("peering bit ", neighbor, " for tile (", x, ", ", y, "): ", peering_bit)
				if peering_bit > -1:
					bitmask += bit_value
					bits.append(neighbor)
			print("peering for (", x, ", ", y, "): ", bitmask, " ", bits)
	print("================================================================")
