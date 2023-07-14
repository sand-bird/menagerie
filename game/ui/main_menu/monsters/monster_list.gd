extends MenuSection

const ITEM_PATH = "res://ui/main_menu/monsters/monster_list_item.tscn"

const ITEMS_PER_PAGE = 8
const ITEMS_PER_SIDE = ITEMS_PER_PAGE / 2

@onready var monsters: Array:
	get: return Player.garden.monsters.values() if Player.garden != null else []

func initialize(_key = null):
	print('monster_list initialize')
	title = tr(T.MONSTERS)
	pages = ceil(float(monsters.size()) / float(ITEMS_PER_PAGE))

func can_next_page():
	return $right.get_children().any(func(child): return child.has_focus())

func can_prev_page():
	return $left.get_children().any(func(child): return child.has_focus())

# instantiate monster_list_items for each monster
func load_page(page: int):
	print('monster_list load_page ', page)
	for child in $left.get_children(): child.queue_free()
	for child in $right.get_children(): child.queue_free()
	for i_p in ITEMS_PER_PAGE: # i_p = page index
		var i_m = i_p + (page * ITEMS_PER_PAGE) # i_m = monster index
		if i_m >= monsters.size(): break
		var item: Node = load(ITEM_PATH).instantiate()
		item.initialize(monsters[i_m])
		if i_p < ITEMS_PER_SIDE:
			$left.add_child(item)
			item.owner = $left
		else:
			$right.add_child(item)
			item.owner = $right

func focus(from_right = false):
	var children = get_list_children(from_right)
	prints(children, children.size())
	var focus_child = children[0]
	print('focus_child: ', focus_child)
	focus_child.grab_focus()

func get_list_children(right = false):
	var children = $right.get_children() if right else $left.get_children()
	return children.filter(
		func(child: Node): return !child.is_queued_for_deletion()
	)
