class_name Validator
const log_name = "Validator"

"""
validates our json files using json-schema.  written against the 2020-12 draft
(the latest at the time of this writing, 2023-04).

initialization requires a `schema_root` object where each key is an entity type
and each value is the schema for that type.  the root is not in itself a valid
schema, only an index; thus, the first step to validating a data definition is
to match it against the correct schema by looking up its type in `schema_root`.
we handle this in the entrypoint function `validate`, which accepts the entire
data object.  this in turn calls `validate_instance` with each data definition
and its corresponding schemafile, which will recurse until it has validated the
instance and all its children.
"""

# http://json-schema.org/draft/2020-12/json-schema-core.html#name-output-structure
enum OutputFormat { BASIC, DETAILED }

class E:#rror
	static func bad_ref(arg: String, path: Array):
		return "could not resolve ref %s in %s" % [arg, '/'.join(path)]
	static func rejected():
		return "rejected (subschema is false)"
	static func not_not_valid():
		return "should not be valid, but is"
	static func type_mismatch_single(a, b):
		return "is the wrong type (should be %s, but is %s)" % [a, b]
	static func type_mismatch_plural(a, b):
		return "is the wrong type (should be one of %s, but is %s)" % [a, b]
	static func enum_mismatch(a, b):
		return "does not have an acceptable value (should be one of %s, but is %s)" % [a, b]
	static func const_mismatch(a, b):
		return "has the wrong value (should be %s, but is %s)" % [a, b]
	static func pattern_mismatch(a, b):
		return "does not match the required pattern '%s' (is %s)" % [a, b]
	static func max_length_exceeded(a, b):
		return "is too long (should be up to %s characters, but is %s)" % [a, b]
	static func min_length_not_met(a, b):
		return "is too short (should be at least %s characters, but is %s)" % [a, b]
	static func not_divisible(a, b):
		return "is not divisible by %s (is %s)" % [a, b]
	static func maximum_exceeded(a, b):
		return "is too large (should be at most %s, but is %s)" % [a, b]
	static func ex_max_exceeded(a, b):
		return "is too large (should be less than %s, but is %s)" % [a, b]
	static func minimum_not_met(a, b):
		return "is too small (should be at least %s, but is %s)" % [a, b]
	static func ex_min_not_met(a, b):
		return "is too small (should be more than %s, but is %s)" % [a, b]
	static func max_props_exceeded(a, b):
		return "has too many properties (should have at most %s, but has %s)" % [a, b]
	static func min_props_not_met(a, b):
		return "has too few properties (should have at least %s, but has %s)" % [a, b]
	static func missing_required(a):
		return "is missing required properties: %s" % [a]
	static func max_items_exceeded(a, b):
		return "has too many items (should have at most %s, but has %s)" % [a, b]
	static func min_items_not_met(a, b):
		return "has too few items (should have at least %s, but has %s)" % [a, b]
	static func not_unique(a):
		return "has duplicate items (%s)" % [a]
	static func format_mismatch(a, b):
		return "is not a valid %s (is %s)" % [a, b]

var schema_root: Dictionary = {}
var output_format: OutputFormat

# --------------------------------------------------------------------------- #

func _init(root: Dictionary, format: OutputFormat = OutputFormat.BASIC):
	schema_root = root
	output_format = format
	# validate root schema using a metaschema (prob hardcoded)

# --------------------------------------------------------------------------- #

# if the result is false (meaning error), we report it using the given
# arguments, then pass it along.
# - message_key: some key in our `messages` dict, for getting the error message
# - message_args: passed to the message we get after looking up `message_key`.
#     currently we don't verify whether the number of args matches up...
#     so, uh, be careful
# - data_path: eg, 'pufig.morphs.pink'; identifies the thing that failed
#     validation. goes in front of our message
# - schema_path: path to the keyword
func report(
	valid: bool, message: String, data_path: String,
	schema_ctx: Dictionary = {}, next_path: String = ""
) -> Dictionary:
	var res = new_result(int(valid), data_path, schema_ctx, next_path)
	if !valid: res.error = message
	return res

# --------------------------------------------------------------------------- #

# generate a result object.  this unnests schema_context.
# does not include error info; that is added in `report` (for leaves) and
# `append` (for parents)
func new_result(
	valid: int, data_path: String = "",
	s: Dictionary = {}, s_ext: String = ""
) -> Dictionary:
	var res = { valid = valid }
	if data_path != "": res.instanceLocation = data_path
	# if we don't already have a schema context, use schema_ext to create one
	# otherwise, append schema_ext to each of the paths in schema_context
#	else: ext_schema(schema_ctx, schema_ext)
	res.merge(schema_context(s, s_ext))
	return res

# --------------------------------------------------------------------------- #

# extends a schema context.  this can also be used to create a schema context
# by passing in an empty dict.  returns a new dict.
func schema_context(
	source = {}, ext: String = "", ext_absolute: String = ""
) -> Dictionary:
	var s = source.duplicate()
	if ext != "":
		if 'keywordLocation' not in s: s.keywordLocation = ""
		for key in s: s[key] = s[key].path_join(ext)	
	if ext_absolute != "":
		s.absoluteKeywordLocation = ext_absolute
	return s

# --------------------------------------------------------------------------- #

func append_sub(result: Dictionary, sub_result: Dictionary, include_valid = false):
	result.valid &= sub_result.valid
	if sub_result.valid:
		if include_valid: append_error(result, sub_result)
		return
	# sub_result is a leaf
	if 'error' in sub_result: append_error(result, sub_result)
	# sub_result is done recursing, so we can prune its children
	elif 'errors' in sub_result:
		if output_format == OutputFormat.BASIC: # flattens errors
			append_errors(result, sub_result.errors)
		else: # returns nested output
			if sub_result.errors.size() == 0: return # omit childless nodes
			if sub_result.errors.size() == 1:
				sub_result = sub_result.errors[0]
			append_error(result, sub_result)

# --------------------------------------------------------------------------- #

func append_error(result: Dictionary, error) -> void:
	if not 'errors' in result: result.errors = []
	result.errors.push_back(error)

func append_errors(result: Dictionary, errors: Array) -> void:
	if not 'errors' in result: result.errors = []
	result.errors.append_array(errors)


# =========================================================================== #
#                     V A L I D A T E   F U N C T I O N S                     #
# --------------------------------------------------------------------------- #
# reference: http://json-schema.org/draft/2020-12/json-schema-validation.html

# root validation validates a data object against a schema object.  iterate over
# keys in the data object and pick the right schema to use for each one.  if no
# schema is found, throw an error.
func validate(data: Dictionary) -> Dictionary:
	var result = new_result(1, "data")
	for key in data:
		var instance = data[key]
		var type = instance.type
		var schema = schema_root[type]
		if schema == null:
			Log.error(log_name, ["(validate) no schema found for type ", type])
		else:
			Log.debug(log_name, ["(validate) key: ", key, " | type: ", type])
			var instance_result = validate_instance(
				instance, schema, key, {}, type
			)
			if instance_result.valid == 1:
				Log.info(log_name, ["(validate_data) '", key, "' is valid! \\o/"])
			append_sub(result, instance_result)
	if result.valid == 1:
		Log.info(log_name, ["(validate_data) all data is valid! \\o/"])
	print(JSON.stringify(result, " ", false))
	return result

# validate schemas against the metaschema!
func validate_schemas() -> Dictionary:
	var metaschema = schema_root.schema
	var result = new_result(1, "schema")
	for key in schema_root:
		if key == 'schema': continue
		var instance = schema_root[key]
		Log.debug(log_name, ["(validate) schema: ", key])
		# `definitions.schema` is a special case, as it is not a schema itself
		# but a collection of schemas (analogous to '$defs' in a typical schema)
		if key == 'definitions':
			for dkey in instance:
				# sources is not a subschema, it's metadata
				if dkey == 'sources': continue
				var d = key.path_join(dkey)
				var instance_result = validate_instance(
					instance[dkey], metaschema, d, schema_context({}, 'schema')
				)
				result.valid &= instance_result.valid
				result[d] = instance_result
		else:
			var instance_result = validate_instance(
				instance, metaschema, key, schema_context({}, 'schema')
			)
			result.valid &= instance_result.valid
			result[key] = instance_result
	if result.valid == 1:
		Log.info(log_name, ["(validate_schemas) all schemas are valid! \\o/"])
	return result

# --------------------------------------------------------------------------- #

# generic validation function for a single instance, using a subschema which
# applies to the instance.  if the schema has its own subschemas (eg `allOf`,
# we recursively resolve those against the instance as appropriate.  finally,
# we pass the instance and schema into specific validators depending on the
# instance's type.  if the instance is an array or object, those functions may
# then call this one, to recursively validate the instance's children.
func validate_instance(
	data, schema, d: String = "", _s: Dictionary = {}, s_ext: String = ""
) -> Dictionary:
	var s = schema_context(_s, s_ext)
	Log.verbose(log_name, [
		"(validate_instance) start | data_path: ", d, " | schema_path: ", s])
	if schema is bool: return report(schema, E.rejected(), d, s, s_ext)
	var result = new_result(1, d, s)
	schema = schema as Dictionary
	var data_type = get_type(data)
	
	# if the schema contains a ref, resolve it using the schema_root.
	# if the schema is composed of subschemas, 
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc
	if '$ref' in schema:
		var ref_value = schema['$ref']
		Log.verbose(log_name, ["resolving ref: ", ref_value, " | data_path: ", d])
		var ref_path = ref_value.split('/')
		var ref = schema_root
		for arg in ref_path:
			if !ref.has(arg):
				var message = E.bad_ref(arg, ref_path)
				Log.warn(log_name, [
					message, " | data_path: ", d, " | schema_path: ", s
				])
				return report(false, message, d, s)
			else: ref = ref.get(arg)
#		schema.erase('$ref')
#		schema.merge(ref)
		var new_s = schema_context(s, "$ref", ref_value)
		var sub_result = validate_instance(data, ref, d, new_s)
		append_sub(result, sub_result)
		Log.verbose(log_name, ["resolved ref: ", ref_value, " | data_path: ", d])
	
	# add the instance's and schema's sources if any
	var sources = {}
	if data is Dictionary and 'sources' in data and data.sources:
		sources.data = data.sources
	if 'sources' in schema and schema.sources:
		sources.schema = schema.sources
	if !sources.is_empty(): result.sources = sources
	
	# handle resolving in-place subschemas
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc
	if 'allOf' in schema and schema.allOf is Array:
		var all_of = new_result(1, d, s, 'allOf')
		for i in schema.allOf.size():
			var subschema = schema.allOf[i]
			append_sub(all_of, validate_instance(
				data, subschema, d, s, prop_join('allOf', i)
			))
		append_sub(result, all_of)
	if 'anyOf' in schema and schema.anyOf is Array:
		var any_of = new_result(0, d, s, 'anyOf')
		for i in schema.anyOf.size():
			var subschema = schema.anyOf[i]
			var sub_result = validate_instance(
				data, subschema, d, s, prop_join('anyOf', i)
			)
			any_of.valid |= sub_result.valid
			append_sub(any_of, sub_result)
			if any_of.valid: break # can exit as soon as we find a match
		append_sub(result, any_of)
	if 'oneOf' in schema and schema.oneOf is Array:
		var one_of = new_result(1, d, s, 'oneOf')
		var passed = 0
		for i in schema.oneOf.size():
			var subschema = schema.oneOf[i]
			var sub_result = validate_instance(
				data, subschema, d, s, prop_join('oneOf', i)
			)
			append_sub(one_of, sub_result, true) # just to append errors
			passed += sub_result.valid
		one_of.valid = int(passed == 1)
		append_sub(result, one_of)
	if 'not' in schema and (schema['not'] is Dictionary or schema['not'] is bool):
		var sub_result = validate_instance(data, schema['not'])
		append_sub(result, report(
			!sub_result.valid, E.not_not_valid(), d, s, 'not'
		))
	
	# any-type validation
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-any
	if 'type' in schema:
		if schema.type is String:
			append_sub(result, report(
				matches_type(data, schema.type),
				E.type_mismatch_single(schema.type, data_type),
				d, s, 'type'
			))
		elif schema.type is Array:
			append_sub(result, report(
				matches_any(data, schema.type, matches_type),
				E.type_mismatch_plural(schema.type, data_type),
				d, s, 'type'
			))
	if 'enum' in schema and schema['enum'] is Array and !schema['enum'].is_empty():
		append_sub(result, report(
			matches_any(data, schema['enum'], Callable(U, 'deep_equals')),
			E.enum_mismatch(schema['enum'], data),
			d, s, 'enum'
		))
	if 'const' in schema:
		append_sub(result, report(
			U.deep_equals(data, schema['const']),
			E.const_mismatch(schema['const'], data),
			d, s, 'const'
		))

	# call specialized validators
	var type_fn = str('validate_', data_type)
	if has_method(type_fn):
		append_sub(result, call(type_fn, data, schema, d, s))

	Log.verbose(log_name, ["(validate_instance) ", d, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

# int values are identified as type "integer" (see `get_type`) for the benefit
# of `type` keyword validation, since we sometimes want to validate that a
# number is actually an int.  this means we will call "validate_integer" for
# them (see the end of `validate_instance`) instead of "validate_number".
func validate_integer(data, schema, d: String = "", s: Dictionary = {}) -> Dictionary:
	return validate_number(data, schema, d, s)

# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-num
func validate_number(data, schema, d: String = "", s: Dictionary = {}) -> Dictionary:
	var result = new_result(1, d, s)
	if &'multipleOf' in schema and is_number(schema.multipleOf) and schema.multipleOf > 0:
		append_sub(result, report(
			data % schema.multipleOf == 0,
			E.not_divisible(schema.multipleOf, data),
			d, s, 'multipleOf'
		))
	if &'maximum' in schema and is_number(schema.maximum):
		append_sub(result, report(
			data <= schema.maximum,
			E.maximum_exceeded(schema.maximum, data),
			d, s, 'maximum'
		))
	if &'exclusiveMaximum' in schema and is_number(schema.exclusiveMaximum):
		append_sub(result, report(
			data < schema.exclusiveMaximum,
			E.ex_max_exceeded(schema.exclusiveMaximum, data),
			d, s, 'exclusiveMaximum'
		))
	if &'minimum' in schema and is_number(schema.minimum):
		append_sub(result, report(
			data >= schema.minimum,
			E.minimum_not_met(schema.minimum, data),
			d, s, 'minimum'
		))
	if &'exclusiveMinimum' in schema and is_number(schema.exclusiveMinimum):
		append_sub(result, report(
			data > schema.exclusiveMinimum,
			E.ex_min_not_met(schema.exclusiveMinimum, data),
			d, s, 'exclusiveMinimum'
		))

	Log.verbose(log_name, ["(validate_number) ", d, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-str
func validate_string(data, schema, d: String = "", s: Dictionary = {}) -> Dictionary:
	var result = new_result(1, d, s)
	if &'maxLength' in schema and is_non_negative_int(schema.maxLength):
		append_sub(result, report(
			data.length() < schema.maxLength,
			E.max_length_exceeded(schema.maxLength, data.length()),
			d, s, 'maxLength'
		))
	if &'minLength' in schema and is_non_negative_int(schema.minLength):
		append_sub(result, report(
			data.length() > schema.minLength,
			E.min_length_not_met(schema.minLength, data.length()),
			d, s, 'minLength'
		))
	if &'pattern' in schema:
		var regex = RegEx.new()
		regex.compile(schema.pattern)
		append_sub(result, report(
			regex.is_valid() and regex.search(data) != null,
			E.pattern_mismatch(schema.pattern, data),
			d, s, 'pattern'
		))
	if &'format' in schema:
		append_sub(result, report(
			matches_format(data, schema.format),
			E.format_mismatch(schema.format, data),
			d, s, 'format'
		))
	Log.verbose(log_name, ["(validate_string) ", d, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

# TODO: maxContains & minContains
func validate_array(data, schema, d: String = "", s: Dictionary = {}) -> Dictionary:
	var result = new_result(1, d, s)
	# validate the array itself
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-arr
	if &'maxItems' in schema and is_non_negative_int(schema.maxItems):
		append_sub(result, report(
			data.size() <= schema.maxItems,
			E.max_items_exceeded(schema.maxItems, data.size()),
			d, s, 'maxItems'
		))
	if &'minItems' in schema and is_non_negative_int(schema.minItems):
		append_sub(result, report(
			data.size() >= schema.minItems,
			E.min_items_not_met(schema.minItems, data.size()),
			d, s, 'minItems'
		))
	if &'uniqueItems' in schema and schema.uniqueItems:
		var sorted = data.duplicate()
		sorted.sort()
		var dupes = []
		var i = 0
		while i < sorted.size() - 1:
			if U.deep_equals(sorted[i], sorted[i + 1]):
				dupes.push(sorted[i])
				i += 1 # skip the next iteration
			i += 1
		append_sub(result, report(
			dupes.is_empty(), E.not_unique(dupes),
			d, s, 'uniqueItems'
		))
	# apply subschemas to array items
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschema
	var prefix_items = 0
	if &'prefixItems' in schema and schema.prefixItems is Array:
		prefix_items = schema.prefixItems.size()
		append_sub(result, report(
			data.size() >= prefix_items,
			E.min_items_not_met(prefix_items, data.size()),
			d, s, 'prefixItems'
		))
		for i in range(prefix_items):
			append_sub(result, validate_instance(
				data[i], schema.prefixItems[i],
				d.path_join(str(i)), s, prop_join('prefixItems', i)
			))
	if &'items' in schema and schema.items is Dictionary:
			for i in range(prefix_items, data.size()):
				append_sub(result, validate_instance(
					data[i], schema.items, prop_join(d, i), s, 'items'
				))
	
	Log.verbose(log_name, ["(validate_array) ", d, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

func validate_dictionary(data, schema, d: String = "", s: Dictionary = {}) -> Dictionary:
	var result = new_result(1, d, s)
	# validate the object itself
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-obj
	if &'maxProperties' in schema and is_non_negative_int(schema.maxProperties):
		append_sub(result, report(
			data.size() <= schema.maxProperties,
			E.max_props_exceeded(schema.maxProperties, data.size()),
			d, s, 'maxProperties'
		))
	if &'minProperties' in schema and is_non_negative_int(schema.minProperties):
		append_sub(result, report(
			data.size() >= schema.minProperties,
			E.min_props_not_met(schema.minProperties, data.size()),
			d, s, 'minProperties'
		))
	if &'required' in schema and schema.required is Array:
		var missing = []
		for key in schema.required:
			if not data.has(key): missing.append(key)
		append_sub(result, report(
			missing.is_empty(),
			E.missing_required(missing),
			d, s, 'required'
		))
	if &'dependentRequired' in schema and schema.dependentRequired is Dictionary:
		var reqs = schema.dependentRequired
		for req in reqs:
			var missing = []
			if data.has(req):
				for key in reqs[req]:
					if not data.has(key): missing.append(key)
			append_sub(result, report(
				missing.is_empty(),
				E.missing_required(missing),
				d, s, 'dependentRequired'
			))
	# resolve subschemas for properties
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschemas
	var additional_properties = data.keys()
	if &'properties' in schema and schema.properties is Dictionary:
		for key in data:
			if key in schema.properties:
				additional_properties.erase(key)
				append_sub(result, validate_instance(
					data[key], schema.properties[key],
					d.path_join(key), s, 'properties'.path_join(key)
				))
	if &'patternProperties' in schema and schema.patternProperties is Dictionary:
		for key in data:
			for pattern in schema.patternProperties:
				var regex = RegEx.new()
				regex.compile(pattern)
				if regex.is_valid() and regex.search(key):
					additional_properties.erase(key)
					append_sub(result, validate_instance(
						data[key], schema.patternProperties[pattern],
						d.path_join(key), s, prop_join('patternProperties', pattern)
					))
	if &'additionalProperties' in schema and schema.additionalProperties is Dictionary:
		for key in additional_properties:
			append_sub(result, validate_instance(
				data[key], schema.additionalProperties, 
				d.path_join(key), s, 'additionalProperties'
			))
	
	Log.verbose(log_name, ["(validate_dictionary) ", d, " | result: ", result])
	return result


# =========================================================================== #
#                                 U T I L S                                   #
# --------------------------------------------------------------------------- #

func sources_to_string(sources: Array) -> String:
	var source_strings: PackedStringArray = []
	for i in sources.size():
		source_strings.append(str(sources[i].id, " (v", sources[i].version, ")"))
	return str("sources: ", ", ".join(source_strings))

# --------------------------------------------------------------------------- #

func get_type(data):
	return {
		TYPE_DICTIONARY: 'dictionary',
		TYPE_ARRAY: 'array',
		TYPE_INT: 'integer',
		TYPE_FLOAT: 'number',
		TYPE_NIL: 'null',
		TYPE_STRING: 'string',
		TYPE_BOOL: 'boolean'
	}[typeof(data)]

# --------------------------------------------------------------------------- #

func is_non_negative_int(x):
	return x is int and x >= 0

# sigh
func is_number(x):
	return x is int or x is float

# --------------------------------------------------------------------------- #

func matches_any(data, items, f: Callable):
	var matches = false
	for item in items:
		if f.call(data, item):
			matches = true
			break
	return matches

# --------------------------------------------------------------------------- #

func matches_type(data, type):
	match type:
		'object': return data is Dictionary
		'array': return data is Array
		'integer': return data is int
		'number': return (data is float or data is int)
		'string': return data is String
		'boolean': return data is bool
		'null': return data == null
	return true

# --------------------------------------------------------------------------- #

func matches_format(data: String, format):
	match format:
		'regex': return RegEx.create_from_string(data).is_valid()
		'filepath': return ResourceLoader.exists(data)
		'date': return true

# --------------------------------------------------------------------------- #

func prop_join(path, prop): return str(path, '[', prop, ']')
