extends CenterContainer

const EventButton = preload("res://ui/event_button.gd")
const Direction = Constants.Direction

var entity
const BUTTON_OFFSET = 32

var options = {
	Direction.TOP: ['Pet', 'pet_monster'],
	Direction.BOTTOM: ['Details', 'view_details'],
	Direction.LEFT: ['Give', 'give_item'],
	Direction.RIGHT: ['Hit', 'hit_monster']
}

var options2 = {
	'top': ['Discipline', 'pet_monster'],
	'bottom': ['Info', 'view_details'],
	'left': ['Give', 'give_item'],
	'right': ['Command', 'hit_monster']
}

var offsets = {
	Direction.TOP: Vector2(0, -BUTTON_OFFSET),
	Direction.BOTTOM: Vector2(0, BUTTON_OFFSET),
	Direction.LEFT: Vector2(-BUTTON_OFFSET, 0),
	Direction.RIGHT: Vector2(BUTTON_OFFSET, 0)
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_options(selected_entity):
	var buttons = {
		left = $h/left,
		right = $h/right,
		top = $v/top,
		bottom = $v/bottom
	}
	entity = selected_entity
	if entity.entity_type == Constants.EntityType.MONSTER:
		for dir in options2:
			var option = options2[dir]
			# var button = EventButton.new()
			var button = buttons[dir]
			button.text = option[0]
			button.signal_name = option[1]
			#add_child(button)
			#button.rect_position += offsets[dir]

func _physics_process(delta):
	if entity:
		rect_position = Player.garden.get_screen_relative_position(entity.position)
