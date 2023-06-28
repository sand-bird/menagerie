extends RefCounted
class_name Traits
"""
traits are a collection of values that influence various aspects of a monster's
behavior.  taken as a whole, they represent the monster's personality.

each monster has a Traits object which stores state for the current value of
all the monster's traits, and is initialized within the Monster constructor.

the Traits constructor takes a serialized traits object (a dict of trait names
to values). for each trait without a supplied value, we roll a new value for it.

rolling traits is static; initializing a Traits object is only necessary to
store state. 

the generation parameters for each trait can be overridden in monster data
definitions (ie, the mean iq for a slowpoke should be much less than 0.5).

requirements:
	- setting the value for a trait clamps it to the trait's bounds
	- traits can inherit or override default values for mean, deviation, and heritability
	- initialization should roll new values for each trait that isn't passed to
	  the constructor (and clamp values for traits that are)
	- initialization should override traits' mean, deviation, and heritability
	  params based on the monster's data definition
"""

# =========================================================================== #
#                          C O N F I G U R A T I O N                          #
# --------------------------------------------------------------------------- #

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
	# parents' values for this trait (should be between 0 and 1 inclusive).
	# the result is used as the mean for `generate`.
	heritability = 0.5
}

# source of truth for which traits to serialize, deserialize, and generate.
# we also declare variables for these way at the bottom of the file, so make
# sure to add new traits to both places.  if not, it will probably still work,
# but clamping won't happen and the trait won't show up in autocomplete.
#
# value should be a dict (but can be empty).  this is where we configure any
# non-default generation parameters for each trait; any we don't supply here
# will fall back to DEFAULT_PARAMS.
const TRAITS = {
	# INT
	# ---
	# heritable sticky trait governing how quickly a pet learns skills and how
	# likely it is to undertake complex actions.
	#
	# note: human iq has a mean of 100 and a standard deviation of 15, which
	# means we can map monster iq to human iq as follows (assuming 0.15 st.dev):
	# monster | 0.0 | .05 | .20 | .35 | .50 | .65 | .80 | .95 | 1.0
	# human   |  50 |  55 |  60 |  85 | 100 | 115 | 130 | 145 | 150
	#
	# with a standard deviation of 0.1, monster iq would run from 15 to 175:
	# monster | 0.0 | .10 | .20 | .30 | .40 | .50 | .60 | .70 | .80 | .90 | 1.0
	# human   |  15 |  30 |  45 |  60 |  85 | 100 | 115 | 130 | 145 | 160 | 175
	iq = { heritability = 0.9 }, # dim / perspicacious
	# accumulative trait reflecting how much a pet has learned over its life.
	# exists to boost the INT attribute. always starts at 0.
	learning = { mean = 0, deviation = 0, heritability = 0 }, # callow / worldly
	
	# VIT
	# ---
	# accumulative trait reflecting good feeding. exists to boost VIT.
	nutrition = { deviation = 0.05, heritability = 0 }, # malnourished / sleek
	# affects energy consumption and regeneration (higher vigor means energy
	# recovers faster and drains slower). increased by expending energy.
	vigor = { mean = 0.4 }, # sickly / hearty
	
	# CON
	# ---
	# governs the success of composure rolls (overcoming a mood hit).
	# increased by encouraging a pet during a composure roll or praising it
	# after a successful roll.
	composure = { mean = 0.3 }, # neurotic / composed
	# governs how long it takes for a pet to start suffering mood hits as a
	# result of unmet needs (drives out of equilibrium).
	# increased by correcting drives after patience procs but before a mood hit.
	patience = { mean = 0.4 }, # antsy / stoic
	# affects the probability of patience and composure procs, and the magnitude
	# of mood losses from patience procs (unmet needs).
	fortitude = {},
	
	
	# CHA
	# ---
	# "social fitness"
	# governs how likely a pet is to undertake social actions (via utility mods).
	# increased by performing social actions with positive results.
	# TODO: unclear, rethink this & "extraversion" w/r/t the social meter
	confidence = { mean = 0.4 }, # timid / gregarious
	# boosts CHA attribute. maybe also affects other pets' preferences.
	# heritable and can be modified (maybe temporarily) by items.
	beauty = { heritability = 0.8 }, # unsightly / lustrous
	# accumulative trait. affects mood losses from social events, and mood-based
	# utility modifiers on social actions. ("A high POISE monster will be less
	# likely to take out its bad mood on others, and won't let negative inter-
	# actions affect its MOOD as much.")
	poise = { mean = 0.1, heritability = 0.2 }, # histrionic / poised
	
	# AMI
	# ---
	# inverse multiplier for negative preferences; low humility pets are more
	# prone to disliking things and other monsters.
	# linear transform to a (0, 2) multiplier: 2 - (humility * 2)
	# when a preference change is negative, we modify it by the humility multi.
	humility = {}, # haughty / humble
	# used as a component of sympathy calculations, alongside preference.
	# converted to a (-1, 1) multiplier: (kindness * 2) - 1
	# low kindness results in a negative multiplier, meaning actions that lower
	# the target's mood will increase the actor's.
	kindness = { deviation = 0.2 }, # wicked / saintly
	# multiplies the target's mood change for sympathy calculations.
	# convert to a (0, 2) multplier: empathy * 2
	empathy = { deviation = 0.2 }, # autistic / empathic
	
	# SPR
	# ---
	# cumulative sample of the pet's mood.  should be sampled once per day at a
	# random time each day.
	happiness = { heritability = 1, deviation = 0.05 }, # depressed / jubilant
	# modifies how likely the pet is to accept commands. increased by discipline.
	loyalty = { mean = 0.15, heritability = 0.2, deviation = 0.08 }, # faithless / steadfast
	# strictly accumulative; measures positive change in traits.  this should be
	# updated whenever we update a trait.
	actualization = { mean = 0, heritability = 0, deviation = 0 },
	
	# N/A
	# ---
	# determines how fast the pet's belly drains and how much food restores it.
	# higher appetite means it drains faster and food is less filling.
	appetite = { deviation = 0.1, heritability = 0.3 }, # anorexic / gluttonous
	# determines the pet's preferred energy level. higher pep = lower preferred
	# energy
	pep = {}, # indolent / energetic
	# modifies the effect of preference on utility calculations; sticky
	openness = {},
}


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func _init(data: Dictionary, param_overrides = {}, inherited_traits = {}):
	for t in TRAITS:
		if t in data: self[t] = data[t]
		else:
			var overrides = param_overrides.get(t, {})
			var inheritance = inherited_traits.get(t)
			self[t] = roll_trait(t, overrides, inheritance)

# --------------------------------------------------------------------------- #

func serialize():
	var data = {}
	for key in TRAITS:
		data[key] = self[key]
	return data


# =========================================================================== #
#                             G E N E R A T I O N                             #
# --------------------------------------------------------------------------- #

# generates a value for a trait using a normal distribution via `randfn`.
# we can't clamp because it would skew the distribution, so if we get a value
# outside the bounds (always technically possible with normal distributions),
# we throw it out and try again.
static func generate(mean: float, deviation: float) -> float:
	var x = MIN_VALUE - 1 # start with an invalid value so the loop will run
	while x < MIN_VALUE or x > MAX_VALUE:
		x = randfn(mean, deviation)
	return x

# --------------------------------------------------------------------------- #

static func roll_trait(
	t: String, overrides: Dictionary = {}, inheritance = null
) -> float:
	const LNAME = 'Traits'
	if t not in TRAITS:
		Log.error(LNAME, ["(roll_trait) invalid trait: ", t])
		return 0.0
	
	var trait_params = TRAITS.get(t, {})
	var params = {}
	# try to fetch each param from overrides, then trait config, then defaults
	for p in [&'mean', &'deviation', &'heritability']:
		params[p] = overrides.get(p, trait_params.get(p, DEFAULT_PARAMS.get(p)))
	
	# if we have an inherited value (presumed the average of our parents' values
	# for the trait), use it to modify the mean.  `heritability` determines the
	# lerp weight (higher values are weighted toward `inheritance`)
	var mean = params.mean
	if inheritance != null:
		if is_trait(inheritance):
			mean = lerpf(params.mean, inheritance, params.heritability)
		else: Log.warn(LNAME, [
			"(roll_trait) invalid inheritance, ignoring: ", inheritance])
	
	return generate(params.mean, params.deviation)

# --------------------------------------------------------------------------- #

static func is_trait(x):
	return (x is int or x is float) and x >= 0.0 and x <= 1.0


# =========================================================================== #
#                                  S T A T E                                  #
# --------------------------------------------------------------------------- #
# declare properties for each trait.  this has two benefits: code completion,
# and bounds clamping.  unfortunately we need to declare a separate setter
# for every one of these because the setter has to reference the variable it's
# setting :(

func clamp_trait(value: float):
	return clamp(value, MIN_VALUE, MAX_VALUE)

# INT
var iq: float:
	set(x): iq = clamp_trait(x)
var learning: float:
	set(x): x = clamp_trait(x)
# VIT
var nutrition: float:
	set(x): nutrition = clamp_trait(x)
var vigor: float:
	set(x): vigor = clamp_trait(x)
# CON
var composure: float:
	set(x): composure = clamp_trait(x)
var patience: float:
	set(x): patience = clamp_trait(x)
var fortitude: float:
	set(x): fortitude = clamp_trait(x)
# CHA
var confidence: float:
	set(x): confidence = clamp_trait(x)
var beauty: float:
	set(x): beauty = clamp_trait(x)
var poise: float:
	set(x): poise = clamp_trait(x)
# AMI
var humility: float:
	set(x): humility = clamp_trait(x)
var kindness: float:
	set(x): kindness = clamp_trait(x)
var empathy: float:
	set(x): empathy = clamp_trait(x)
# SPI
var happiness: float:
	set(x): happiness = clamp_trait(x)
var loyalty: float:
	set(x): loyalty = clamp_trait(x)
var actualization: float:
	set(x): actualization = clamp_trait(x)
# N/A
var openness: float:
	set(x): openness = clamp_trait(x)
var appetite: float:
	set(x): appetite = clamp_trait(x)
var pep: float:
	set(x): pep = clamp_trait(x)
var extraversion: float:
	set(x): extraversion = clamp_trait(x)
