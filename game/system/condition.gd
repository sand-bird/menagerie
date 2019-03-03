# class Condition
# ---------------
# evaluates and resolves conditions parsed from data files.

extends Node

# not a typo: actually a portmanteau of "separators" and
# "operators". these apply to condition arguments
const seperators = {
	".": "get",
	":": "map"
}

# dictionary of operators to the functions used to evaluate
# them, accessed via GDScript's handy call() method.
const lookup_func = {
	# booleans
	"and": "_and",
	"or": "_or",
	"not": "_not",
	
	# comparators
	"==": "_equals",
	"!=": "_not_equals",
	">": "_greater_than",
	"<": "_less_than",
	">=": "_greater_than_equals",
	"<=": "_less_than_equals",
	"in": "_in",
	
	# separator operators (expanded seperators)
	"map": "_map",
	"get": "_get",
	
	# collection operators
	"filter": "_filter",
	"max": "_max",
	"min": "_min",
	"total": "_total",
	"first": "_first",
	"last": "_last",
	"empty": "_empty"
}

# our global refs must be parsed at runtime, since not every
# global will be a singleton (and we don't want to depend too
# much on the other singletons being loaded first, anyway).
# otherwise this would be a dictionary also.
func resolve_global(arg):
	match (arg):
		"player":
			return Player
		"time":
			return Time
		"data":
			return Data
		"garden":
			return get_node("/root/game/garden")

# -----------------------------------------------------------

# basic test (please remember to delete me at some point)
func _ready():
	return
	var Monster = load("res://monster/monster.gd")
	var sample_monster = Monster.new()
	sample_monster.mother = Monster.new()
	sample_monster.mother.traits["iq"] = 20
	sample_monster.father = Monster.new()
	sample_monster.father.traits["iq"] = 40
	sample_monster.id = 77777
	var test_str = "$garden.monsters:preferences:monsters:@id"
	var test_cond = {"in": [10, test_str]}
	#print(eval_arg("$garden"))
	#print(to_json(expand_ops(test_str)))
	#print("eval_arg: ", to_json(eval_arg(test_str, sample_monster)))
	Log.info(self, resolve(test_cond, sample_monster))
	#eval_string("@mother.iq", sample_monster)
	#eval_string("@mother", sample_monster)
	for morph in Data.data.monsters.pufig.morphs:
		Log.info(self, [morph.id, ": ", resolve(morph.condition, sample_monster)])

# ----------------------------------------------------------- #

func resolve(data, caller = null, parent = null):
	var result = false
	
	# an array of conditions implies an AND
	if typeof(data) == TYPE_ARRAY:
		result = _and(data, caller, parent)
	
	# if it's a dict, our key will tell us what to do
	elif typeof(data) == TYPE_DICTIONARY:
		# must have exactly one key
		assert(data.keys().size() == 1)
		var key = data.keys()[0]
		# key must be one of our known comparators
		assert(key in lookup_func)
		result = call(lookup_func[key], data[key], caller, parent)
	
	# if we just want to evaluate a single (string) argument,
	# we should be able to. the likely use case is checking 
	# the result for truthiness, but it can also be used to
	# fetch data declaratively (eg in an entity definition).
	#
	# note that `eval_arg` also calls `resolve` (if the arg
	# evaluates to a dictionary). some more testing should
	# probably be done to ensure we don't have any infinite
	# recursion situations.
	elif typeof(data) == TYPE_STRING:
		result = eval_arg(data, caller, parent)
	
	else: # any other type is a problem
		Log.error(self, "(resolve) failed: unsupported argument!")
	
	Log.verbose(self, ["(resolve) condition ", data, 
			" resolved to ", result])
	return result

# =========================================================== #
#                      O P E R A T O R S                      #
# ----------------------------------------------------------- #

#                       b o o l e a n s                    
# ----------------------------------------------------------- 

# accepts an ARRAY with AT LEAST 2 members
# returns true if all members resolve to true
func _and(data, caller, parent):
	for condition in data:
		if !resolve(condition, caller, parent): return false
	return true

# accepts an ARRAY with AT LEAST 2 members
# returns true if at least one member resolves to true
func _or(data, caller, parent):
	for condition in data:
		if resolve(condition, caller, parent): return true
	return false

func _not(data, caller, parent):
	return !resolve(data, caller, parent)

#                    c o m p a r a t o r s                    
# ----------------------------------------------------------- 

# accepts an ARRAY with EXACTLY 2 members
func _equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] == args[1]

# accepts an ARRAY with EXACTLY 2 members
func _not_equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] != args[1]

# accepts an ARRAY with EXACTLY 2 members
func _greater_than(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] > args[1]

# accepts an ARRAY with EXACTLY 2 members
func _less_than(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] < args[1]

# accepts an ARRAY with EXACTLY 2 members
func _greater_than_equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] >= args[1]

# accepts an ARRAY with EXACTLY 2 members
func _less_than_equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] <= args[1]

# accepts an ARRAY with EXACTLY 2 members,
# the first a scalar, and the second a collection
func _in(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] in args[1]

#                d a t a   o p e r a t o r s                 
# ----------------------------------------------------------- 

# accepts an ARRAY with EXACTLY 2 members, where the first is
# a dictionary or object and the second is a valid index or
# property of the first. returns the value corresponding to
# the key or property of the former, specified by the latter.
# (should crash if data doesn't have key.)
# as of godot 3.1, `get` is a member function that can't be
func _get_op(args, caller, parent):
	Log.verbose(Condition, ["(_get): ", args])
	var data = eval_arg(args[0], caller, parent)
	var key = eval_arg(args[1], caller, parent) # no parent i think
	var result
	
	# check that data and key exist
	if !data:
		Log.error(Condition, ["(_get) failed: collection '", args[0],
				"' could not be resolved"])
		return null
	if key == null:
		Log.error(Condition, ["(_get) failed: argument ", args[1],
				" could not be resolved to a key"])
		return null
	
	# (try to) get property
	if typeof(data) == TYPE_OBJECT:
		if data.has_method("get"):
			result = data.get(key)
		elif key in data:
			result = data[key]
	elif typeof(data) == TYPE_DICTIONARY and data.has(key):
		result = data[key]
	
	if !result:
		Log.error(Condition, ["(_get) failed: key '", key,
				"' not found in collection ", data])
	return result

# ----------------------------------------------------------- 

# accepts an ARRAY with EXACTLY 2 members, where the first 
# is a dictionary or array, and the second is a valid index 
# or property of at least one ELEMENT IN the first. returns 
# a dictionary or array containing, for each element in the
# former, the value corresponding to the key or property 
# specified by the latter, if such a value exists.
func _map(args, caller, parent):
	Log.verbose(self, ["(_map) before: ", args])
	var results = []
	var data = eval_arg(args[0], caller, parent)
	for item in data:
		var value
		if typeof(data) == TYPE_ARRAY: value = item
		elif typeof(data) == TYPE_DICTIONARY: value = data[item]
		var key = eval_arg(args[1], caller, value)
#		Log.verbose(self, ["-----\n args: ", args, "\n key: ", key,
#				"\n item: ", item, "\n data: ", data, "\n value: ", value])
		if value.has(key): results.push_back(value[key])
		# stuff for "true map" that didn't work
#		var value = resolve(args[1])
#		Log.verbose(self, ["(_map) resolved value: ", value])
#		results.push_back(value)
	Log.verbose(self, ["(_map) after: ", results])
	return results

# -----------------------------------------------------------

# accepts an ARRAY with EXACTLY 2 members: the first is a 
# dictionary or array, and the second is a condition object.
# returns a dictionary or array containing the elements of
# the former for which the latter resolves to true.
func _filter(args, caller, parent):
	var results = []
	var data = eval_arg(args[0], caller, parent)
	var condition = args[1]
	for item in data:
		if resolve(condition, caller, item): 
			results.push_back(item)
	return results

# accepts a single member, assumed to be an array or a dict.
func _empty(arg, caller, parent):
	var data = eval_arg(arg, caller, parent)
	if typeof(data) == TYPE_ARRAY or typeof(data) == TYPE_DICTIONARY:
		return data.empty()
	else:
		Log.warn(self, "(_empty) argument is not a collection!")
		return true


# =========================================================== #
#                      A R G U M E N T S                      #
# ----------------------------------------------------------- #

# residual from 1.0 - convenient for the basic comparators
# but probably won't handle * context right, meaning it will
# break for filtering
func eval_args(data, caller, parent):
	assert(typeof(data) == TYPE_ARRAY and data.size() == 2)
	var resolved_data = []
	for arg in data:
		resolved_data.append(eval_arg(arg, caller, parent))
	return resolved_data

# this is called from anybody who might get an argment with
# seperators in it. expands the arg, then resolves it.
func eval_arg(arg, caller = null, parent = null):
	var expanded = expand_ops(arg)
	if typeof(expanded) == TYPE_DICTIONARY:
		return resolve(expanded, caller, parent)
	elif typeof(expanded) == TYPE_STRING:
		return eval_sigil(expanded, caller, parent)
	else: return expanded

#                         s i g i l s                        
# -----------------------------------------------------------

# accepts an ATOMIC (no seperators) string argument that may
# or may not have a sigil.
func eval_sigil(arg, caller, parent):
	match arg[0]:
		'$': return resolve_global(Utils.strip_sigil(arg))
		'#': return Constants[Utils.strip_sigil(arg
				).capitalize().replace(' ', '')]
		'@': return caller[Utils.strip_sigil(arg)]
		'*': return parent
	return arg

#                     s e p e r a t o r s                    
# -----------------------------------------------------------

# expands an argument string with separator operators, aka
# seperators (see the const up top), into actual "condition"
# objects that our regular resolve logic knows how to handle.
# the seperator becomes the key, and the rest of the string
# is split around it to become the arguments, which are then
# expanded themselves.
func expand_ops(arg):
	if typeof(arg) != TYPE_STRING: return arg
	var op_pos = find_op(arg)
	if op_pos:
		var op = op_pos[0]
		var pos = op_pos[1]
		return {seperators[op]: [
			expand_ops(arg.left(pos)), 
			expand_ops(arg.right(pos + 1))
		]}
	else: return arg

# gets all operator positions in the argument string, and
# returns the largest one as an array[2] with the operator
# at 0 and its position at 1. 
#
# the rfind is VERY IMPORTANT for our argument to expand in 
# the correct order. resolve recurses from the inside out, 
# so the "top level" of the expansion must be the innermost 
# nested operator. meanwhile, expand_ops recurses from the
# outside in, so we have to start at the END of the string 
# to obtain the correct structure.
func find_op(arg):
	var op_pos
	var max_pos = 0
	for op in seperators:
		var pos = arg.rfind(op)
		if pos > max_pos: 
			max_pos = pos
			op_pos = [op, pos]
	return op_pos
