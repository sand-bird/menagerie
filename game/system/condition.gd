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
	# comparators
	"and": "_and",
	"or": "_or",
	"==": "_equals",
	"!=": "_not_equals",
	">": "_greater_than",
	"<": "_less_than",
	">=": "_greater_than_equals",
	"<=": "_less_than_equals",
	"in": "_in",
	
	# separator operators
	"map": "_map",
	"get": "_get",
	
	# collection operators
	"filter": "_filter",
	"max": "_max",
	"min": "_min",
	"total": "_total",
	"first": "_first",
	"last": "_last"
}

var globals = {
	"player": Player,
	"time": Time,
	"data": Data.data
	#"garden": get_node("/root/game/garden"),
}

# -----------------------------------------------------------

# basic test
func _ready():
	return
	var Monster = preload("res://monster/monster_new.gd")
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
	var result
	# an array of conditions implies an AND
	if typeof(data) == TYPE_ARRAY:
		result = _and(data, caller)
	# if it's a dict, our key will tell us what to do
	elif typeof(data) == TYPE_DICTIONARY:
		# must have exactly one key
		assert(data.keys().size() == 1)
		var key = data.keys()[0]
		# key must be one of our known comparators
		assert(key in lookup_func)
		result = call(lookup_func[key], data[key], caller, parent)
	# any other type is a problem
	else: assert(false)
	Log.verbose(self, ["condition ", data, " resolved to ", result])
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
# (should crash if data doesn't have key)
func _get(args, caller, parent):
#	print("get (before): ", to_json(args))
	var data = eval_arg(args[0], caller, parent)
	var key = eval_arg(args[1], caller, parent) # no parent i think
#	print("get (after): ", to_json([data, key]))
	return data[key]

# ----------------------------------------------------------- 

# accepts an ARRAY with EXACTLY 2 members, where the first 
# is a dictionary or array, and the second is a valid index 
# or property of at least one ELEMENT IN the first. returns 
# a dictionary or array containing, for each element in the
# former, the value corresponding to the key or property 
# specified by the latter, if such a value exists.
func _map(args, caller, parent):
#	print("map (before): ", to_json(args))
	var results = []
	var data = eval_arg(args[0], caller, parent)
	for item in data:
		var value
		if typeof(data) == TYPE_ARRAY: value = item
		elif typeof(data) == TYPE_DICTIONARY: value = data[item]
		var key = eval_arg(args[1], caller, value)
#		print("-----\n args: ", to_json(args), "\n key: ", to_json(key), 
#				"\n item: ", to_json(item), "\n data: ", to_json(data),
#				"\n value: ", to_json(value))
		if value.has(key): results.push_back(value[key])
#	print("map (after): ", to_json(results))
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
		'$': return globals[strip_sigil(arg)]
		'#': return Constants[strip_sigil(arg).capitalize().replace(' ', '')]
		'@': return caller[strip_sigil(arg)]
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
		return { seperators[op]: [
			expand_ops(arg.left(pos)), 
			expand_ops(arg.right(pos + 1))
		] }
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