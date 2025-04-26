class_name U
extends Node

const LNAME = "Utils"

## french/spanish/portuguese for "or" since that's a reserved keyword
static func ou(a: Variant, b: Variant): return b if !a else a
## specifically nullish coalescing (qq stands for ??)
static func qq(a: Variant, b: Variant): return b if a == null else a

# --------------------------------------------------------------------------- #

static func serialize_value(value: Variant, key: String = ''):
	if value == null:
		Log.warn(LNAME, ["serializing null value for key `", key, "`"])
	elif value is Array:
		return value.map(serialize_value)
	elif value is Vector2 or value is Vector2i:
		return format_vec(value)
	elif value is Object:
		if value.has_method('serialize'): return value.serialize()
		else: Log.error(LNAME, [
			"tried to serialize object without `serialize` method: ", value])
	else: return value

# --------------------------------------------------------------------------- #

## sets properties on the passed-in object using the given key and value, which
## correspond to some serialized state.
## delegates more complex behavior to `load_x` and `generate_x` functions on the
## object, where x matches the given key:
## - `generate` should create and return a value for the property and is used if
##   the passed-in value is null (we then set it on the object in this function).
## - `load` functions set the property on the object themselves, returning void.
##   these take in the passed-in value so they can manipulate or validate it.
static func deserialize_value(o: Object, value: Variant, key: String) -> void:
	var loader = str('load_', key)
	# if the key has a loader, just call it and trust it to initialize
	if o.has_method(loader): o.call(loader, value)
	elif value == null:
		var generator = str('generate_', key)
		if o.has_method(generator): o.set(key, o.call(generator))
	else:
		# if the value is a serialized vec, parse it here so we don't have
		# to implement a `load_x` function for it in the callee (unless it
		# needs to handle defaults or partial vecs)
		if is_serialized_vec(value): value = parse_vec(value)
		o.set(key, value)


# =========================================================================== #
#                               F I L E   I / O                               #
# --------------------------------------------------------------------------- #

## related scenes should be kept close to each other. a scene knows its own
## path, so we can find related scenes from that, rather than using THE
## TERRIBLE, HORRIBLE, NO GOOD ABSOLUTE FILEPATH. (rip preload, but it's better
## this way)
static func load_relative(own_fn, sib_fn, ext = "tscn"):
	var file = str(sib_fn, ".", ext)
	var path = own_fn.get_base_dir().path_join(file)
	Log.debug(LNAME, ["loading: ", path])
	return load(path)

# --------------------------------------------------------------------------- #

## TODO: test if passing a null to a parameter with default argument will
## override the default. ideally we should also be able to handle filenames that
## already have an extension.
static func load_resource(res_path, res_fn, ext = "png"):
	var file = str(res_fn, ".", ext)
	var path = res_path.path_join(file)
	Log.debug(LNAME, ["loading resource: ", path])
	return ResourceLoader.load(path)

# --------------------------------------------------------------------------- #

static func write_file(path, data):
	Log.info(LNAME, ["writing file: ", path])
	Log.verbose(LNAME, data)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

# --------------------------------------------------------------------------- #

static func read_file(path):
	Log.debug(LNAME, ["reading file: ", path])
	if !FileAccess.file_exists(path):
		Log.warn(LNAME, ["could not load `", path, "`: file does not exist!"])
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	file.close()
	# even for verbose, this is a little much, but i'll
	# leave it here in case we need to re-enable it
	Log.verbose(LNAME, data)
	return data


# =========================================================================== #
#                                 A R R A Y S                                 #
# --------------------------------------------------------------------------- #

## for event buttons (or dispatch buttons or whatever) we need to pack multiple
## arguments into an array, so here is an argument unpacker that i'm too lazy to
## write more than once
static func unpack(arg):
	if typeof(arg) == TYPE_ARRAY and arg.size() == 1:
		return arg[0]
	else: return arg

# --------------------------------------------------------------------------- #

## for functions that use argument arrays as bootleg varargs, because boxing a
## lone argument in an array[1] is a crime against fashion
static func pack(arg) -> Array:
	if typeof(arg) == TYPE_ARRAY: return arg
	elif arg == null: return []
	else: return [arg]

# --------------------------------------------------------------------------- #

static func aget(a: Array, i: int, default = null):
	return a[i] if a.size() > i and i >= 0 else default

# --------------------------------------------------------------------------- #

## takes a function that accepts a single element and returns a sort function
## that can be used with `Array.sort_custom` to sort elements ascending.
## also see `sort_by`.
static func sorter(fn: Callable):
	return func(a, b): return fn.call(a) < fn.call(b)

# --------------------------------------------------------------------------- #

static func sort_by(arr: Array, fn: Callable):
	arr.sort_custom(U.sorter(fn))

# --------------------------------------------------------------------------- #

## fn: (value: T, i: int) -> boolean
static func find_by(arr: Array, fn: Callable) -> int:
	for i in arr.size():
		if fn.call(arr[i], i): return i
	return -1
# --------------------------------------------------------------------------- #

## fn: (value: T, i: int) -> Variant
static func pick_by(arr: Array, fn: Callable) -> Variant:
	return arr[find_by(arr, fn)]

# --------------------------------------------------------------------------- #

## a map function that takes an index parameter
static func mapi(arr: Array, fn: Callable) -> Array:
	var mapped = []
	for i in arr.size(): mapped.push_back(fn.call(arr[i], i))
	return mapped

# --------------------------------------------------------------------------- #

static func reverse(arr: Array) -> Array:
	var copy = arr.duplicate()
	copy.reverse()
	return copy

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

## sugar for chaining `dict.get(a, dict.get(b, ...))`.
## update this comment if we ever actually use it
static func get_any(
	dict: Dictionary, options: Array[Variant], fallback: Variant = null
) -> Variant:
	for key in options: if dict.has(key): return dict[key]
	return fallback

# =========================================================================== #
#                                S T R I N G S                                #
# --------------------------------------------------------------------------- #

## for localized data (eg an object with localization strings as keys and the
## translated text as the value), grabs the relevant translation based on our
## Options global.
##
## TODO: add some logging here (though we don't receive any identifying info for
## the trans object, so maybe rethink this at some point)
static func trans(t) -> String:
	if t is String: return t
	if not t is Dictionary:
		Log.error(LNAME, ["(trans) unsupported input; must be string or dict. ", t])
		return ""
	# get_locale returns a full locale code like `en_US`, but we only care
	# about the language code
	var locale = TranslationServer.get_locale().split("_")[0]
	if locale in t: return t[locale]
	# the schema requires translatable text to always have an 'en' key
	return t.get('en', "")

# --------------------------------------------------------------------------- #

## just returns the string minus the first char
## maybe todo: double-check if sigil before trying to strip
static func strip_sigil(s):
	return s.substr(1)

# --------------------------------------------------------------------------- #

## TODO: make these translatable
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

## stringifies a number with commas inserted where appropriate
static func comma(num: int):
	var strnum = str(num)
	var i = strnum.length() - 3
	while i > 0:
		strnum = strnum.insert(i, ",")
		i -= 3
	return strnum

# --------------------------------------------------------------------------- #

## String.num(x) with sensible defaults for number of decimal places
static func str_num(x: float, decimals: int = -1) -> String: return (
	String.num(x, 3 if x < 1 else 2 if x < 10 else 1 if x < 100 else 0)
	if decimals < 0 else String.num(x, decimals)
)


# =========================================================================== #
#                                V E C T O R S                                #
# --------------------------------------------------------------------------- #

## a serialized vec is an { x, y } dict. 
static func is_serialized_vec(data: Variant, allow_partial = false):
	if !data is Dictionary: return false
	if allow_partial: return data.keys().all(func (k): return k in ['x', 'y'])
	return data.keys().size() == 2 and 'x' in data and 'y' in data

# --------------------------------------------------------------------------- #

## parse a vector from an { x, y } dict. throws an error if either of the props
## is missing and default is not supplied.
## data: Dictionary | null, default: Vector2 | null
static func parse_vec(data, default = null):
	var x = data.x if data != null and 'x' in data else default.x
	var y = data.y if data != null and 'y' in data else default.y
	return Vector2(x, y)

# --------------------------------------------------------------------------- #

static func format_vec(vec: Vector2, allow_partial = true):
	# don't serialize nan values or it will break json parsing
	if (JSON.stringify(vec.x) == 'nan' or JSON.stringify(vec.y) == 'nan'):
		return {} if allow_partial else { x = 0, y = 0 }
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
# same result as integer division, but convenient to have the same api
static func floor_div(a, b) -> int: return floor(float(a) / float(b))

# --------------------------------------------------------------------------- #

## generates a random float using a normal distribution via `randfn`.
## we can't clamp because it would skew the distribution, so if we get a value
## outside the bounds (always technically possible with normal distributions),
## we throw it out and try again.
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

## takes an array of [value, weight] tuples
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

# --------------------------------------------------------------------------- #

# 1 hour = 3600 seconds = 12 ticks
# 1 tick = 3600 / 12 seconds = 300 seconds
# 1 watt = 1 joule / second = 300 joules / tick

# 1 kcal = 4184 joules
# 1 joule = 1 / 4184 kcal
# 1 watt = 300 joules / tick = (300 / 4184) kcal / tick = 0.07 kcal/tick

## 1 watt = 0.07 kcal/tick
func watts_to_kcal_per_tick(watts: float): # should be ~0.0717017
	var seconds_per_hour = 60 * 60
	var seconds_per_tick = U.div(seconds_per_hour, Clock.TICKS_IN_HOUR)
	# 1 watt = 1 joule / second
	return watts * seconds_per_tick / Constants.JOULES_PER_KCAL

# 1 watt = 1 joule / second
# 1 day = 60 * 60 * 24 seconds = 86400 seconds
# 1 joule = 1 / 
## 1 watt = 0.07 kcal/tick
func watts_to_kcal_per_day(watts: float): # should be ~20.65
	var seconds_per_day = 60 * 60 * 24
	var joules_per_day = watts * seconds_per_day
	return joules_per_day / Constants.JOULES_PER_KCAL

# to calc energy capacity (in kcals), first find energy spend per day.
# this is a function of the animal's basal metabolic rate.
# bunny has mass of 3kg and bmr of 6 watts


# 1 day = 12 ticks * 24 hours = 288 ticks
# rabbit bmr = 6 watts = 0.07 * 6 kcal/tick = 0.43 kcal/tick = 123 kcal/day
