extends Node
class_name U

const log_name = "Utils"

# =========================================================================== #
#                               F I L E   I / O                               #
# --------------------------------------------------------------------------- #

# related scenes should be kept close to each other. a scene knows its own
# path, so we can find related scenes from that, rather than using THE
# TERRIBLE, HORRIBLE, NO GOOD ABSOLUTE FILEPATH. (rip preload, but it's better
# this way)
static func load_relative(own_fn, sib_fn, ext = "tscn"):
	var file = str(sib_fn, ".", ext)
	var path = own_fn.get_base_dir().path_join(file)
	Log.debug(log_name, ["loading: ", path])
	return load(path)

# --------------------------------------------------------------------------- #

# TODO: test if passing a null to a parameter with default argument will
# override the default. ideally we should also be able to handle filenames that
# already have an extension.
static func load_resource(res_path, res_fn, ext = "png"):
	var file = str(res_fn, ".", ext)
	var path = res_path.path_join(file)
	Log.debug(log_name, ["loading resource: ", path])
	return ResourceLoader.load(path)

# --------------------------------------------------------------------------- #

static func write_file(path, data):
	Log.info(log_name, ["writing file: ", path])
	Log.verbose(log_name, data)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

# --------------------------------------------------------------------------- #

static func read_file(path):
	Log.debug(log_name, ["reading file: ", path])
	if !FileAccess.file_exists(path):
		Log.warn(log_name, ["could not load `", path, "`: file does not exist!"])
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	file.close()
	# even for verbose, this is a little much, but i'll
	# leave it here in case we need to re-enable it
	Log.verbose(log_name, data)
	return data


# =========================================================================== #
#                                 A R R A Y S                                 #
# --------------------------------------------------------------------------- #

# for event buttons (or dispatch buttons or whatever) we need to pack multiple
# arguments into an array, so here is an argument unpacker that i'm too lazy to
# write more than once
static func unpack(arg):
	if typeof(arg) == TYPE_ARRAY and arg.size() == 1:
		return arg[0]
	else: return arg

# --------------------------------------------------------------------------- #

# for functions that use argument arrays as bootleg varargs, because boxing a
# lone argument in an array[1] is a crime against fashion
static func pack(arg) -> Array:
	if typeof(arg) == TYPE_ARRAY: return arg
	elif arg == null: return []
	else: return [arg]

# --------------------------------------------------------------------------- #

static func aget(a: Array, i: int, default = null):
	return a[i] if a.size() > i and i >= 0 else default

# --------------------------------------------------------------------------- #

# takes a function that accepts a single element and returns a sort function
# that can be used with `Array.sort_custom` to sort elements ascending.
# also see `sort_by`.
static func sorter(fn: Callable):
	return func(a, b): return fn.call(a) < fn.call(b)

# --------------------------------------------------------------------------- #

static func sort_by(arr: Array, fn: Callable):
	arr.sort_custom(U.sorter(fn))

# --------------------------------------------------------------------------- #

# fn: (value: T, i: int) -> boolean
static func find_by(arr: Array, fn: Callable) -> int:
	for i in arr.size():
		if fn.call(arr[i], i): return i
	return -1


# =========================================================================== #
#                            C O L L E C T I O N S                            #
# --------------------------------------------------------------------------- #

static func deep_equals(a, b) -> bool:
	if a is Array:
		if not b is Array: return false
		if a.size() != b.size(): return false
		for i in a.size(): if !deep_equals(a[i], b[i]): return false
	if a is Dictionary:
		if not b is Dictionary: return false
		if a.size() != b.size(): return false # rules out keys in b but not a
		for k in a:
			if not k in b: return false
			if !deep_equals(a[k], b[k]): return false
	else: return a == b
	return true


# =========================================================================== #
#                                S T R I N G S                                #
# --------------------------------------------------------------------------- #

# for localized data (eg an object with localization strings as keys and the
# translated text as the value), grabs the relevant translation based on our
# Options global.
#
# TODO: add some logging here (though we don't receive any identifying info for
# the trans object, so maybe rethink this at some point)
static func trans(t):
	if t is String: return t
	elif t is Dictionary:
		for i in ['locale/test', 'locale/fallback']:
			var locale = ProjectSettings.get(i)
			if locale in t: return t[locale]
	# the schema requires translatable text to always have an 'en' key
	return t.get('en', "")

# --------------------------------------------------------------------------- #

# just returns the string minus the first char
# maybe todo: double-check if sigil before trying to strip
static func strip_sigil(s):
	return s.substr(1)

# --------------------------------------------------------------------------- #

# TODO: make these translatable
static func ordinalize(num: int):
	var ordinal
	num = int(num)
	if num % 100 in range(11, 14):
		ordinal = "th"
	else:
		var ending = num % 10
		if ending == 1: ordinal = "st"
		elif ending == 2: ordinal = "nd"
		elif ending == 3: ordinal = "rd"
		else: ordinal = "th"
	return str(num) + ordinal

# --------------------------------------------------------------------------- #

# stringifies a number with commas inserted where appropriate
static func comma(num: int):
	var strnum = str(num)
	var i = strnum.length() - 3
	while i > 0:
		strnum = strnum.insert(i, ",")
		i -= 3
	return strnum


# =========================================================================== #
#                                V E C T O R S                                #
# --------------------------------------------------------------------------- #

# parse a vector from an { x, y } dict. throws an error if either of the props
# is missing and default is not supplied.
# data: Dictionary | null, default: Vector2 | null
static func parse_vec(data, default = null):
	var x = data.x if data != null and 'x' in data else default.x
	var y = data.y if data != null and 'y' in data else default.y
	return Vector2(x, y)

# --------------------------------------------------------------------------- #

static func format_vec(vec: Vector2):
	return { x = vec.x, y = vec.y }

# --------------------------------------------------------------------------- #

static func vmin(a, b):
	return Vector2(min(a.x, b.x), min(a.y, b.y))

# --------------------------------------------------------------------------- #

static func vmax(a, b):
	return Vector2(max(a.x, b.x), max(a.y, b.y))


# =========================================================================== #
#                                   M A T H                                   #
# --------------------------------------------------------------------------- #

# convenience functions to do floating-point division on integers...
static func div(a, b) -> float: return float(a) / float(b)
# ...and ceil the result (this saves a paren over ceil(U.div()))
static func ceil_div(a, b) -> int: return ceil(float(a) / float(b))
# ...and round the result
static func round_div(a, b) -> int: return round(float(a) / float(b))

# --------------------------------------------------------------------------- #

# generates a random float using a normal distribution via `randfn`.
# we can't clamp because it would skew the distribution, so if we get a value
# outside the bounds (always technically possible with normal distributions),
# we throw it out and try again.
static func randfn_range(
	mean: float, deviation: float, min: float = 0, max: float = 1
) -> float:
	var x = min - 1 # start with an invalid value so the loop will run
	while x < min or x > max:
		x = randfn(mean, deviation)
	return x

# --------------------------------------------------------------------------- #

static func avg(args: Array[float]):
	var total_value = 0
	for item in args:
		total_value += item
	return round(float(total_value) / args.size())

# --------------------------------------------------------------------------- #

# takes an array of [value, weight] tuples
static func weighted_mean(args: Array) -> float:
	var total_value: float = 0
	var total_weight: float = 0
	for item in args:
		total_weight += item[1]
		total_value += (item[0] * item[1])
	if total_weight == 0: return 0
	return total_value / total_weight

# --------------------------------------------------------------------------- #

static func rand_tri(a, b, c):
	var u = randf()
	var f = float(c - a) / float(b - a)
	if u < f:
		return round(a + sqrt(u * (b - a) * (c - a)))
	else:
		return round(b - sqrt((1 - u) * (b - a) * (b - c)))

# --------------------------------------------------------------------------- #

static func rand_poisson(a, b, lambda):
	var k = 0;
	var target = exp(-lambda)
	var p = randf()
	while (p > target):
		p *= randf()
		k += 1
	return clamp(k, a, b)

# --------------------------------------------------------------------------- #

static func rand_parab(a, b, c):
	var x = randf()
	var k = float(c - a) / float(b - a)
	if x < k:
		return round(
			c + pow(
				((2*x*(a-b) - 3) * pow((a-c), 2) - pow(c,3)) * (1 / 9),
				1.0/3.0
			)
		)
	else: return b
