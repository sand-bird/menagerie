extends RefCounted
class_name Attributes
"""
attributes are a collection of values that influence various aspects of a
monster's behavior.  taken as a whole, they represent the monster's personality.

this class is the source of truth for which attributes a monster has and what
their configuration parameters should be (used when generating a new value for
that attribute).  it's also responsible for serializing and deserializing all of
a monster's attributes, and for computing the special "index" attributes which
summarize a monster's regular attributes.

the generation parameters for each attribute can also be overridden in monster
data definitions (ie, the mean iq for a slowpoke should be much less than 0.5).

each monster has an Attributes object which is initialized within the Monster
constructor.  the Attributes constructor takes a dict of serialized attribute
values, loads these, and rolls the rest.

requirements:
- setting the value for a attribute clamps it to the attribute's bounds
- attributes can inherit or override default values for mean, deviation, and
  heritability
- initialization should roll new values for each attribute that isn't passed to
  the constructor (and clamp values for attributes that are)
- initialization should override attributes' mean, deviation, and heritability
  params based on the monster's data definition
"""

# =========================================================================== #
#                          C O N F I G U R A T I O N                          #
# --------------------------------------------------------------------------- #

# source of truth for which attributes to serialize, deserialize, and generate.
# we also declare variables for these way at the bottom of the file, so make
# sure to add new attributes to both places.  if not, it will probably still
# work, but the attributes won't show up in autocomplete.
#
# value should be a dict (but can be empty).  this is where we configure any
# non-default generation parameters for each trait; any we don't supply here
# will fall back to Attribute.DEFAULT_PARAMS.
const ATTRIBUTES = {
# INT
# ---
# heritable sticky attribute governing how quickly a pet learns skills and how
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
# dim / perspicacious
iq = { heritability = 0.9 },
# accumulative attribute reflecting how much a pet has learned over its life.
# exists to boost the INT attribute. always starts at 0.
# callow / worldly
learning = { mean = 0, deviation = 0, heritability = 0 },

# accumulative attribute reflecting good feeding. exists to boost VIT.
# malnourished / sleek
nutrition = { deviation = 0.15, heritability = 1 },
# affects energy consumption and regeneration (higher vigor means energy
# recovers faster and drains slower). increased by expending energy.
 # sickly / hearty
vigor = { mean = 0.4 },

# CON
# ---
# governs the success of composure rolls (overcoming a mood hit).
# increased by encouraging a pet during a composure roll or praising it
# after a successful roll.
# neurotic / composed
composure = { mean = 0.3 },
# governs how long it takes for a pet to start suffering mood hits as a
# result of unmet needs (drives out of equilibrium).
# increased by correcting drives after patience procs but before a mood hit.
# antsy / stoic
patience = { mean = 0.4 },
# affects the probability of patience and composure procs, and the magnitude
# of mood losses from patience procs (unmet needs).
fortitude = {},

# CHA
# ---
# "social fitness"
# governs how likely a pet is to undertake social actions (via utility mods).
# increased by performing social actions with positive results.
# TODO: unclear, rethink this & "extraversion" w/r/t the social meter
# timid / gregarious
confidence = { mean = 0.4 },
# boosts CHA attribute. maybe also affects other pets' preferences.
# heritable and can be modified (maybe temporarily) by items.
# unsightly / lustrous
beauty = { heritability = 0.8 },
# accumulative attribute. affects mood losses from social events, and mood-based
# utility modifiers on social actions. ("A high POISE monster will be less
# likely to take out its bad mood on others, and won't let negative inter-
# actions affect its MOOD as much.")
# histrionic / poised
poise = { mean = 0.3, heritability = 0.2 },

# AMI
# ---
# inverse multiplier for negative preferences; low humility pets are more
# prone to disliking things and other monsters.
# linear transform to a (0, 2) multiplier: 2 - (humility * 2)
# when a preference change is negative, we modify it by the humility multi.
# haughty / humble
humility = {},
# used as a component of sympathy calculations, alongside preference.
# converted to a (-1, 1) multiplier: (kindness * 2) - 1
# low kindness results in a negative multiplier, meaning actions that lower
# the target's mood will increase the actor's.
# wicked / saintly
kindness = { deviation = 0.2 },
# multiplies the target's mood change for sympathy calculations.
# convert to a (0, 2) multplier: empathy * 2
empathy = { mean = 0.4, deviation = 0.2 }, # autistic / empathic

# SPR
# ---
# cumulative sample of the pet's mood.  should be sampled once per day at a
# random time each day. # depressed / jubilant
happiness = { heritability = 1, deviation = 0.2 },
# modifies how likely the pet is to accept commands. increased by discipline.
# faithless / steadfast
loyalty = { mean = 0.15, heritability = 0.2, deviation = 0.08 },
# strictly accumulative; measures positive change in attributes.  this should be
# updated whenever we update a attribute.
actualization = { mean = 0, heritability = 0, deviation = 0 },

# N/A
# ---
# determines how fast the pet's belly drains and how much food restores it.
# higher appetite means it drains faster and food is less filling.
# anorexic / gluttonous
appetite = { deviation = 0.1, heritability = 0.3 },
# determines the pet's preferred energy level. higher pep = lower preferred
# energy # indolent / energetic
pep = {},
# modifies the effect of preference on utility calculations; sticky
openness = {},
extraversion = {}
}


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

# source of truth for which attributes to serialize and deserialize.  returns
# the names of all our properties whose values are instances of Attribute.
func attribute_keys():
	return get_property_list().map(
		func (p): return p.name
	).filter(
		func (pname): return get(pname) is Attribute
	)

# --------------------------------------------------------------------------- #

# - data is a dict of attribute keys to values; we load these directly into
#   the matching attribute, where they will be clamped between 0 and 1.
# - param_overrides is a dict of attribute keys to generation parameter objects
#   (mean, deviation, and heritability), presumed to come from the data
#   definition of whichever monster we are initializing attributes for.
# - inherited_attributes is another dict of attribute keys to values; presumed
#   to be the average of the monster's parents' attributes.  this will be used
#   to calculate attributes for monster eggs.
func _init(data: Dictionary, param_overrides = {}, inherited_attrs = {}):
	for key in ATTRIBUTES:
		# initialize the attribute from a serialized value
		if key in data: set(key, Attribute.new(data[key]))
		else:
			var overrides = param_overrides.get(key, {})
			var inheritance = inherited_attrs.get(key) # nullable
			var params = overrides
			params.merge(ATTRIBUTES[key])
			set(key, Attribute.new(params, inheritance))

# --------------------------------------------------------------------------- #

func serialize():
	var data = {}
	for key in ATTRIBUTES:
		data[key] = get(key).value
	return data


# =========================================================================== #
#                                  S T A T E                                  #
# --------------------------------------------------------------------------- #
# declare properties for each attribute.  this is mostly for autocompletion;
# the initializer should still properties for attributes defined in ATTRIBUTES
# but not declared here, though i haven't tested it.
# TODO: move the "summary" attributes (INT, VIT, etc) out of here

# INT
# ---
var INT: float:
	set(_x): return
	get: return U.weighted_mean([
		[iq.value, 2],
		[learning.value, 1]
	])
var iq: Attribute
var learning: Attribute

# VIT
# ---
var VIT: float:
	set(_x): return
	get: return U.weighted_mean([
		[nutrition.value, 1],
		[vigor.value, 1]
	])
var nutrition: Attribute
var vigor: Attribute

# CON
# ---
var CON: float:
	set(_x): return
	get: return U.weighted_mean([
		[composure.value, 1],
		[patience.value, 1],
		[fortitude.value, 1],
	])
var composure: Attribute
var patience: Attribute
var fortitude: Attribute

# CHA
# ---
var CHA: float:
	set(_x): return
	get: return U.weighted_mean([
		[confidence.value, 1],
		[beauty.value, 1],
		[poise.value, 0.5],
	])
var confidence: Attribute
var beauty: Attribute
var poise: Attribute

# AMI
# ---
var AMI: float:
	set(_x): return
	get: return U.weighted_mean([
		[humility.value, 1],
		[kindness.value, 2],
		[empathy.value, 1.5],
	])
var humility: Attribute
var kindness: Attribute
var empathy: Attribute

# SPR
# ---
var SPR: float:
	set(_x): return
	get: return U.weighted_mean([
		[happiness.value, 1],
		[loyalty.value, 0.5],
		[actualization.value, 1],
	])
var happiness: Attribute
var loyalty: Attribute
var actualization: Attribute

# N/A
# ---
var appetite: Attribute
var pep: Attribute
var openness: Attribute
var extraversion: Attribute
