extends Node

func weighted_average(args):
	var total_value = 0
	var total_weight = 0
	for item in args:
		total_weight += item[1]
		total_value += item[0] * item[1]
	return round(total_value / total_weight)