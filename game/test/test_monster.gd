extends GutTest

var g = preload("res://garden/garden.tscn").instantiate()

func test_catabolize():
	var m = Monster.new({}, g)
	m.scoses = 1
	m.porps = 1
	m.fobbles = 1
	var energy = m.catabolize(12)
	
	prints({ energy = energy, scoses = m.scoses, porps = m.porps, fobbles = m.fobbles })
