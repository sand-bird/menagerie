extends Action

# action to grab an item and then put it somewhere else.
# get_item(item) -> put_item(item, target)

# on each tick, check if still has item - fail if item is lost

# what's the utility calculus here? when would a pet want to do this?
# either the item or the target could advertise put_item. 

# drive calculus depends on get_item, which prepends necessary steps to pick up
# the item (eg approaching, stealing, collecting from object, etc),
# and put_item, which prepends moving to the target

func _init(m, item, target).(m):
	pass
