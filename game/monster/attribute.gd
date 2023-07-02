extends RefCounted
class_name Attribute

const MIN_VALUE: float = 0.0
const MAX_VALUE: float = 1.0

const DEFAULT_PARAMS = {
	# the center of the bell curve
	mean = 0.5,
	# standard deviation from the mean. 68% of values fall within 1 standard
	# deviation of the mean (0.35 - 0.65), 95% within 2 (0.20 - 0.80), and 99.7%
	# within 3 (0.05 - 0.95).
	deviation = 0.15,
	# weight for interpolation between the mean and the average of the pet's
	# parents' values for this attribute (should be between 0 and 1 inclusive).
	# the result is used as the mean for `generate`.
	heritability = 0.5
}

var mean: float
var deviation: float
var heritability: float

var value: float:
	set(x): value = clamp(x, MIN_VALUE, MAX_VALUE)

func _init(
	params: Dictionary = {},
	_value: float = params.get('mean', DEFAULT_PARAMS.mean)
):
	params.merge(DEFAULT_PARAMS) # fill in any unset params
	for key in DEFAULT_PARAMS:
		set(key, params[key])
	value = _value

@warning_ignore("shadowed_global_identifier") # this doesn't actually work lol
func lerp(from: float, to: float) -> float:
	return lerpf(from, to, value)

func ilerp(from: int, to: int) -> int:
	return int(lerp(from, to + 1, value))


# =========================================================================== #
#                             G E N E R A T I O N                             #
# --------------------------------------------------------------------------- #

# generates a new value for the attribute and sets it.
func roll(overrides: Dictionary = {}, inheritance = null):
	var params = {}
	for p in [&'mean', &'deviation', &'heritability']:
		params[p] = overrides.get(p, get(p))
	
	# if we have an inherited value (presumed the average of our parents' values
	# for the attribute), use it to modify the mean.  `heritability` determines
	# the lerp weight (higher values are weighted toward `inheritance`)
	if inheritance != null:
		if Attribute.is_valid_value(inheritance):
			params.mean = lerpf(params.mean, inheritance, params.heritability)
		else: Log.warn(self, [
			"(roll) invalid inheritance, ignoring: ", inheritance])
	
	value = Attribute.generate(params.mean, params.deviation)

# --------------------------------------------------------------------------- #

# generates a value for an attribute using a normal distribution via `randfn`.
# we can't clamp because it would skew the distribution, so if we get a value
# outside the bounds (always technically possible with normal distributions),
# we throw it out and try again.
@warning_ignore("shadowed_variable")
static func generate(mean_: float, deviation_: float) -> float:
	var x = MIN_VALUE - 1 # start with an invalid value so the loop will run
	while x < MIN_VALUE or x > MAX_VALUE:
		x = randfn(mean_, deviation_)
	return x

# --------------------------------------------------------------------------- #

static func is_valid_value(x):
	return (x is int or x is float) and x >= MIN_VALUE and x <= MAX_VALUE
