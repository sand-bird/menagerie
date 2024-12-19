extends NavigationRegion2D
"""
generate a navigation polygon for the garden.  as long as this is the only
NavigationRegion in our world, gd4's NavigationServer automatically adds it to
the navigation map that agents will use.

we generate the navpolygon with `add_outline`.  the first outline surrounds the
tilemap and creates our nagivable area.  then we add outlines for obstacles
(objects in the garden); since these are contained within the base outline, they
become "holes" in the final navpoly.

however, NavigationPolygon does not support merging outlines and will crash if
we give it two outlines that overlap.  thus we first need to identify and merge
all of our overlapping obstacles.

the final consideration is agent size padding: we want to add half the agent
size to all obstacles (with `Geometry2D.offset_polygon`) before merging them,
and probably also subtract it from the base navpoly around the tilemap.
eventually, we'll want to generate a few different navpolys with different agent
sizes, and configure the NavigationAgents in our monsters to use the correct one
for the monster's size.

merging algorithm:
- naive approach means checking each obstacle against each other one, O(n^2)
- we can reduce the size of the search space by sorting obstacles first, so each
  obstacle only needs to check the ones before it in the list

recursive merges:
- no matter how we sort obstacles, there may be cases where a successful merge
  enables more merges.  eg, sorting by (x,y):
   ,__,       ,__,
,__|1_| -> ,__|__|
|2_|3_|    |_____|

we cannot merge until we get to 3, which can be merged with 2.
"""

var navpoly: NavigationPolygon = get_navigation_polygon()

func make_box(_size, _offset):
	var to_vec = func (x):
		return x if typeof(x) in [TYPE_VECTOR2, TYPE_VECTOR2I] else Vector2(x, x)
	var size = to_vec.call(_size)
	var offset = to_vec.call(_offset)
	return PackedVector2Array([
		Vector2(offset.x,          offset.y),
		Vector2(offset.x + size.x, offset.y),
		Vector2(offset.x + size.x, offset.y + size.y),
		Vector2(offset.x,          offset.y + size.y)
	])

func add_box(size, offset):
	navpoly.add_outline(make_box(size, offset))

# --------------------------------------------------------------------------- #

var obstacles: Array[PackedVector2Array] = []

# returns true if any of the points in a are inside or on b.
# this includes polygons whose corners touch
func overlaps_poly(a: PackedVector2Array, b: PackedVector2Array):
	for point in a:
		if Geometry2D.is_point_in_polygon(point, b):
			prints('(overlaps_poly) found overlap | a:', a, '| b:', b, '| point:', point)
			return true
	return false

# 
func add_obstacle(size, offset, _padding):
	var box: PackedVector2Array = make_box(size, offset)
	if obstacles.is_empty():
		obstacles.push_back(box)
		return
	for o in obstacles:
		if overlaps_poly(box, o):
			pass

# --------------------------------------------------------------------------- #

func merge_obstacles(_obstacles: Array[PackedVector2Array]):
	pass

# --------------------------------------------------------------------------- #

func _ready():
	pass
#	var map = (get_parent().get_node('map') as TileMap)
#	var tileset = map.tile_set
	# for some reason get_used_rect is short by one in the x-direction
#	var map_size = map.get_used_rect().size + Vector2i(1, 0)
	# get_used_rect.size is the number of tiles; we have to multiply it by the
	# grid size (stored on the tileset) to get the pixel size of the tilemap
#	var bounds = map_size * tileset.tile_size
#	var base = make_box(bounds, map.get_used_rect().position)
#	navpoly.add_outline(base)
	
#	random_test(bounds)
#	convex_test()
	
		# testing merging
	var poly2a = make_box(10, 100)
	var poly2b = make_box(10, Vector2(110, 110))
	var _poly2c = make_box(10, Vector2(120, 100))
#	navpoly.add_outline(poly2a)
#	navpoly.add_outline(poly2b)
	var merged = Geometry2D.merge_polygons(poly2a, poly2b)
#	var intersection = Geometry2D.intersect_polygons(poly2a, poly2b)
#	print('-INTERSECTION------------ ', intersection)
	print('--MERGED-----------------')
	for i in merged:
		print(i, ' | ', Geometry2D.is_polygon_clockwise(i))
#		navpoly.add_outline(i)
	print('-------------------------')
	
#	parse_2d_collisionshapes(self)
#	NavigationServer2D.bake_from_source_geometry_data(navpoly, merged)
	#navpoly.make_polygons_from_outlines()
#	set_navigation_polygon(navpoly)

# --------------------------------------------------------------------------- #

func random_test(bounds):
	# testing: add some holes
	for i in 5:
		var size = randi_range(5, 50)
		var pos = Vector2(
			randi_range(0, bounds.x - size),
			randi_range(0, bounds.y - size),
		)
		add_box(Vector2(size, size), pos)
#	add_box(Vector2(5, 5), Vector2(100, 100))
#	add_box(Vector2(5, 5), Vector2(80, 120))
#	add_box(Vector2(5, 5), Vector2(80, 80))

# testing whether it works with concave polygons
""" 
  10 20 30 40
10 1__2  5__6
20 |  3__4  |
30 8________7
"""
func convex_test():
	var poly = [
		Vector2(10, 10), # 1
		Vector2(20, 10), # 2
		Vector2(20, 20), # 3
		Vector2(30, 20), # 4
		Vector2(30, 10), # 5
		Vector2(40, 10), # 6
		Vector2(40, 30), # 7
		Vector2(10, 30), # 8
	]
	var convex = Geometry2D.convex_hull(poly)
	navpoly.add_outline(convex)

# --------------------------------------------------------------------------- #

# copied from the godot docs:
# https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationmeshes.html#d-navmesh-from-collisionpolygons
# need to adapt this to look at objects, not just children of this node, and to
# handle overlaps (may need to create holes via shapes rather than outlines)
func parse_2d_collisionshapes(root_node: Node2D):
	for node in root_node.get_children():
		if node.get_child_count() > 0:
			parse_2d_collisionshapes(node)
		if node is CollisionPolygon2D:
			var colpoly_transform: Transform2D = node.get_global_transform()
			var colpoly: PackedVector2Array = node.polygon
			var col_outline: PackedVector2Array = colpoly_transform * colpoly
			navpoly.add_outline(col_outline)

# --------------------------------------------------------------------------- #

# test.  we can add multiple polygons to a NavigationPolygon, but they stack on
# top of each other, rather than cutting holes like outlines do.
"""
func add_poly(size: Vector2, offset: Vector2 = Vector2(0, 0)):
	var vertices = navpoly.vertices
	var start = vertices.size()
	vertices.append_array([
		Vector2(offset.x,          offset.y),
		Vector2(offset.x + size.x, offset.y),
		Vector2(offset.x + size.x, offset.y + size.y),
		Vector2(offset.x,          offset.y + size.y)
	])
	navpoly.set_vertices(vertices)
	prints('vertices', navpoly.vertices)
	navpoly.add_polygon([start, start + 1, start + 2, start + 3])
"""
