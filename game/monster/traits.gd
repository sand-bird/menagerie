extends RefCounted
class_name Traits
"""
traits are a collection of values that influence various aspects of a monster's
behavior.  taken as a whole, they represent the monster's personality.

each monster has a Traits object which stores state for the current value of
all the monster's traits, and is initialized within the Monster constructor.

the Traits constructor takes a serialized traits object (a dict of trait names
to values). for each trait without a supplied value, we roll a new value for it.

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
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

func trait_keys():
	return get_property_list().map(
		func (p): return p.name
	).filter(
		func (pname): return get(pname) is Trait
	)

# --------------------------------------------------------------------------- #

func _init(data: Dictionary, param_overrides = {}, inherited_traits = {}):
	for key in trait_keys():
		var t: Trait = get(key)
		if key in data: t.value = data.get(key)
		else:
			var overrides = param_overrides.get(t, {})
			var inheritance = inherited_traits.get(t)
			t.roll(overrides, inheritance)

# --------------------------------------------------------------------------- #

func serialize():
	var data = {}
	for key in trait_keys():
		data[key] = get(key).value
	return data

# =========================================================================== #
#                                  S T A T E                                  #
# --------------------------------------------------------------------------- #

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
# dim / perspicacious
var iq = Trait.new({ heritability = 0.9 }) 
# accumulative trait reflecting how much a pet has learned over its life.
# exists to boost the INT attribute. always starts at 0.
# callow / worldly
var learning = Trait.new({ mean = 0, deviation = 0, heritability = 0 })

# VIT
# ---
# accumulative trait reflecting good feeding. exists to boost VIT.
# malnourished / sleek
var nutrition = Trait.new({ deviation = 0.05, heritability = 0 })
# affects energy consumption and regeneration (higher vigor means energy
# recovers faster and drains slower). increased by expending energy.
 # sickly / hearty
var vigor = Trait.new({ mean = 0.4 })

# CON
# ---
# governs the success of composure rolls (overcoming a mood hit).
# increased by encouraging a pet during a composure roll or praising it
# after a successful roll.
# neurotic / composed
var composure = Trait.new({ mean = 0.3 })
# governs how long it takes for a pet to start suffering mood hits as a
# result of unmet needs (drives out of equilibrium).
# increased by correcting drives after patience procs but before a mood hit.
# antsy / stoic
var patience = Trait.new({ mean = 0.4 })
# affects the probability of patience and composure procs, and the magnitude
# of mood losses from patience procs (unmet needs).
var fortitude = Trait.new()

# CHA
# ---
# "social fitness"
# governs how likely a pet is to undertake social actions (via utility mods).
# increased by performing social actions with positive results.
# TODO: unclear, rethink this & "extraversion" w/r/t the social meter
# timid / gregarious
var confidence = Trait.new({ mean = 0.4 })
# boosts CHA attribute. maybe also affects other pets' preferences.
# heritable and can be modified (maybe temporarily) by items.
# unsightly / lustrous
var beauty = Trait.new({ heritability = 0.8 })
# accumulative trait. affects mood losses from social events, and mood-based
# utility modifiers on social actions. ("A high POISE monster will be less
# likely to take out its bad mood on others, and won't let negative inter-
# actions affect its MOOD as much.")
# histrionic / poised
var poise = Trait.new({ mean = 0.1, heritability = 0.2 })

# AMI
# ---
# inverse multiplier for negative preferences; low humility pets are more
# prone to disliking things and other monsters.
# linear transform to a (0, 2) multiplier: 2 - (humility * 2)
# when a preference change is negative, we modify it by the humility multi.
# haughty / humble
var humility = Trait.new()
# used as a component of sympathy calculations, alongside preference.
# converted to a (-1, 1) multiplier: (kindness * 2) - 1
# low kindness results in a negative multiplier, meaning actions that lower
# the target's mood will increase the actor's.
# wicked / saintly
var kindness = Trait.new({ deviation = 0.2 })
# multiplies the target's mood change for sympathy calculations.
# convert to a (0, 2) multplier: empathy * 2
var empathy = Trait.new({ deviation = 0.2 }) # autistic / empathic

# SPR
# ---
# cumulative sample of the pet's mood.  should be sampled once per day at a
# random time each day. # depressed / jubilant
var happiness = Trait.new({ heritability = 1, deviation = 0.05 })
# modifies how likely the pet is to accept commands. increased by discipline.
# faithless / steadfast
var loyalty = Trait.new({ mean = 0.15, heritability = 0.2, deviation = 0.08 })
# strictly accumulative; measures positive change in traits.  this should be
# updated whenever we update a trait.
var actualization = Trait.new({ mean = 0, heritability = 0, deviation = 0 })

# N/A
# ---
# determines how fast the pet's belly drains and how much food restores it.
# higher appetite means it drains faster and food is less filling.
# anorexic / gluttonous
var appetite = Trait.new({ deviation = 0.1, heritability = 0.3 })
# determines the pet's preferred energy level. higher pep = lower preferred
# energy # indolent / energetic
var pep = Trait.new()
# modifies the effect of preference on utility calculations; sticky
var openness = Trait.new()
var extraversion = Trait.new()
