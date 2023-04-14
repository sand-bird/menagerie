extends Control

func update_item(id, qty = 0):
	var item_data = Data.fetch(id)

	$item_name/label.text = Utils.trans(item_data.name)
	$item_description/label.text = Utils.trans(item_data.description)
	$item_icon/icon.texture = Data.fetch_res([id, "icon"])
	$item_properties/category.text = item_data.category
	$item_properties/value.text = Utils.comma(item_data.value)
	$item_properties/value/aster.show()

	if qty == 1: $item_icon/quantity.hide()
	else:
		$item_icon/quantity.show()
		$item_icon/quantity.text = str(qty)
		var min_size = $item_icon/quantity.get_minimum_size().x
		$item_icon/quantity.offset_left = -7 - min_size
