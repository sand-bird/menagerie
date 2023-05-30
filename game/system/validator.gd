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

TODO:

1. if an instance fails validation, we bubble up a 0 result (meaning it will
   cause its parents to fail) and log a message about the failure.  instead,
   we should save failure info to a results object and log it all out at the
   end.

3. this really needs tests
"""

# 2019-03-10 01:35:11 ERROR [Validator]: Validation error in monster 'pufig':
# 'morphs.pink.name' is the wrong type (should be one of ['string', 'condition',
# 'null'], but is 'boolean'). | schema sources: my_mod (v1.0.0), menagerie
# (v0.1.0) | data sources: bobs_mod (v1.0.0), menagerie (v0.1.0)

const messages = {
	type_mismatch_single = "is the wrong type (should be %s, but is %s).",
	type_mismatch_plural = "is the wrong type (should be one of %s, but is %s).",
	enum_mismatch = "does not have an acceptable value (should be one of %s, but is %s).",
	const_mismatch = "has the wrong value (should be %s, but is %s).",
	pattern_mismatch = "does not match the required pattern '%s' (is %s).",
	max_length_exceeded = "is too long (should be up to %s characters, but is %s).",
	min_length_not_met = "is too short (should be at least %s characters, but is %s).",
	not_divisible = "is not divisible by %s (is %s).",
	maximum_exceeded = "is too large (should be at most %s, but is %s).",
	ex_max_exceeded = "is too large (should be less than %s, but is %s).",
	minimum_not_met = "is too small (should be at least %s, but is %s).",
	ex_min_not_met = "is too small (should be more than %s, but is %s).",
	max_props_exceeded = "has too many properties (should have at most %s, but has %s).",
	min_props_not_met = "has too few properties (should have at least %s, but has %s).",
	missing_required = "is missing required properties: %s.",
	max_items_exceeded = "has too many items (should have at most %s, but has %s).",
	min_items_not_met = "has too few items (should have at least %s, but has %s).",
	not_unique = "has duplicate items (%s)",
	format_mismatch = "is not a valid %s (is %s)."
}

var schema_root: Dictionary = {}

# --------------------------------------------------------------------------- #

func _init(root: Dictionary):
	schema_root = root;
	# validate root schema using a metaschema (prob hardcoded)

# --------------------------------------------------------------------------- #

# if the result is false (meaning error), we report it using the given
# arguments, then pass it along.
# - message_key: some key in our `messages` dict, for getting the error message
# - message_args: passed to the message we get after looking up `message_key`.
#     currently we don't verify whether the number of args matches up...
#     so, uh, be careful
# - breadcrumb: eg, 'pufig.morphs.pink'; identifies the thing that failed
#     validation. goes in front of our message
# - sources: when data is loaded, each mod that contributes to a data
#     definition is added to its 'sources' array. the dict we see here has
#     'data' and 'schema' keys with the sources array for each, corresponding
#     to the ROOT of the breadcrumb (eg 'pufig').
func report(result: int, message_key: String, message_args: Array,
		breadcrumb: String, sources: Dictionary) -> int:
	if not result:
		var message = str("'", breadcrumb, "' ",
				messages[message_key] % message_args)
		if 'data' in sources:
			message += " | data " + sources_to_string(sources.data)
		if 'schema' in sources:
			message += " | schema " + sources_to_string(sources.schema)
		Log.error(log_name, message)
		return 0
	else:
		return 1


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

func matches_any(data, items, f):
	var matches = false
	for item in items:
		if call(f, data, item):
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

func matches_format(data: String, format):
	match format:
		'regex': return RegEx.create_from_string(data).is_valid()
		'filepath': return ResourceLoader.exists(data)
		'date': return true

# --------------------------------------------------------------------------- #

# using hashes for a cheap deep equals. 
# not sure if this is a viable shortcut -- keep an eye on it in future
func deep_equals(a, b):
	if typeof(a) != typeof(b):
		return false
	if typeof(a) in [TYPE_DICTIONARY, TYPE_ARRAY]:
		return a.hash() == b.hash()
	return a == b


# =========================================================================== #
#                     V A L I D A T E   F U N C T I O N S                     #
# --------------------------------------------------------------------------- #
# reference: http://json-schema.org/draft/2020-12/json-schema-validation.html

# root validation validates a data object against a schema object.  iterate over
# keys in the data object and pick the right schema to use for each one.  if no
# schema is found, throw an error.
func validate(data: Dictionary) -> int:
	var result = 1
	for key in data:
		var instance = data[key]
		var type = instance.type
		var schema = schema_root[type]
		if schema == null:
			Log.error(log_name, ["(validate) no schema found for type ", type])
		else:
			Log.debug(log_name, ["(validate) key: ", key, " | type: ", type])
			var instance_result = validate_instance(instance, schema, key, {})
			if instance_result == 1:
				Log.info(log_name, ["(validate_data) '", key, "' is valid! \\o/"])
			result &= instance_result
	if result == 1:
		Log.info(log_name, ["(validate_data) all data is valid! \\o/"])
	return result

# validate schemas against the metaschema!
func validate_schemas() -> int:
	var metaschema = schema_root.schema
	var result = 1
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
				result &= validate_instance(
					instance[dkey], metaschema, str(key, '.', dkey), {}
				)
		else: 
			result &= validate_instance(instance, metaschema, key, {})
	if result == 1:
		Log.info(log_name, ["(validate_schemas) all schemas are valid! \\o/"])
	return result

# --------------------------------------------------------------------------- #

# generic validation function for a single instance, using a subschema which
# applies to the instance.  if the schema has its own subschemas (eg `allOf`,
# we recursively resolve those against the instance as appropriate.  finally,
# we pass the instance and schema into specific validators depending on the
# instance's type.  if the instance is an array or object, those functions may
# then call this one, to recursively validate the instance's children.
func validate_instance(data, schema, breadcrumb: String = "",
		sources: Dictionary = {}) -> int:
	Log.verbose(log_name, ["(validate_instance) start | breadcrumb: ", breadcrumb])
	var result = 1
	if schema is bool: return 1 if schema else 0
	schema = schema as Dictionary
	var data_type = get_type(data)
	
	# if the schema contains a ref, resolve it using the schema_root.
	# if the schema is composed of subschemas, 
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc
	if '$ref' in schema:
		var ref_value = schema['$ref']
		Log.verbose(log_name, ["resolving ref: ", ref_value, " | breadcrumb: ", breadcrumb])
		var ref_path = ref_value.split('/')
		var ref = schema_root
		for arg in ref_path:
			if !ref.has(arg):
				Log.warn(log_name, ["could not resolve ref ", arg,
					" in ", '/'.join(PackedStringArray(ref_path)),
					" | breadcrumb: ", breadcrumb])
				return 0
			else: ref = ref.get(arg)
		schema.erase('$ref')
		schema.merge(ref)
		Log.verbose(log_name, ["resolved ref: ", ref_value, " | breadcrumb: ", breadcrumb])
	
	# add the instance's and schema's sources if any
	if data is Dictionary and 'sources' in data and data.sources:
		sources.data = data.sources
	if 'sources' in schema and schema.sources:
		sources.schema = schema.sources
	
	# handle resolving in-place subschemas
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc
	if 'allOf' in schema and schema.allOf is Array:
		var sub_result = 1
		for subschema in schema.allOf:
			sub_result &= validate_instance(data, subschema, breadcrumb, sources)
			if !sub_result: break
		result &= sub_result
	if 'anyOf' in schema and schema.anyOf is Array:
		var sub_result = 0
		for subschema in schema.anyOf:
			sub_result |= validate_instance(data, subschema, breadcrumb, sources)
			if sub_result: break
		result &= sub_result
	if 'oneOf' in schema and schema.oneOf is Array:
		var passed = 0
		for subschema in schema.oneOf:
			passed += validate_instance(data, subschema, breadcrumb, sources)
			if passed > 1: break
		result &= 1 if passed == 1 else 0
	if 'not' in schema and schema['not'] is Dictionary:
		var sub_result = validate_instance(data, schema['not'], breadcrumb, sources)
		result &= 1 if not sub_result else 0
	
	# any-type validation
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-any
	if 'type' in schema:
		if schema.type is String:
			result &= report(
				matches_type(data, schema.type),
				'type_mismatch_single', [schema.type, data_type],
				breadcrumb, sources
			)
		elif schema.type is Array:
			result &= report(
				matches_any(data, schema.type, 'matches_type'),
				'type_mismatch_plural', [schema.type, data_type],
				breadcrumb, sources
			)
	if 'enum' in schema and schema['enum'] is Array and !schema['enum'].is_empty():
		result &= report(
			matches_any(data, schema['enum'], 'deep_equals'),
			'enum_mismatch', [schema['enum'], data],
			breadcrumb, sources
		)
	if 'const' in schema:
		result &= report(
			deep_equals(data, schema['const']),
			'const_mismatch', [schema['const'], data],
			breadcrumb, sources
		)

	# call specialized validators
	var type_fn = str('validate_', data_type)
	if has_method(type_fn):
		result &= call(type_fn, data, schema, breadcrumb, sources)

	Log.verbose(log_name, ["(validate_instance) ", breadcrumb, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

# int values are identified as type "integer" (see `get_type`) for the benefit
# of `type` keyword validation, since we sometimes want to validate that a
# number is actually an int.  this means we will call "validate_integer" for
# them (see the end of `validate_instance`) instead of "validate_number".
func validate_integer(data, schema, breadcrumb, sources) -> int:
	return validate_number(data, schema, breadcrumb, sources)

# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-num
func validate_number(data, schema: Dictionary,
		breadcrumb: String = "", sources: Dictionary = {}) -> int:
	var result = 1
	if 'multipleOf' in schema and is_number(schema.multipleOf) and schema.multipleOf > 0:
		result &= report(
			data % schema.multipleOf == 0,
			'not_divisible', [schema.multipleOf, data],
			breadcrumb, sources
		)
	if 'maximum' in schema and is_number(schema.maximum):
		result &= report(
			data <= schema.maximum,
			'maximum_exceeded', [schema.maximum, data],
			breadcrumb, sources
		)
	if 'exclusiveMaximum' in schema and is_number(schema.exclusiveMaximum):
		result &= report(
			data < schema.exclusiveMaximum,
			'ex_max_exceeded', [schema.exclusiveMaximum, data],
			breadcrumb, sources
		)
	if 'minimum' in schema and is_number(schema.minimum):
		result &= report(
			data >= schema.minimum,
			'minimum_not_met', [schema.minimum, data],
			breadcrumb, sources
		)
	if 'exclusiveMinimum' in schema and is_number(schema.exclusiveMinimum):
		result &= report(
			data > schema.exclusiveMinimum,
			'ex_min_not_met', [schema.exclusiveMinimum, data],
			breadcrumb, sources
		)

	Log.verbose(log_name, ["(validate_number) ", breadcrumb, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-str
func validate_string(data: String, schema: Dictionary,
		breadcrumb: String = "", sources: Dictionary = {}) -> int:
	var result = 1
	if 'maxLength' in schema and is_non_negative_int(schema.maxLength):
		result &= report(
			data.length() < schema.maxLength,
			'max_length_exceeded', [schema.maxLength, data.length()],
			breadcrumb, sources
		)
	if 'minLength' in schema and is_non_negative_int(schema.minLength):
		result &= report(
			data.length() > schema.minLength,
			'min_length_not_met', [schema.minLength, data.length()],
			breadcrumb, sources
		)
	if 'pattern' in schema:
		var regex = RegEx.new()
		regex.compile(schema.pattern)
		result &= report(
			regex.is_valid() and regex.search(data) != null,
			'pattern_mismatch', [schema.pattern, data],
			breadcrumb, sources
		)
	if 'format' in schema:
		result &= report(
			matches_format(data, schema.format),
			'format_mismatch', [schema.format, data],
			breadcrumb, sources
		)
	Log.verbose(log_name, ["(validate_string) ", breadcrumb, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

# TODO: maxContains & minContains
func validate_array(data: Array, schema: Dictionary,
		breadcrumb: String, sources: Dictionary) -> int:
	var result = 1
	# validate the array itself
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-arr
	if 'maxItems' in schema and is_non_negative_int(schema.maxItems):
		result &= report(
			data.size() <= schema.maxItems,
			'max_items_exceeded', [schema.maxItems, data.size()],
			breadcrumb, sources
		)
	if 'minItems' in schema and is_non_negative_int(schema.minItems):
		result &= report(
			data.size() >= schema.minItems,
			'min_items_not_met', [schema.minItems, data.size()],
			breadcrumb, sources
		)
	if 'uniqueItems' in schema and schema.uniqueItems:
		var sorted = data.duplicate()
		sorted.sort()
		var dupes = []
		var i = 0
		while i < sorted.size() - 1:
			if deep_equals(sorted[i], sorted[i + 1]):
				dupes.push(sorted[i])
				i += 1 # skip the next iteration
			i += 1
		result &= report(
			dupes.is_empty(), 'not_unique', [dupes],
			breadcrumb, sources
		)
	# apply subschemas to array items
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschema
	var prefix_items = 0
	if 'prefixItems' in schema and schema.prefixItems is Array:
		prefix_items = schema.prefixItems.size()
		result &= report(
			data.size() >= prefix_items,
			'min_items_not_met', [prefix_items, data.size()],
			breadcrumb, sources
		)
		for i in range(prefix_items):
			result &= validate_instance(
				data[i], schema.prefixItems[i],
				str(breadcrumb, "[", i, "]"), sources
			)
	if 'items' in schema and schema.items is Dictionary:
			for i in range(prefix_items, data.size()):
				result &= validate_instance(data[i], schema.items,
						str(breadcrumb, "[", i, "]"), sources)
	
	Log.verbose(log_name, ["(validate_array) ", breadcrumb, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

func validate_dictionary(data, schema, breadcrumb, sources) -> int:
	var result = 1
	# validate the object itself
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-obj
	if 'maxProperties' in schema and is_non_negative_int(schema.maxProperties):
		result &= report(
			data.size() <= schema.maxProperties,
			'max_props_exceeded', [schema.maxProperties, data.size()],
			breadcrumb, sources
		)
	if 'minProperties' in schema and is_non_negative_int(schema.minProperties):
		result &= report(
			data.size() >= schema.minProperties,
			'min_props_not_met', [schema.minProperties, data.size()],
			breadcrumb, sources
		)
	if 'required' in schema and schema.required is Array:
		var missing = []
		for key in schema.required:
			if not data.has(key): missing.append(key)
		result &= report(
			missing.is_empty(),
			'missing_required', [missing],
			breadcrumb, sources
		)
	if 'dependentRequired' in schema and schema.dependentRequired is Dictionary:
		var reqs = schema.dependentRequired
		for req in reqs:
			var missing = []
			if data.has(req):
				for key in reqs[req]:
					if not data.has(key): missing.append(key)
			result &= report(
				missing.is_empty(),
				'missing_required', [missing],
				breadcrumb, sources
			)
	# resolve subschemas for properties
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschemas
	var additional_properties = data.keys()
	if 'properties' in schema and schema.properties is Dictionary:
		for key in data:
			if key in schema.properties:
				additional_properties.erase(key)
				result &= validate_instance(
					data[key], schema.properties[key],
					str(breadcrumb, '.', key), sources
				)
	if 'patternProperties' in schema and schema.patternProperties is Dictionary:
		for key in data:
			for pattern in schema.patternProperties:
				var regex = RegEx.new()
				regex.compile(pattern)
				if regex.is_valid() and regex.search(key):
					additional_properties.erase(key)
					result &= validate_instance(
						data[key], schema.patternProperties[pattern],
						str(breadcrumb, '.', key), sources
					)
	if 'additionalProperties' in schema and schema.additionalProperties is Dictionary:
		for key in additional_properties:
			result &= validate_instance(
				data[key], schema.additionalProperties, 
				str(breadcrumb, '.', key), sources
			)
	
	Log.verbose(log_name, ["(validate_dictionary) ", breadcrumb, " | result: ", result])
	return result
