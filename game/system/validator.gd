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
	max_length_exceeded = "is too long (should be under %s characters, but is %s).",
	min_length_not_met = "",
}

# -----------------------------------------------------------

func report(result, message_key, message_args, breadcrumb, sources):
	if !result:
		var message = str("'", breadcrumb, "' ",
				messages[message_key] % message_args)
		Log.error(self, message)
		print(message)
	return result

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

func validate(data, schema, breadcrumb = "", sources = {}):
	var result = true
	var data_type = get_type(data)
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
	if 'enum' in schema:
		result &= report(
			matches_any(data, schema.enum, 'deep_equals'),
			'enum_mismatch', [schema.enum, data],
			breadcrumb, sources
		)
	if 'const' in schema:
		result &= report(
			deep_equals(data, schema.const),
			'const_mismatch', [schema.const, data],
			breadcrumb, sources
		)
	var type_fn = str('validate_', data_type)
	if has_method(type_fn):
		result &= call(type_fn, data, schema, breadcrumb, sources)
	return result

# -----------------------------------------------------------

func validate_number(data, schema, breadcrumb = "", sources = {}):
	var result = true
	if 'multipleOf' in schema and (schema.multipleOf is int
			or schema.multipleOf is float):
		result &= report(
			data % schema.multipleOf == 0,
			'not_divisible', [data, schema.multipleOf],
			breadcrumb, sources)
	return result

# -----------------------------------------------------------

func validate_string(data, schema, breadcrumb = "", sources = {}):
	var result = true
	if 'maxLength' in schema:
		result &= report(
			data.length() < schema.maxLength,
			'max_length_exceeded', [schema.maxLength, data.length],
			breadcrumb, sources
		)
	if 'minLength' in schema:
		result &= report(
			data.length() > schema.minLength,
			'min_length_not_met', [schema.minLength, data.length],
			breadcrumb, sources
		)
	if 'pattern' in schema:
		result &= report(
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
