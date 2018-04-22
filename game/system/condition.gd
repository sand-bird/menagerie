# class Condition
# ---------------
# evaluates and resolves conditions parsed from data files.

extends Node

var global_vars = {
	"player": {
		"money": 0,
		"playtime": 1,
		"name": 2
	},
	"time": {
		"date": 0,
		"day": 1
	},
	"garden": {
		"monsters": {
			"by_species": 1,
			"by_id": 2,
			"count": 3
		}
	},
	"encyclopedia": {
		"completion": 0,
		"monsters": 1,
		"items": 2,
		"stories": 3,
		"plants": 4
	}
}

# basic test
func _ready():
	var Monster = preload("res://monster/monster.gd")
	var sample_monster = Monster.new()
	sample_monster.mother = Monster.new()
	sample_monster.mother.iq = 20
	sample_monster.father = Monster.new()
	sample_monster.father.iq = 40
	for morph in Data.data.monsters.pufig.morphs:
		print(morph.id, ": ", resolve(morph.condition, sample_monster))

# ----------------------------------------------------------- #

static func resolve(data, caller = null):
	var result
	
	# an array of conditions implies an AND
	if typeof(data) == TYPE_ARRAY:
		result = resolve_and(data, caller)
	
	# if it's a dict, our key will tell us what to do
	elif typeof(data) == TYPE_DICTIONARY:
		# must have exactly one key
		assert(data.keys().size() == 1)
		var key = data.keys()[0]
		# key must be one of our known comparators
		assert(key in lookup_func)
		result = call(lookup_func[key], data[key], caller)
	
	# any other type is a problem
	else: assert(false) 
	
#	print("condition ", data, " resolved to ", result)
	return result

# ----------------------------------------------------------- #
#                      O P E R A T O R S                      #
# ----------------------------------------------------------- #

const lookup_func = {
	"and": "_resolve_and",
	 "or": "_resolve_or",
	 "==": "_resolve_equals",
	 "!=": "_resolve_not_equals",
	  ">": "_resolve_greater_than",
	  "<": "_resolve_less_than",
	 ">=": "_resolve_greater_than_equals",
	 "<=": "_resolve_less_than_equals",
	 "in": "_resolve_in"
}

static func _resolve_and(data, caller):
	for condition in data:
		if !resolve(condition, caller): return false
	return true

static func _resolve_or(data, caller):
	for condition in data:
		if resolve(condition, caller): return true
	return false

static func _resolve_equals(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] == args[1]

static func _resolve_not_equals(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] != args[1]

static func _resolve_greater_than(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] > args[1]

static func _resolve_less_than(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] < args[1]

static func _resolve_greater_than_equals(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] >= args[1]

static func _resolve_less_than_equals(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] <= args[1]

static func _resolve_in(data, caller):
	var args = _resolve_args(data, caller)
	return args[0] in args[1]

# ----------------------------------------------------------- #
#                      A R G U M E N T S                      #
# ----------------------------------------------------------- #

static func _resolve_args(data, caller):
	assert(typeof(data) == TYPE_ARRAY and data.size() == 2)
	var resolved_data = []
	for arg in data:
		resolved_data.append(_resolve_arg(arg, caller))
	return resolved_data

static func _resolve_arg(arg, caller):
	if (typeof(arg) == TYPE_STRING):
		if arg[0] == '@':
			arg = _eval_local(strip_sigil(arg), caller)
		elif arg[0] == '$':
			arg = _eval_global(strip_sigil(arg))
	return arg

# -----------------------------------------------------------

static func _eval_local(arg, caller):
#	print("evaluating local var: ", arg)
	var breadcrumb = arg.split('.')
	var obj = caller
	for prop in breadcrumb:
		obj = obj[prop]
		# error reporting - prob not necessary
#		if typeof(obj) in [TYPE_ARRAY, TYPE_DICTIONARY] and !obj.has(prop):
#			print("key '", prop, "' not found in ", obj)
#		elif typeof(obj) == TYPE_OBJECT and obj[prop] == null:
#			print("prop '", prop, "' not found in ", obj)
	return obj

# -----------------------------------------------------------

static func _eval_global(arg):
	print("evaluating global var: ", arg)

# -----------------------------------------------------------

# just returns the string minus the first char
# maybe todo: double-check if sigil before trying to strip
static func strip_sigil(s):
	return s.substr(1, s.length() - 1)
