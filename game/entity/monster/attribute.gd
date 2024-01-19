class_name Attribute
extends RefCounted
const LNAME = &"Attribute"

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

var value: float:
	set(x): value = clamp(x, MIN_VALUE, MAX_VALUE)

var variance:
	set(_x): push_error("cannot set attribute variance")
	get: return (value - DEFAULT_PARAMS.mean) / DEFAULT_PARAMS.deviation

# --------------------------------------------------------------------------- #

# first arg is either a float (if directly setting) or a params dict
func _init(arg = {}, inheritance = null):
	if arg is float or arg is int: value = arg
	elif arg is Dictionary:
		value = Attribute.generate(arg, inheritance)
	else: # note: using `self` here will throw an error in Logger
		Log.error(LNAME, ["invalid input: ", arg])

# =========================================================================== #
#                                  U S A G E                                  #
# --------------------------------------------------------------------------- #

# linearly interpolates between `from` and `to` using the attribute's value as
# the weight.  effectively this scales the attribute, and is very useful for
# converting attributes into multipliers, eg `lerp(0, 2)`.
@warning_ignore("shadowed_global_identifier") # this doesn't actually work lol
func lerp(from: float, to: float) -> float:
	return lerpf(from, to, value)

func ilerp(from: int, to: int) -> int:
	return int(lerp(from, to + 1, value))

# --------------------------------------------------------------------------- #

# scales an input value (generally a change to a monster's drive) based on the
# attribute's value.  assuming the attribute's value is above 0.5, this applies
# a positive multiplier if `x` is positive and an inverse multiplier if it is
# negative, increasing gains and mitigating losses.
# the multiplier is proportionate to the attribute's value; thus, if its value
# less than 0.5, the multiplier is flipped, decreasing gains and increasing
# losses.  if the attribute's value is exactly 0.5, the multiplier is always 1.
#
# the `scale` parameter scales the multiplier: with `scale = 2`, the maximum
# attribute value of 1.0 will double the input if it is positive and halve it if
# it is negative, while the minimum value of 0.0 would have the opposite effect.
# with `scale = 3`, we triple or third it, etc.  `scale` must be at least 1.
# 
# the `invert` parameter flips the effect, so that attribute values greater than
# 0.5 will DEcrease gains and INcrease losses, and vice versa for values <0.5.
func modify(x: float, scale: float, invert: bool = false):
		assert(scale >= 1)
		var multiplier = scale ** self.lerp(-1, 1)
		var dampener = scale ** self.lerp(1, -1)
		var should_multiply = x < 0 if invert else x > 0
		return x * multiplier if should_multiply else x * dampener


# =========================================================================== #
#                             G E N E R A T I O N                             #
# --------------------------------------------------------------------------- #

static func generate(custom_params: Dictionary = {}, inheritance = null):
	var params = DEFAULT_PARAMS.duplicate()
	# ensure all required params are present
	params.merge(custom_params, true)
	# if we have an inherited value (presumed the average of our parents' values
	# for the attribute), use it to modify the mean.  `heritability` determines
	# the lerp weight (higher values are weighted toward `inheritance`)
	var mean = params.mean
	if inheritance != null:
		if is_valid_value(inheritance):
			mean = lerpf(mean, inheritance, params.heritability)
		else: Log.warn(LNAME, [
			"(roll) invalid inheritance, ignoring: ", inheritance])
	
	return U.randfn_range(mean, params.deviation, MIN_VALUE, MAX_VALUE)

# --------------------------------------------------------------------------- #

static func is_valid_value(x):
	return (x is int or x is float) and x >= MIN_VALUE and x <= MAX_VALUE
