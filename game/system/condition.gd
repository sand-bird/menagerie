# class Condition
# ---------------
# evaluates and resolves conditions parsed from data files.

extends Node

onready var globals = {
	"garden": {
		"monsters": {
			12345: {
				"preferences": {
					"monsters": {
						77777: 10
					}
				}
			},
			67890: {
				"preferences": {
					"monsters": {
						77777: 33
					}
				}
			}
		}
	} 
}

const operators = {
	".": "get",
	":": "map"
}


# basic test
func _ready():
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
	print(resolve(test_cond, sample_monster))
	#eval_string("@mother.iq", sample_monster)
	#eval_string("@mother", sample_monster)
	for morph in Data.data.monsters.pufig.morphs:
		print(morph.id, ": ", resolve(morph.condition, sample_monster))

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
#	print("condition ", data, " resolved to ", result)
	return result

# =========================================================== #
#                      O P E R A T O R S                      #
# ----------------------------------------------------------- #

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
func _filter(args, caller):
	var results = []
	var data = eval_arg(args[0], caller)
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
# separators in it. expands the arg, then resolves it.
func eval_arg(arg, caller = null, parent = null):
	var expanded = expand_ops(arg)
	if typeof(expanded) == TYPE_DICTIONARY:
		return resolve(expanded, caller, parent)
	elif typeof(expanded) == TYPE_STRING:
		return eval_sigil(expanded, caller, parent)
	else: return expanded

# -----------------------------------------------------------

# accepts an ATOMIC (no separators) string argument that may
# or may not have a sigil.
func eval_sigil(arg, caller, parent):
	if arg[0] == '$': return globals[strip_sigil(arg)]
	if arg[0] == '@': return caller[strip_sigil(arg)]
	if arg[0] == '*': return parent
	else: return arg

# just returns the string minus the first char
# maybe todo: double-check if sigil before trying to strip
func strip_sigil(s):
	return s.substr(1, s.length() - 1)

# -----------------------------------------------------------

func expand_ops(arg):
	if typeof(arg) != TYPE_STRING: return arg
	var op_pos = find_op(arg)
	if op_pos:
		var op = op_pos[0]
		var pos = op_pos[1]
		return { operators[op]: [
			expand_ops(arg.left(pos)), 
			expand_ops(arg.right(pos + 1))
		] }
	else: return arg

# get all operator positions in the argument string, and
# return the largest one.
func find_op(arg):
	var op_pos
	var max_pos = 0
	for op in operators:
		var pos = arg.rfind(op)
		if pos > max_pos: 
			max_pos = pos
			op_pos = [op, pos]
	return op_pos