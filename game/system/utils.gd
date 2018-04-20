extends Node

# --------- #
#  STRINGS  #
# --------- #

static func capitalize(string):
	var new_str = string.to_lower()
	return  new_str[0].to_upper() + new_str.substr(1, new_str.length())

static func ordinalize(num):
	var ord
	num = int(num)
	if num % 100 in range(11, 14):
		ord = "th"
	else:
		var ending = num % 10
		if ending == 1: ord = "st"
		elif ending == 2: ord = "nd"
		elif ending == 3: ord = "rd"
		else: ord = "th"
	return str(num) + ord

# --------- #
#  VECTORS  #
# --------- #

static func veq(a, b):
	var xeq = round(a.x) == round(b.x)
	var yeq = round(a.y) == round(b.y)
	return (xeq && yeq)

static func vmin(a, b):
	return Vector2(min(a.x, b.x), min(a.y, b.y))

static func vmax(a, b):
	return Vector2(max(a.x, b.x), max(a.y, b.y))

static func vclamp(vec, vmin, vmax):
	return Vector2(clamp(vec.x, vmin.x, vmax.x), clamp(vec.y, vmin.y, vmax.y))

static func vrandi(vec):
	return Vector2(randi_qty(int(vec.x)), randi_qty(int(vec.y)))

static func vabs(vec):
	return vec * vsign(vec)

static func vlerp(a, b, w):
	return Vector2(lerp(a.x, b.x, w), lerp(a.y, b.y, w))

static func vsign(vec):
	return Vector2(sign(vec.x), sign(vec.y))

static func vround(vec):
	return Vector2(round(vec.x), round(vec.y))

static func vceil(vec):
	return Vector2(ceil(vec.x), ceil(vec.y))

static func vfloor(vec):
	return Vector2(floor(vec.x), floor(vec.y))


# ------ #
#  MATH  #
# ------ #

static func avg(args):
	var total_value = 0
	for item in args:
		total_value += item
	return round(float(total_value) / args.size())

static func weighted_avg(args):
	var total_value = 0
	var total_weight = 0
	for item in args:
		total_weight += item[1]
		total_value += (item[0] * item[1])
#	print("total weight: ", total_weight, " | total value: ", total_value,
#		" | arg1: ", args[0][0], " | arg1 value: ", (args[0][0] * args[0][1]), 
#		" | result: ", round(float(total_value) / float(total_weight)))
	var result = float(total_value) / float(total_weight)
	if (randf() > 0.50): return round(result)
	else: return floor(result)

static func weighted_avg2(args):
	var total = 0
	for item in args:
		total += item[0] * item[1]
	return round(total)

# returns a random value within {threshold} of {anchor}
static func randi_thresh_raw(anchor, threshold):
	return randi_range(anchor - threshold, anchor + threshold)

# threshold should be a between 0 and 1 exclusive
static func randi_thresh(anchor, threshold):
	var raw_thresh = round(anchor * threshold)
	return randi_range(anchor - raw_thresh, anchor + raw_thresh)

static func randi_range(minimum, maximum):
	return minimum + randi() % (maximum - minimum + 1)

static func randi_qty(maximum):
	return randi() % (maximum + 1)

static func rand_tri(a, b, c):
	var u = randf()
	var f = float(c - a) / float(b - a)
	if u < f:
		return round(a + sqrt(u * (b - a) * (c - a)))
	else: 
		return round(b - sqrt((1 - u) * (b - a) * (b - c)))
	pass

static func rand_poisson(a, b, lambda):
	var k = 0;
	var target = exp(-lambda)
	var p = randf()
	while (p > target):
		p *= randf()
		k += 1
	return clamp(k, a, b)

static func rand_parab(a, b, c):
	var x = randf()
	var k = float(c - a) / float(b - a)
	if x < k:
		return round(c + pow(((2*x*(a-b) - 3) * pow((a-c), 2) - pow(c,3)) * (1 / 9), 1.0/3.0))
	else: return b
