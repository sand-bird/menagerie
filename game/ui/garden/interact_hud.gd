extends Container

# const EventButton = preload("res://ui/event_button.gd")
# const Direction = Constants.Direction

var entity

var options = {
	'top': ['Discipline', 'pet_monster'],
	'right': ['Info', 'view_details'],
	'left': ['Give', 'give_item'],
	'bottom': ['Command', 'hit_monster']
}

func attach(selected_entity):
	show()
	entity = selected_entity
	if entity.entity_type == Constants.EntityType.MONSTER:
		for dir in options:
			var option = options[dir]
			var button = get_node(dir)
			button.text = option[0]
			button.signal_name = option[1]

func detach():
	entity = null
	hide()

func _physics_process(delta):
	if entity:
		position = Player.garden.get_screen_relative_position(entity.get_position())
