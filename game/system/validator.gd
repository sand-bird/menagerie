extends Node

# 2019-03-10 01:35:11 ERROR [Validator]: Validation error in monster 'pufig':
# 'morphs.pink.name' is the wrong type (should be one of ['string', 'condition',
# 'null'], but is 'boolean'). | schema sources: my_mod (v1.0.0), menagerie
# (v0.1.0) | data sources: bobs_mod (v1.0.0), menagerie (v0.1.0)

const messages = {
	type_mismatch_single = "is the wrong type (should be %s, but is %s).",
	type_mismatch_plural = "is the wrong type (should be one of %s, but is %s).",
	enum_mismatch = "does not have an acceptable value (should be one of %s, but is %s).",
	const_mismatch = "has the wrong value (should be %s, but is %s).",
	max_length_exceeded = "is too long (should be up to %s characters, but is %s).",
	min_length_not_met = "is too short (should be at least %s characters, but is %s).",
	not_divisible = "should be divisible by %s, but is not (remainder: %s).",
	maximum_exceeded = "is too large (should be at most %s, but is %s)."
}

# -----------------------------------------------------------

# if the result is false (meaning error), we report it using
# the given arguments, then pass it along.
# - message_key: some key in our `messages` dict, for getting
#     the error message.
# - message_args: passed to the message we get after looking
#     up `message_key`. currently we don't verify whether the
#     number of args matches up... so, uh, be careful
# - breadcrumb: eg, 'pufig.morphs.pink'; identifies the thing
#     that failed validation. goes in front of our message
# - sources: when data is loaded, each mod that contributes
#     to a data definition is added to its 'sources' array.
#     the dict we see here has 'data' and 'schema' keys with
#     the sources array for each, corresponding to the ROOT
#     of the breadcrumb (eg 'pufig').
func report(result: bool, message_key: String, message_args: Array,
		breadcrumb: String, sources: Dictionary) -> bool:
	if !result:
		var message = str("'", breadcrumb, "' ",
				messages[message_key] % message_args)

		if 'data' in sources:
			message += " | data " + sources_to_string(sources.data)
		if 'schema' in sources:
			message += " | schema " + sources_to_string(sources.schema)

		Log.error(self, message)
		print("validation error: ", message)
	return result

# -----------------------------------------------------------

func warn_schema(key: String, breadcrumb: String, sources: Dictionary) -> void:
	var message = str("schema warning: found bad keyword '", key,
			"' when testing '", breadcrumb, "'.")

	if 'schema' in sources:
		message += " | " + sources_to_string(sources.schema)

	Log.warn(self, message)
	print(message)

# -----------------------------------------------------------

func sources_to_string(sources: Array) -> String:
	var source_strings: PoolStringArray = []
	for i in sources.size():
		source_strings.append(str(sources[i].id, " (v", sources[i].version, ")"))
	return str("sources: ", source_strings.join(", "))

# -----------------------------------------------------------

func get_type(data):
	return {
		TYPE_DICTIONARY: 'dictionary',
		TYPE_ARRAY: 'array',
		TYPE_INT: 'integer',
		TYPE_REAL: 'number',
		TYPE_NIL: 'null',
		TYPE_STRING: 'string',
		TYPE_BOOL: 'boolean'
	}[typeof(data)]

# -----------------------------------------------------------

# sigh
func is_number(x):
	return x is int or x is float

# -----------------------------------------------------------

func matches_any(data, items, f):
	var matches = false
	for item in items:
		if call(f, data, item):
			matches = true
			break
	return matches

# -----------------------------------------------------------

func matches_type(data, type):
	match type:
		'object': return data is Dictionary
		'array': return data is Array
		'number': return (data is float or data is int)
		'string': return data is String
		'boolean': return data is bool
		'null': return data == null
		'integer': return data is int
	return true

# -----------------------------------------------------------

func deep_equals(a, b):
	if typeof(a) != typeof(b):
		return false
	if typeof(a) in [TYPE_DICTIONARY, TYPE_ARRAY]:
		return a.hash() == b.hash()
	return a == b


# ===========================================================
#
# -----------------------------------------------------------

func validate(data, schema: Dictionary, breadcrumb: String = "",
		sources: Dictionary = {}) -> bool:
	var result = true
	var data_type = get_type(data)

	if 'sources' in data and data.sources:
		sources.data = data.sources
	if 'sources' in schema and schema.sources:
		sources.schema = schema.sources

	# any-type validation
	if 'type' in schema:
		if schema.type is String:
			result = result && report(
				matches_type(data, schema.type),
				'type_mismatch_single', [schema.type, data_type],
				breadcrumb, sources
			)
		elif schema.type is Array:
			result = result && report(
				matches_any(data, schema.type, 'matches_type'),
				'type_mismatch_plural', [schema.type, data_type],
				breadcrumb, sources
			)
	if 'enum' in schema and schema.enum is Array and !schema.enum.empty():
		result = result && report(
			matches_any(data, schema.enum, 'deep_equals'),
			'enum_mismatch', [schema.enum, data],
			breadcrumb, sources
		)
	if 'const' in schema:
		result = result && report(
			deep_equals(data, schema.const),
			'const_mismatch', [schema.const, data],
			breadcrumb, sources
		)

	# call specialized validators
	var type_fn = str('validate_', data_type)
	if has_method(type_fn):
		result = result && call(type_fn, data, schema, breadcrumb, sources)
	return result

# -----------------------------------------------------------

func validate_integer(data, schema, breadcrumb, sources) -> bool:
	return validate_number(data, schema, breadcrumb, sources)

func validate_number(data, schema: Dictionary,
		breadcrumb: String = "", sources: Dictionary = {}) -> bool:
	var result = true
	if 'multipleOf' in schema and is_number(schema.multipleOf):
		result = result && report(
			data % schema.multipleOf == 0,
			'not_divisible', [schema.multipleOf, data % schema.multipleOf],
			breadcrumb, sources)
	if 'maximum' in schema and is_number(schema.maximum):
		result = result && report(
			data <= schema.maximum,
			'maximum_exceeded', [schema.maximum, data],
			breadcrumb, sources)
	return result

# -----------------------------------------------------------

func validate_string(data: String, schema: Dictionary,
		breadcrumb: String = "", sources: Dictionary = {}) -> bool:
	var result = true
	if 'maxLength' in schema:
		if schema.maxLength is int and schema.maxLength >= 0:
			result = result && report(
				data.length() < schema.maxLength,
				'max_length_exceeded', [schema.maxLength, data.length],
				breadcrumb, sources
			)
		else: warn_schema('maxLength', breadcrumb, sources)
	if 'minLength' in schema:
		if schema.maxLength is int and schema.maxLength >= 0:
			result = result && report(
				data.length() > schema.minLength,
				'min_length_not_met', [schema.minLength, data.length],
				breadcrumb, sources
			)
		else: warn_schema('minLength', breadcrumb, sources)
	if 'pattern' in schema:
		result = result && report(
			data.match(schema.pattern),
			'pattern_not_matched', [data, schema.pattern],
			breadcrumb, sources
		)
	return result

# -----------------------------------------------------------

func validate_array(data: Array, schema: Dictionary,
		breadcrumb: String, sources: Dictionary) -> bool:
	var is_valid = true
	# The value of "items" MUST be either a valid JSON Schema
	# or an array of valid JSON Schemas. Omitting this keyword
	# has the same behavior as an empty schema.
	if 'items' in schema:
		# If "items" is a schema, validation succeeds if all
		# elements in the array successfully validate against
		# that schema.
		if schema.items is Dictionary:
			for i in data.size():
				is_valid &= validate(data[i], schema.items,
						str(breadcrumb, "[", i, "]"), sources)
		# If "items" is an array of schemas, validation succeeds
		# if each element of the instance validates against the
		# schema at the same position, if any.
		elif schema.items is Array:
			for i in min(data.size(), schema.items.size()):
				is_valid &= validate(data[i], schema.items[i],
						str(breadcrumb, "[", i, "]"), sources)
	return is_valid
