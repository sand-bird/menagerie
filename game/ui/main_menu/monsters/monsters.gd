extends MenuChapter

const BASE_PATH = "res://ui/main_menu/monsters/"
const MONSTER_LIST_PATH = BASE_PATH + "monster_list.tscn"
# const MONSER_DETAILS_PATH = BASE_PATH + "monster_details.tscn"

func build_index():
	# create a section for the monster list
	sections.index = MONSTER_LIST_PATH

	for monster in (Player.garden.monsters if Player.garden != null else []):
		# create a section for that monster's description
		
		pass
