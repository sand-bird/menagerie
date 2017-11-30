extends Node

static func weighted_average(args):
	var total_value = 0
	var total_weight = 0
	for item in args:
		total_weight += item[1]
		total_value += item[0] * item[1]
	return round(total_value / total_weight)

# returns a random value within {threshold} of {anchor}
static func randi_thresh_raw(anchor, threshold):
	return randi_range(anchor - threshold, anchor + threshold)

# threshold should be a between 0 and 1 exclusive
static func randi_thresh(anchor, threshold):
	var raw_thresh = round(anchor * threshold)
	return randi_range(anchor - raw_thresh, anchor + raw_thresh)

static func randi_range(minimum, maximum):
	return randi() % (maximum + minimum + 1)

static func randi_qty(maximum):
	return randi() % maximum + 1