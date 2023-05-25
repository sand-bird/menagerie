# evaluates and resolves conditions parsed from data files.
class_name Condition
const log_name = "Condition"

# not a typo: actually a portmanteau of "separators" and "operators".
# these apply to condition arguments
const seperators = {
	'.': 'get',
	':': 'map'
}

# our global refs must be parsed at runtime, since not every global will be a
# singleton (and we don't want to depend too much on the other singletons being
# loaded first, anyway). otherwise this would be a dictionary also.
static func resolve_global(arg):
	match (arg):
		'player': return Player
		'clock': return Clock
		'data': return Data
		'garden': return Player.garden

# --------------------------------------------------------------------------- #

static func call_fn(data, caller, parent):
	# must have exactly one key
	if data.keys().size() != 1:
		Log.error(log_name, [""])
		return false
	var key = data.keys()[0]
	match key:
		# booleans
		'and': return _and(data[key], caller, parent)
		'or': return _or(data[key], caller, parent)
		'not': return _not(data[key], caller, parent)
		# comparators
		'==': return _equals(data[key], caller, parent)
		'!=': return _not_equals(data[key], caller, parent)
		'>': return _greater_than(data[key], caller, parent)
		'<': return _less_than(data[key], caller, parent)
		'>=': return _greater_than_equals(data[key], caller, parent)
		'<=': return _less_than_equals(data[key], caller, parent)
		'in': return _in(data[key], caller, parent)
		# collection operators
		'map': return _map(data[key], caller, parent)
		'get': return _get_op(data[key], caller, parent)
		'filter': return _filter(data[key], caller, parent)
		# "max": _max(data[key], caller, parent)
		# "min": _min(data[key], caller, parent)
		# "total": _total(data[key], caller, parent)
		# "first": _first(data[key], caller, parent)
		# "last": _last(data[key], caller, parent)
		'empty': return _empty(data[key], caller, parent)

# --------------------------------------------------------------------------- #

static func resolve(data, caller = null, parent = null):
	var result = false

	# an array of conditions implies an AND
	if typeof(data) == TYPE_ARRAY:
		result = _and(data, caller, parent)

	# if it's a dict, our key will tell us what to do
	elif typeof(data) == TYPE_DICTIONARY:
		result = call_fn(data, caller, parent)

	# if we just want to evaluate a single string argument, we should be able to.
	# the likely use case is checking the result for truthiness, but it can also
	# be used to fetch data declaratively (eg in an entity definition). note that
	# `eval_arg` also calls `resolve` (if the arg evaluates to a dictionary).
	# some more testing should probably be done to ensure we don't have any
	# infinite recursion situations.
	elif typeof(data) == TYPE_STRING:
		result = eval_arg(data, caller, parent)

	else: # any other type is a problem
		Log.error(log_name, "(resolve) failed: unsupported argument!")

	Log.verbose(log_name, ["(resolve) condition ", data,
			" resolved to ", result])
	return result

# =========================================================================== #
#                              O P E R A T O R S                              #
# --------------------------------------------------------------------------- #

#                               b o o l e a n s
# --------------------------------------------------------------------------- #

# accepts an ARRAY with AT LEAST 2 members
# returns true if all members resolve to true
static func _and(data, caller, parent):
	for condition in data:
		if !resolve(condition, caller, parent): return false
	return true

# accepts an ARRAY with AT LEAST 2 members
# returns true if at least one member resolves to true
static func _or(data, caller, parent):
	for condition in data:
		if resolve(condition, caller, parent): return true
	return false

static func _not(data, caller, parent):
	return !resolve(data, caller, parent)

#                            c o m p a r a t o r s
# --------------------------------------------------------------------------- #
# each accepts an ARRAY with EXACTLY 2 members

static func _equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] == args[1]

static func _not_equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] != args[1]

static func _greater_than(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] > args[1]

static func _less_than(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] < args[1]

static func _greater_than_equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] >= args[1]

static func _less_than_equals(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] <= args[1]

# the first value should be a scalar, and the second a collection
static func _in(data, caller, parent):
	var args = eval_args(data, caller, parent)
	return args[0] in args[1]

#                        d a t a   o p e r a t o r s
# --------------------------------------------------------------------------- #

# accepts an ARRAY with EXACTLY 2 members, where the first is a dictionary or
# object and the second is a valid index or property of the first. returns the
# value corresponding to the key or property of the former, specified by the
# latter. (should crash if data doesn't have key.)
static func _get_op(args, caller, parent):
	Log.verbose(log_name, ["(_get): ", args])
	var data = eval_arg(args[0], caller, parent)
	var key = eval_arg(args[1], caller, parent) # no parent i think
	var result

	# check that data and key exist
	if data == null:
		Log.error(log_name, ["(_get) failed: collection '", args[0],
				"' could not be resolved"])
		return null
	if key == null:
		Log.error(log_name, ["(_get) failed: argument ", args[1],
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

	if result == null:
		Log.error(log_name, ["(_get) failed: key '", key,
				"' not found in collection ", data])
	return result

# --------------------------------------------------------------------------- #

# accepts an ARRAY with EXACTLY 2 members, where the first is a dictionary or
# array, and the second is a valid index or property of at least one ELEMENT IN
# the first. returns a dictionary or array containing, for each element in the
# former, the value corresponding to the key or property specified by the
# latter, if such a value exists.
static func _map(args, caller, parent):
	Log.verbose(log_name, ["(_map) before: ", args])
	var results = []
	var data = eval_arg(args[0], caller, parent)
	for item in data:
		var value
		if typeof(data) == TYPE_ARRAY: value = item
		elif typeof(data) == TYPE_DICTIONARY: value = data[item]
		var key = eval_arg(args[1], caller, value)
#		Log.verbose(log_name, ["-----\n args: ", args, "\n key: ", key,
#				"\n item: ", item, "\n data: ", data, "\n value: ", value])
		if value.has(key): results.push_back(value[key])
		# stuff for "true map" that didn't work
#		var value = resolve(args[1])
#		Log.verbose(log_name, ["(_map) resolved value: ", value])
#		results.push_back(value)
	Log.verbose(log_name, ["(_map) after: ", results])
	return results

# --------------------------------------------------------------------------- #

# accepts an ARRAY with EXACTLY 2 members: the first a collection, and the
# second a condition object. returns a collection containing the elements of
# the former for which the latter resolves to true.
static func _filter(args, caller, parent):
	var results = []
	var data = eval_arg(args[0], caller, parent)
	var condition = args[1]
	for item in data:
		if resolve(condition, caller, item):
			results.push_back(item)
	return results

# accepts a single member, assumed to be an array or a dict.
static func _empty(arg, caller, parent):
	var data = eval_arg(arg, caller, parent)
	if typeof(data) == TYPE_ARRAY or typeof(data) == TYPE_DICTIONARY:
		return data.is_empty()
	else:
		Log.warn(log_name, "(_empty) argument is not a collection!")
		return true


# =========================================================================== #
#                              A R G U M E N T S                              #
# --------------------------------------------------------------------------- #

# residual from 1.0 - convenient for the basic comparators but probably won't
# handle * context right, meaning it will break for filtering
static func eval_args(data, caller, parent):
	assert(typeof(data) == TYPE_ARRAY and data.size() == 2)
	var resolved_data = []
	for arg in data:
		resolved_data.append(eval_arg(arg, caller, parent))
	return resolved_data

# this is called from anybody who might get an argment with seperators in it.
# expands the arg, then resolves it.
static func eval_arg(arg, caller = null, parent = null):
	var expanded = expand_ops(arg)
	if typeof(expanded) == TYPE_DICTIONARY:
		return resolve(expanded, caller, parent)
	elif typeof(expanded) == TYPE_STRING:
		return eval_sigil(expanded, caller, parent)
	else: return expanded

#                                 s i g i l s
# --------------------------------------------------------------------------- #

# accepts an ATOMIC (no seperators) string that may or may not have a sigil.
static func eval_sigil(arg, caller, parent):
	match arg[0]:
		'$': return resolve_global(Utils.strip_sigil(arg))
		'#': return Constants.new().get(Utils.strip_sigil(arg).capitalize().replace(' ', ''))
		'@': return caller[Utils.strip_sigil(arg)]
		'*': return parent
	return arg

#                             s e p e r a t o r s
# --------------------------------------------------------------------------- #

# expands an argument string with separator operators, aka seperators (see the
# const up top), into actual "condition" objects that our regular resolve logic
# knows how to handle. the seperator becomes the key, and the rest of the
# string is split around it to become the arguments, which are then expanded
# themselves.
static func expand_ops(arg):
	if typeof(arg) != TYPE_STRING: return arg
	var op_pos = find_op(arg)
	if op_pos:
		var op = op_pos[0]
		var pos = op_pos[1]
		return {seperators[op]: [
			expand_ops(arg.left(pos)),
			expand_ops(arg.substr(pos + 1))
		]}
	else: return arg

# gets all operator positions in the argument string, and returns the largest
# one as an array[2] with the operator at 0 and its position at 1.
#
# the rfind is VERY IMPORTANT for our argument to expand in the correct order.
# resolve recurses from the inside out, so the "top level" of the expansion
# must be the innermost nested operator. meanwhile, expand_ops recurses from
# the outside in, so we have to start at the END of the string to obtain the
# correct structure.
static func find_op(arg):
	var op_pos
	var max_pos = 0
	for op in seperators:
		var pos = arg.rfind(op)
		if pos > max_pos:
			max_pos = pos
			op_pos = [op, pos]
	return op_pos
