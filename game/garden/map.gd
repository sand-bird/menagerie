extends TileMapLayer

# mapping from peering bits set on a TileSetAtlasSource in the editor to their
# respective bitmask values for marching squares tiling.  uses to look up which
# display tile to use for each cell on each layer of each display map based on
# which terrain tile is on the data map cell at each of that cell's corners.
const peering_bit_mapping = {
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: 1,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: 2,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: 4,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: 8
}

# mapping from terrain ids to the name of the display layer on which we draw
# that terrain.  necessary to decouple terrain ids (which are serialized and
# thus should stay the same) from display layer order.
const terrain_to_layer_mapping = {
	0: 'dirt', 1: 'grass', # 2: 'water'
}

# a dictionary of  `{ [terrain_id]: TileIndex }`; see `build_tile_index`.
var tile_index = {}

# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _ready():
	for idx in terrain_to_layer_mapping:
		var layer_name = terrain_to_layer_mapping[idx]
		var layer = get_node(layer_name)
		if !layer: continue
		var atlas = get_first_tilesetsource(layer)
		tile_index[idx] = build_tile_index(atlas)

# --------------------------------------------------------------------------- #

# returns a mapping from a marching squares bitmask value (0 to 15) to an array
# of tile options from the TileSetAtlasSource that are valid for that bitmask,
# ie `{ [bitmask]: Array[TileOption] }`, where a TileOption is a dict with
# `{ coords: Vector2i, probability: float }`.
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

# =========================================================================== #
#                                T E R R A I N                                #
# --------------------------------------------------------------------------- #
# we save the garden's terrain as a 2d array of integers, each representing a
# terrain type (grass, dirt, etc).  each of these corresponds with a y-index in
# the TileSetAtlasSource on the TileSet belonging to this TileMapLayer, which
# is simply a vertical png with one tile for each type of terrain in the game.
# These tiles will hold properties relevant to each of those terrains, eg
# navigation, physics (friction?? idk), etc.
# the terrain tiles themselves are invisible; to actually display the terrain,
# we render each terrain type on its own separate display layer (TileMapLayer
# child of this node) using render_display_cell.

func set_cell_terrain(coords: Vector2i, idx: int):
	set_cell(coords, tile_set.get_source_id(0), Vector2i(0, idx))

func get_cell_terrain(coords: Vector2i):
	return get_cell_atlas_coords(coords).y

# when we update a cell's terrain after the initial load, we also need to
# rerender the four surrounding display cells on each display layer.
func update_cell_terrain(coords: Vector2i, idx: int):
	set_cell_terrain(coords, idx)
	var display_cells = get_display_cells(coords)
	for cell in display_cells: render_display_cell(cell)

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


# =========================================================================== #
#                D A T A / D I S P L A Y   C O N V E R S I O N                #
# --------------------------------------------------------------------------- #

# display tiles are offset from data tiles by half a tile left and up, meaning
# the display tile at (1, 1) will have the data tile at (1, 1) as its bottom
# right corner, the data tile at (0, 0) as its top left corner, and so on.
const display_to_data_offset_mapping = {
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: Vector2i(0, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: Vector2i(-1, 0),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER: Vector2i(-1, -1),
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER: Vector2i(0, -1)
}

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


# =========================================================================== #
#                      D I S P L A Y   R E N D E R I N G                      #
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

# --------------------------------------------------------------------------- #

func calc_bitmask_for_layer(layer: int, corners: Dictionary) -> int:
	var bitmask = 0
	for corner in corners:
		var data_cell = corners[corner]
		var terrain = get_cell_terrain(data_cell)
		if terrain == layer:
			bitmask += peering_bit_mapping[corner]
	return bitmask

# chooses randomly from a weighted array of valid tile options using a seed
# determined by the given cell coords. this ensures we always use the same tile
# option per layer per cell.
static func pick_tile_for_cell(coords: Vector2i, options: Array):
	var rng = RandomNumberGenerator.new()
	rng.seed = coords.x**5 + coords.y**3
	var idx = rng.rand_weighted(options.map(func (x): return x.probability))
	return options[idx]

# --------------------------------------------------------------------------- #

static func get_first_tilesetsource(layer: TileMapLayer) -> TileSetSource:
	var source_id = layer.tile_set.get_source_id(0)
	return layer.tile_set.get_source(source_id)
