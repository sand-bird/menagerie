extends ReferenceRect

var target: Node2D
var EntityType = Constants.EntityType

func select(new_target: Node2D = null):
	if !new_target or not 'entity_type' in new_target:
		print("select_hud: bad entity")
		return

	if target and target != new_target:
		deselect()

	target = new_target

	match target.entity_type:
		# TODO: connect to monster so we can update on the fly
		EntityType.MONSTER: connect_monster()
		EntityType.OBJECT: connect_object()

	show()

# --------------------------------------------------------------------------- #

func deselect(entity = null):
	hide()
	if !target: return
	for connection in get_incoming_connections():
		if connection.source == target:
			target.disconnect(connection.signal_name, Callable(self, connection.method_name))

func connect_monster():
	target.connect('drives_changed', Callable(self, 'update_monster'))
	update_monster()

func update_monster():
	$name_bar/label.text = target.monster_name
	$horizontal.show()
	$horizontal/belly.value = target.belly
	$horizontal/energy.value = target.energy
	$horizontal/social.value = target.social
	$horizontal/current_action.text = target.current_action.name if target.current_action else 'none'

func connect_object():
	$name_bar/label.text = 'an object'
	$horizontal.hide()
