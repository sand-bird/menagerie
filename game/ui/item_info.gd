extends Control


func set_section_title(node: Label, t: StringName):
	node.text = str(" ", tr(t).to_upper())

func _ready(): pass
#	set_section_title($scroll/info/hbox/value/title, T.VALUE)
#	set_section_title($scroll/info/hbox/mass/title, "WEIGHT")
#	set_section_title($scroll/info/description/title, T.DESCRIPTION)
#	set_section_title($scroll/info/tags/title, "TAGS")

# --------------------------------------------------------------------------- #

# TODO: display information based on item state, not just data.
func update_item(state):
	var data = Data.fetch(state.id)
	
	$item_name/label.text = U.trans(data.name)
	$item_description/label.text = U.trans(data.description)
	$item_icon/icon.texture = Data.fetch_res([state.id, 'icon'])
	
	# TODO: replace this with tags/properties (entities will not have a single category)
#	$item_properties/category.text = data.category
	
	var value = state.get('value', data.value)
	$item_properties/value.text = U.comma(value)
	$item_properties/value/aster.show()
	
	# new stuff
	$hbox/weight/hbox/value.text = str(U.comma(data.mass * 1000), ' g') if data.mass < 1 else str(U.str_num(data.mass), ' kg')
	$hbox/value/hbox/value.text = U.comma(value)
	$scroll/info/hbox/mass/hbox/value.text = str(U.comma(data.mass * 1000), ' g') if data.mass < 1 else str(U.str_num(data.mass), ' kg')
	$scroll/info/hbox/value/hbox/value.text = U.comma(value * state.qty)
	$scroll/info/description/panel/value.text = U.trans(data.description)
	$scroll/info/tags/hbox/value.text = ', '.join(data.tags)

#	if state.qty == 1: $item_icon/quantity.hide()
#	else:
	$item_icon/quantity.show()
	$item_icon/quantity.text = str(state.qty)
		#var min_size = $item_icon/quantity.get_minimum_size().x
		#$item_icon/quantity.offset_left = -11 - min_size
