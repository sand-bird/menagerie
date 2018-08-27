extends ReferenceRect

var target
var EntityType = Constants.EntityType

func initialize(entity):
	update()

func update(entity = null):
	if !entity: 
		hide()
		return
	show()
	target = entity
	target.connect("drives_changed", self, "update_monster")
	match entity.entity_type:
		# TODO: connect to monster so we can update on the fly
		EntityType.MONSTER: update_monster()

func update_monster():
	$name_bar/label.text = target.monster_name
	$horizontal.show()
	$horizontal/belly.value = target.belly
	$horizontal/energy.value = target.energy
	$horizontal/social.value = target.social
