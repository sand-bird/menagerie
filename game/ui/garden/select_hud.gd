extends ReferenceRect

var target: Node2D
var EntityType = Constants.EntityType

func select(new_target: Node2D = null):
	if !new_target or not 'entity_type' in new_target:
		print("select_hud: bad entity")
		return

	if target and target != new_target:
		unselect()

	target = new_target

	match target.entity_type:
		# TODO: connect to monster so we can update on the fly
		EntityType.MONSTER: connect_monster()

	show()

# --------------------------------------------------------------------------- #

func unselect(entity = null) -> void:
	hide()
	if !target: return
	print("self: ", get_incoming_connections())
	for connection in get_incoming_connections():
		if connection.source == target:
			target.disconnect(connection.signal_name,
					self, connection.method_name)
			print("disconnected! ", connection)

func connect_monster() -> void:
	target.connect('drives_changed', self, 'update_monster')
	update_monster()

func update_monster() -> void:
	$name_bar/label.text = target.monster_name
	$horizontal.show()
	$horizontal/belly.value = target.belly
	$horizontal/energy.value = target.energy
	$horizontal/social.value = target.social
