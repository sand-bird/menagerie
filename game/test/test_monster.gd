extends GutTest

var g = preload("res://garden/garden.tscn").instantiate()

func test_init():
	var m = Monster.new({}, g)
