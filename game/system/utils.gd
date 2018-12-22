extends Node

# =========================================================== #
#                       F I L E   I / O                       #
# ----------------------------------------------------------- #

# related scenes should be kept close to each other. a scene
# knows its own filepath, so we can find related scenes from
# that, rather than using THE TERRIBLE, HORRIBLE, NO GOOD
# ABSOLUTE FILEPATH. (rip preload, but it's better this way)
static func load_relative(own_fn, sib_fn, ext = "tscn"):
	var file = str(sib_fn, ".", ext)
	var path = own_fn.get_base_dir().plus_file(file)
	Log.debug(Utils, ["loading: ", path])
	return load(path)

# -----------------------------------------------------------

# TODO: test if passing a null to a parameter with default
# argument will override the default. ideally we should also
# be able to handle filenames that already have an extension.
static func load_resource(res_path, res_fn, ext = "png"):
	var file = str(res_fn, ".", ext)
	var path = res_path.plus_file(file)
	Log.debug(Utils, ["loading resource: ", path])
	return ResourceLoader.load(path)

# -----------------------------------------------------------

func write_file(path, data):
	Log.info(Utils, ["writing file: ", path])
	Log.verbose(Utils, data)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(to_json(data))
	file.close()

# -----------------------------------------------------------

func read_file(path):
	Log.info(Utils, ["reading file: ", path])
	var file = File.new()
	if !file.file_exists(path): 
		Log.warn(Utils, ["could not load `", path, "`: file does not exist!"])
		return null
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	Log.verbose(Utils, data)
	return data


# =========================================================== #
#                         A R R A Y S                         #
# ----------------------------------------------------------- #

# for event buttons (or dispatch buttons or whatever) we need
# to pack 1+ arguments into an array, so here is an argument
# unpacker that i'm too lazy to write more than once
static func unpack(arg):
	if typeof(arg) == TYPE_ARRAY and arg.size() == 1:
		return arg[0]
	else: return arg

# -----------------------------------------------------------

# for functions that use argument arrays as bootleg varargs,
# because boxing a lone argument in an array[1] is a crime
# against fashion
static func pack(arg):
	if typeof(arg) == TYPE_ARRAY: return arg
	else: return [arg]

# -----------------------------------------------------------

# honestly can't believe i have to implement this
static func slice(array, first, size):
	var subarray = []
	var actual_size = min(array.size() - first, size)
	for i in actual_size: subarray.push_back(array[first + i])
	return subarray


# =========================================================== #
#                        S T R I N G S                        #
# ----------------------------------------------------------- #

# for localized data (eg an object with localization strings
# as keys and the translated text as the value), grabs the
# relevant translation based on our Options global.
#
# TODO: add some logging here (though we don't receive any
# identifying info for the trans object, so maybe rethink
# this at some point)
func trans(t):
	if typeof(t) == TYPE_STRING:
		return t
	elif typeof(t) == TYPE_DICTIONARY:
		if t.has(Options.get_lang()):
			return t[Options.get_lang()]
		elif t.has(Options.fallback_lang):
			return t[Options.fallback_lang]
	return ""

# -----------------------------------------------------------

# just returns the string minus the first char
# maybe todo: double-check if sigil before trying to strip
static func strip_sigil(s):
	return s.substr(1, s.length() - 1)

# -----------------------------------------------------------

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

# -----------------------------------------------------------

# stringifies a number with commas inserted where appropriate
static func comma(num):
	var strnum = str(num)
	var i = strnum.length() - 3
	while i > 0:
		strnum = strnum.insert(i, ",")
		i -= 3
	return strnum


# =========================================================== #
#                        V E C T O R S                        #
# ----------------------------------------------------------- #


static func is_horizontal(v):
	return v.x and !v.y

static func is_vertical(v):
	return v.y and !v.x

static func is_diagonal(v):
	return v.x and v.y


static func veq(a, b):
	var xeq = round(a.x) == round(b.x)
	var yeq = round(a.y) == round(b.y)
	return (xeq && yeq)

# -----------------------------------------------------------

static func vmin(a, b):
	return Vector2(min(a.x, b.x), min(a.y, b.y))

# -----------------------------------------------------------

static func vmax(a, b):
	return Vector2(max(a.x, b.x), max(a.y, b.y))

# -----------------------------------------------------------

static func vrandi(vec):
	return Vector2(randi_qty(int(vec.x)), randi_qty(int(vec.y)))

# -----------------------------------------------------------

# Vector2.clamped() clamps the vector's length, but we want to
# clamp the vector between a min vector and a max one
static func vclamp(a, b, c):
	return Vector2(clamp(a.x, b.x, c.x), clamp(a.y, b.y, c.y))

# -----------------------------------------------------------

# sugar for Vector2.linear_interpolate(Vector2, float)
static func vlerp(a, b, w):
	return a.linear_interpolate(b, w)

# -----------------------------------------------------------

static func vsign(vec):
	return Vector2(sign(vec.x), sign(vec.y))


# =========================================================== #
#                           M A T H                           #
# ----------------------------------------------------------- #

static func avg(args):
	var total_value = 0
	for item in args:
		total_value += item
	return round(float(total_value) / args.size())

# -----------------------------------------------------------

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

# -----------------------------------------------------------

static func weighted_avg2(args):
	var total = 0
	for item in args:
		total += item[0] * item[1]
	return round(total)

# -----------------------------------------------------------

# returns a random value within {threshold} of {anchor}
static func randi_thresh_raw(anchor, threshold):
	return randi_range(anchor - threshold, anchor + threshold)

# -----------------------------------------------------------

# threshold should be a between 0 and 1 exclusive
static func randi_thresh(anchor, threshold):
	var raw_thresh = round(anchor * threshold)
	return randi_range(anchor - raw_thresh, anchor + raw_thresh)

# -----------------------------------------------------------

static func randi_range(minimum, maximum):
	return minimum + randi() % (int(maximum) - int(minimum) + 1)

# -----------------------------------------------------------

static func randi_to(maximum):
	return randi() % (int(maximum) + 1)

# -----------------------------------------------------------

static func rand_tri(a, b, c):
	var u = randf()
	var f = float(c - a) / float(b - a)
	if u < f:
		return round(a + sqrt(u * (b - a) * (c - a)))
	else: 
		return round(b - sqrt((1 - u) * (b - a) * (b - c)))
	pass

# -----------------------------------------------------------

static func rand_poisson(a, b, lambda):
	var k = 0;
	var target = exp(-lambda)
	var p = randf()
	while (p > target):
		p *= randf()
		k += 1
	return clamp(k, a, b)

# -----------------------------------------------------------

static func rand_parab(a, b, c):
	var x = randf()
	var k = float(c - a) / float(b - a)
	if x < k:
		return round(c + pow(((2*x*(a-b) - 3) * pow((a-c), 2) - pow(c,3)) * (1 / 9), 1.0/3.0))
	else: return b
