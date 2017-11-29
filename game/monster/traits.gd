extends Node

class Trait:
	signal value_changed
	
	# defaults for trait properties
	var name = ""
	var max_value = 100
	var min_value = 0
	var title_high = ""
	var high_threshold = 80
	var title_low = ""
	var low_threshold = 20
	
	var orig_value = 0 setget _set_orig
	var value = 0 setget _set_value
	
	func get_portion ():
		return round(value / max_value)
	
	func get_increase ():
		return value - orig_value
	
	func init_value ():
		pass
	
	func load_value (data):
		value = data.value
		orig_value = data.orig_value
	
	func _set_value (val):
		value = val
		emit_signal("value_changed", name, val)
		print(name, ", ", val)
	
	func _set_orig (val): 
		print("Error: can't change original value! (", orig_value, ")")
		pass
	
	func serialize():
		return {
			orig_value = orig_value,
			value = value
		}



# +-----+--------------+
# | INT | intelligence |
# +-----+--------------+


class Iq extends Trait:
# - highly hereditary
# - while pet is young, can be improved by increasing its learning; 
#   potential for improvement decreases rapidly as pet ages
# ---
# - strongly contributes to INT
# - affects how much discipline applies to past actions
# - affects how likely the pet is to undertake complicated (multipart) actions, 
#   like shaking a tree for food (how to implement this???)
# - affects how quickly the pet learns skills (like what?)
# - (maybe) affects how much discipline applies to certain types of actions, like training?
# - causes pet to bond slightly faster with other high-INT pets (affects preference increase)
# - causes pet to prefer "INT-type" items and foods (affects pref. increase) (is this gonna be a thing?)
	func _init():
		name = "iq"
		max_value = 200
		min_value = 0
		title_high = "perspicacious"
		high_threshold = 150
		title_low = "dim-witted"
		low_threshold = 50
	
	func init_value():
		pass


class Learning extends Trait:
# LEARNING - worldly, naive
# - expose the pet to as many different kinds of things as possible
# - increase pet's skills
# - starts at 0
# ---
# - ?
	func _init():
		name = "learning"
		max_value = 100
		min_value = 0
		title_high = "worldly"
		high_threshold = 80
		title_low = "callow"
		low_threshold = 20
	
	func init_value():
		value = 0
		orig_value = 0



# +-----+--------------+
# | VIT |   vitality   |
# +-----+--------------+


class Size extends Trait:
# - improve: keep pet consistently well fed (small to medium impact)
# - inherit from parent
# - size is relative for species, not absolute
# ---
# - mostly for flavor, contributes slightly to VIT (if at all!!)
# - highly hereditary (makes offspring more likely to be bigger)
# - makes the pet more intimidating, maybe other pets try to fight with it less
# - makes pet require slightly more food (food fills less belly, or belly cap is increased)
	func _init():
		name = "size"
		max_value = 100
		min_value = 0
		title_high = "massive"
		high_threshold = 80
		title_low = "shrimpy"
		low_threshold = 20


class Strength extends Trait:
# STRENGTH - brawny, wimpy
# - starting value somewhere between 0 and middle (maybe depends on base size)
# - maybe slight dependence on species (adjust when pet evolves)
# ---
# - makes pet more likely to win fights
# - reduces energy drain & increases energy cap (maybe)
# - affects pet's willingness to accept a fight vs run away
	func _init():
		name = "strength"
		max_value = 100
		min_value = 0
		title_high = "brawny"
		high_threshold = 80
		title_low = "wimpy"
		low_threshold = 20


class Health extends Trait:
# HEALTH (or "heartiness") - hearty, sickly/frail
# ---
# - affects lifespan
# - affects pet's chance of getting sick
# - affects fertility (?)
# - increases energy recovery rate and energy cap
# - affects pet's willingness to accept a fight vs run away
	func _init():
		name = "health"
		max_value = 100
		min_value = 0
		title_high = "hearty"
		high_threshold = 80
		title_low = "frail"
		low_threshold = 20



# +-----+--------------+
# | CON | constitution |
# +-----+--------------+


class Composure extends Trait:
# - ?
# ---
# - when pet's mood DECREASES, triggers a PROC that wil lessen the decrease. 
#   this is so that composure can be trained by praising after a successful proc. 
#   (proc comes with an emote that is different from the regular mood hit emote)
	func _init():
		name = "composure"
		max_value = 100
		min_value = 0
		title_high = "composed"
		high_threshold = 80
		title_low = "neurotic"
		low_threshold = 20


class Willpower extends Trait:
# - ?
# ---
# - duration of activities that drain energy, response to low energy
# - affects the priority pet places on energy-recovering actions (ENERGY DRIVE PRIORITY FORMULA)
# - affects pet's likelihood to quit current action due to low energy (threshold for "quit" event)
# - two options for training: come up with some way to make this a proc'd action so we can train it, or make it increase passively whenever pet is forced to the limits of its energy
	func _init():
		name = "willpower"
		max_value = 100
		min_value = 0
		title_high = "determined"
		high_threshold = 80
		title_low = "lazy"
		low_threshold = 20


class Patience extends Trait:
# - ?
# ---
# - affects the lower threshold for pet's status before it considers its needs unmet?
# - affects the length of time the pet will wait with unmet needs before it starts taking mood hits
# - HOW TO TRAIN THIS?? possibly a proc on above? (as is, pet will emote hunger before it's hungry enough to affect mood. really just need to work out how mood should respond to unmet drives ("meter management")
# - factor in MOOD DRIVE PRIORITY FORMULA
	func _init():
		name = "patience"
		max_value = 100
		min_value = 0
		title_high = "stoic"
		high_threshold = 80
		title_low = "antsy"
		low_threshold = 20



# +-----+--------------+
# | CHA |    charm     |
# +-----+--------------+


class Confidence extends Trait:
# - mostly rng, slightly dependent on pet's sociability
# - improve by praising social actions (esp when of pet's own will)
# ---
# - increases pet's willingness to socialize (too low and it will not meet its own social needs)
# - includes willingness to follow orders to socialize)
# - slightly increases other pets' preference gain for this pet (maybe half of beauty)
	func _init():
		name = "confidence"
		max_value = 100
		min_value = 0
		title_high = "gregarious"
		high_threshold = 80
		title_low = "timid"
		low_threshold = 20


class Beauty extends Trait:
# - mostly hereditary, small amount of rng at birth
# - can be slightly improved by good grooming (TODO: how does grooming work) and consistently high health & energy
# - really good candidate for a potion or spell (maybe damage some other trait a random amt)
# ---
# - increases the preference gain of other pets toward your pet
# - contributes a lot to CHA
	func _init():
		name = "beauty"
		max_value = 100
		min_value = 0
		title_high = "lustrous"
		high_threshold = 80
		title_low = "unsightly"
		low_threshold = 20


class Poise extends Trait:
# - tbh this is a pretty CON-centric trait, maybe have it depend on similar factors??
# ---
# - affects how much mood influences social actions (or actions in general, like complaining)
# - TODO: figure out how mood is supposed to influence social actions in the first place (this is important)
# - affects how much other pets' behavior influence mood (eg less mood hit from insults or fights)
	func _init():
		name = "poise"
		max_value = 100
		min_value = 0
		title_high = "poised"
		high_threshold = 80
		title_low = "histrionic"
		low_threshold = 20



# +-----+--------------+
# | AMI |  amiability  |
# +-----+--------------+


class Independence extends Trait:
# - 60% rng, 40% hereditary
# - decreases a tiny amount with every discipline action
# ---
# - affects how likely pet is to obey orders (esp with low loyalty)
	func _init():
		name = "independence"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20


class Arrogance extends Trait:
# - positive correlation with confidence and iq, maybe roll on birth depending on those
# ---
# - contributes negatively to AMI
# - promotes discriminatory behavior against pets with very different traits/preferences
# - increases chance to reject acts of kindness from other pets (scolding this will lower arrogance)
# - strongly decreases preference gain toward other pets whose attributes are lower, or who have many preferences opposite this pet's preferences
# - decrease other pets' preference gain for this pet (especially from other arrogant pets(?))
	func _init():
		name = "arrogance"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20


class Aggressiveness extends Trait:
# AGGRESSIVENESS - bellicose, zen/placid/quiescent
# ---
# - likelihood to fight when choosing a social action
# - contributes a lot to AMI (negatively)
# - scold when pet picks a fight to reduce aggressiveness (also praise on peaceful social interaction reduces it slightly)
# - affects pet's willingness to accept a fight vs run away
	func _init():
		name = "aggressiveness"
		max_value = 100
		min_value = 0
		title_high = "bellicose"
		high_threshold = 80
		title_low = "zen"
		low_threshold = 20


class Empathy extends Trait:
# ---
# - affects pet's mood to be more like the moods of pets around it (this should not cause a preference hit to those pets though, probably)
	func _init():
		name = "empathy"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20


class Kindness extends Trait:
# ---
# - prioritizes "nice" interactions (play, cheer up) over "mean" ones (fight, insult)
# - TODO: enumerate interaction types and triggers
	func _init():
		name = "kindness"
		max_value = 100
		min_value = 0
		title_high = ""
		high_threshold = 80
		title_low = ""
		low_threshold = 20



# +-----+--------------+
# | SPR |    spirit    |
# +-----+--------------+


class Happiness extends Trait:
# - represents pet's average mood
# - calculate once per day: @ time of birth, roll n % 24 for hour of update that day (where "day" starts & ends at time of birth)
# - fold day's calculation into lifetime average
# - maybe just save the total mood (yes it will ALWAYS fit in an integer) - that way total mood contributes some, and average mood contributes some, plus makes average easier to calculate
# ---
# - does nothing except contribute to SPR
# - strength of effect has to be carefully balanced; maybe should depend on age as well as value
	func _init():
		name = "happiness"
		max_value = 0
		high_threshold = 0
		low_threshold = 0
	
	func get_portion():
		# this needs to be special since we don't really have a max happiness
		pass
	
	func init_value():
		value = 0
		orig_value = 0


class Actualization extends Trait:
# - represents improvement across traits
# - starts at 0, and increases by a certain amount each time a trait increases (1 for most, 2 for spiritually important traits like confidence, health, learning, all the CON skills, 0 for irrelevant traits like beauty and size, -1 for arrogance/aggression)
# ---
# - does nothing except contribute to SPR
	func _init():
		name = "actualization"
		max_value = 0
		high_threshold = 0
		low_threshold = 0
	
	func init_value():
		value = 0
		orig_value = 0


class Loyalty extends Trait:
# - represents relationship with player (basically pet's preference toward player)
# - improved by causing mood increases in pet and maybe other stuff (see discipline.md)
# ---
# - shows up on pet loadout as 0-10 (?) hearts
# - makes pet more likely to follow player orders
# - small effect on SPR
	func _init():
		name = "loyalty"
		max_value = 10
		high_threshold = 0
		low_threshold = 0
	
	func init_value():
		value = 0
		orig_value = 0



# +-----+--------------+
# | N/A | no attribute |
# +-----+--------------+


class Appetite extends Trait:
# - ?
# ---
# - factor in BELLY DRIVE PRIORITY FORMULA
# - makes it easier to gain priority toward foods
	func _init():
		name = "appetite"
		max_value = 100
		title_high = "gluttonous"
		high_threshold = 80
		title_low = "ascetic"
		low_threshold = 20


class Openness extends Trait:
# - ?
# ---
# - modulates target selection by preference (makes pet more likely to choose targets with less preference) (TARGET PRIORITY FORMULA?)
# - makes it easier to gain preference (esp toward targets pet is not naturally disposed to)?
	func _init():
		name = "openness"
		max_value = 100
		title_high = "adventurous"
		high_threshold = 80
		title_low = "closed-minded"
		low_threshold = 20


class Sociability extends Trait:
# - ?
# ---
# - reflects pet's preference for socializing 
# - affects rate of increase/decrease of social meter & social cap (maybe)
# - factor in SOCIAL DRIVE PRIORITY FORMULA
# - influences the effect on mood of max/min social (with low sociability, too much interaction will decrease mood)
	func _init():
		name = "sociability"
		max_value = 100
		title_high = "outgoing"
		high_threshold = 80
		title_low = "reclusive"
		low_threshold = 20

