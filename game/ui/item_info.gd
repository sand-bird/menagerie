extends Control

# TODO: display information based on item state, not just data.
func update_item(state):
	var data = Data.fetch(state.id)
	
	$item_name/label.text = Utils.trans(data.name)
	$item_description/label.text = Utils.trans(data.description)
	$item_icon/icon.texture = Data.fetch_res([state.id, 'icon'])
	
	# TODO: replace this with tags/properties (entities will not have a single category)
	$item_properties/category.text = data.category
	
	var value = state.get('value', data.value)
	$item_properties/value.text = Utils.comma(value)
	$item_properties/value/aster.show()

	if state.qty == 1: $item_icon/quantity.hide()
	else:
		$item_icon/quantity.show()
		$item_icon/quantity.text = str(state.qty)
		var min_size = $item_icon/quantity.get_minimum_size().x
		#$item_icon/quantity.offset_left = -11 - min_size
