## Validates our json files using json-schema.  Written against the 2020-12
## draft (the latest as of 2023-07).
class_name Validator
const log_name = "Validator"

## [url]http://json-schema.org/draft/2020-12/json-schema-core.html#name-output-structure[/url]
enum OutputFormat { BASIC, DETAILED }

## A mapping of data definition types to schemas (not in itself a valid schema.)
## During validation, [param $ref] paths are resolved relative to the schema root.
var schema_root: Dictionary = {}
## See [enum OutputFormat]
var output_format: OutputFormat

# --------------------------------------------------------------------------- #

## Initialization requires a [param schema_root] object where each key is an
## entity type and each value is the schema for that type.  The root is not in
## itself a valid schema, only an index -- thus, the first step to validating
## all of our game data is to match each data definition against the correct
## schema by looking up the value of its [param type] property in [param schema_root].
## We handle this in the entrypoint function [method validate], which then calls
## [method validate_instance] to recursively validate each data definition
## as a JSON instance.
func _init(root: Dictionary, format: OutputFormat = OutputFormat.BASIC):
	schema_root = root
	output_format = format


# =========================================================================== #
#                         E R R O R   M E S S A G E S                         #
# --------------------------------------------------------------------------- #

## Namespace for error messages.  Conveninently also lets us get around the 
## "static called on instance" warning.
class E:
	static func bad_ref(arg: String, path: Array):
		return "could not resolve ref %s in %s" % [arg, '/'.join(path)]
	static func rejected():
		return "rejected (subschema is false)"
	static func not_not_valid():
		return "expected an error, but got a valid result"
	static func type_mismatch_single(a: StringName, b):
		return "wrong type (should be %s, but is %s)" % [a, b]
	static func type_mismatch_plural(a: Array, b):
		return "invalid type (should be one of %s, but is %s)" % [a, b]
	static func enum_mismatch(a: Array, b):
		return "invalid value (should be one of %s, but is %s)" % [a, b]
	static func const_mismatch(a, b):
		return "wrong value (should be %s, but is %s)" % [a, b]
	static func pattern_mismatch(a, b):
		return "pattern mismatch (should match '%s', but is %s)" % [a, b]
	static func max_length_exceeded(a: int, b: int):
		return "too long (should be up to %s characters, but is %s)" % [a, b]
	static func min_length_not_met(a: int, b: int):
		return "too short (should be at least %s characters, but is %s)" % [a, b]
	static func not_divisible(a, b):
		return "not divisible by %s (is %s)" % [a, b]
	static func maximum_exceeded(a, b):
		return "too large (should be at most %s, but is %s)" % [a, b]
	static func ex_max_exceeded(a, b):
		return "too large (should be less than %s, but is %s)" % [a, b]
	static func minimum_not_met(a, b):
		return "too small (should be at least %s, but is %s)" % [a, b]
	static func ex_min_not_met(a, b):
		return "too small (should be more than %s, but is %s)" % [a, b]
	static func max_props_exceeded(a: int, b: int):
		return "too many properties (should have at most %s, but has %s)" % [a, b]
	static func min_props_not_met(a: int, b: int):
		return "too few properties (should have at least %s, but has %s)" % [a, b]
	static func missing_required(a: Array):
		return "missing required properties: %s" % [a]
	static func max_items_exceeded(a: int, b: int):
		return "too many items (should have at most %s, but has %s)" % [a, b]
	static func min_items_not_met(a: int, b: int):
		return "too few items (should have at least %s, but has %s)" % [a, b]
	static func not_unique(a: Array):
		return "duplicate items: %s" % [a]
	static func format_mismatch(a: StringName, b):
		return "not a valid %s (is %s)" % [a, b]

# --------------------------------------------------------------------------- #

## Generates a leaf result.  If the result is invalid, adds the error message
## to the result's [param error] key.
## Note: we use int for [param valid] instead of bool so we can combine results
## with bitwise setters (eg, [code]a.valid &= b.valid[/code]).
func report(
	valid: bool, message: String, data_path: String,
	schema_ctx: Dictionary = {}, s_ext: String = ""
) -> Dictionary:
	var res = new_result(int(valid), data_path, schema_ctx, s_ext)
	if !valid: res.error = message
	return res

# --------------------------------------------------------------------------- #

## Generate a result object.  This appends the next schema key ([param s_ext])
## to the schema context [param s], if applicable, and then merges the schema
## context into the result.
## Does not include error info; that is added in [method report] (for leaves)
## and [method append] (for parents).
func new_result(
	valid: int, data_path: String = "",
	s: Dictionary = {}, s_ext: String = ""
) -> Dictionary:
	var res = { valid = valid }
	if data_path != "": res.instanceLocation = data_path
	# if we don't already have a schema context, use schema_ext to create one
	# otherwise, append schema_ext to each of the paths in schema_context
#	else: ext_schema(schema_ctx, schema_ext)
	res.merge(schema_context(s_ext, s))
	return res

# --------------------------------------------------------------------------- #

## Creates or extends a schema context, returning a new object.
## A schema context consists of two optional properties: [param keywordLocation]
## and [param absoluteKeywordLocation] (defined here: [url]http://json-schema.org/draft/2020-12/json-schema-core.html#section-12.3.1[/url]).
func schema_context(
	ext: String = "", source = {}, ext_absolute: String = ""
) -> Dictionary:
	var s = source.duplicate()
	if ext != "":
		# passing in a nonempty value for `ext` means we should start tracking
		# `keywordLocation` if we're not already
		if 'keywordLocation' not in s: s.keywordLocation = ""
		# append the new extension to each existing key
		for key in s: s[key] = s[key].path_join(ext)
	if ext_absolute != "":
		# absolute keyword locations overwrite any previous value
		s.absoluteKeywordLocation = ext_absolute
	return s

# --------------------------------------------------------------------------- #

## Appends a sub-result to a parent result.  If [param output_type] is
## [enum OutputType.BASIC], we merge the sub-result's errors array into the
## parent's to achieve a flat list; otherwise, we add the sub-result as a child
## according to these rules from the json-schema spec:
## [url]http://json-schema.org/draft/2020-12/json-schema-core.html#section-12.4.3[url]
func append_sub(result: Dictionary, sub_result: Dictionary, include_valid = false):
	result.valid &= sub_result.valid
	if sub_result.valid:
		if include_valid: _append_error(result, sub_result)
		return
	# sub_result is a leaf
	if 'error' in sub_result: _append_error(result, sub_result)
	# sub_result is done recursing, so we can prune its children
	elif 'errors' in sub_result:
		if output_format == OutputFormat.BASIC: # flattens errors
			_append_errors(result, sub_result.errors)
		else: # returns nested output
			if sub_result.errors.size() == 0: return # omit childless nodes
			if sub_result.errors.size() == 1:
				sub_result = sub_result.errors[0]
			_append_error(result, sub_result)

# --------------------------------------------------------------------------- #

func _append_error(result: Dictionary, error) -> void:
	if not 'errors' in result: result.errors = []
	result.errors.push_back(error)

func _append_errors(result: Dictionary, errors: Array) -> void:
	if not 'errors' in result: result.errors = []
	result.errors.append_array(errors)


# =========================================================================== #
#                             V A L I D A T I O N                             #
# --------------------------------------------------------------------------- #
## Reference: http://json-schema.org/draft/2020-12/json-schema-validation.html
##
## Validates a data definitions object against [param schema_root].
## Iterates over keys in the data object and picks the right schema to use for
## each one.  If no schema is found, throws an error.
func validate(data: Dictionary) -> Dictionary:
	var result = new_result(1, 'data')
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

# --------------------------------------------------------------------------- #

## Validates schemas against the metaschema at [param schema_root.schema]!
func validate_schemas() -> Dictionary:
	var metaschema = schema_root.schema
	var result = new_result(1, 'schema')
	for key in schema_root:
		if key == &'schema': continue
		var instance = schema_root[key]
		Log.debug(log_name, ["(validate) schema: ", key])
		# `definitions.schema` is a special case, as it is not a schema itself
		# but a collection of schemas (analogous to '$defs' in a typical schema)
		if key == &'definitions':
			for dkey in instance:
				# sources is not a subschema, it's metadata
				if dkey == &'sources': continue
				var d = key.path_join(dkey)
				var instance_result = validate_instance(
					instance[dkey], metaschema, d, schema_context('schema')
				)
				result.valid &= instance_result.valid
				result[d] = instance_result
		else:
			var instance_result = validate_instance(
				instance, metaschema, key, schema_context('schema')
			)
			result.valid &= instance_result.valid
			result[key] = instance_result
	if result.valid == 1:
		Log.info(log_name, ["(validate_schemas) all schemas are valid! \\o/"])
	return result

#                             c o r e   l o g i c                             #
# --------------------------------------------------------------------------- #

## Generic validation function for a single "instance", using a subschema which
## applies to the instance.  If the schema has its own subschemas (eg [param allOf]),
## we recursively resolve those against the instance as appropriate.  Finally,
## we pass the instance and schema into the dedicated validator function for the
## instance's type.  If the instance is an array or object, those functions may
## then call this one, to recursively validate the instance's children.
## Note: this can't be static because it uses [param schema_root] to resolve refs.
func validate_instance(
	data, schema, d: String = "", _s: Dictionary = {}, s_ext: String = ""
) -> Dictionary:
	var s = schema_context(s_ext, _s)
	Log.verbose(log_name, [
		"(validate_instance) start | data_path: ", d, " | schema_path: ", s])
	if schema is bool: return report(schema, E.rejected(), d, s, s_ext)
	var result = new_result(1, d, s)
	schema = schema as Dictionary
	var data_type = get_type(data)
	
	# if the schema contains a ref, resolve it using the schema_root.
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc
	if &'$ref' in schema:
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
		var new_s = schema_context("$ref", s, ref_value)
		var sub_result = validate_instance(data, ref, d, new_s)
		append_sub(result, sub_result)
		Log.verbose(log_name, ["resolved ref: ", ref_value, " | data_path: ", d])
	
	# add the instance's and schema's sources if any
	var sources = {}
	if data is Dictionary and &'sources' in data and data.sources:
		sources.data = data.sources
	if &'sources' in schema and schema.sources:
		sources.schema = schema.sources
	if !sources.is_empty(): result.sources = sources
	
	# handle resolving in-place subschemas
	# https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subsc
	if &'allOf' in schema and schema.allOf is Array:
		var all_of = new_result(1, d, s, 'allOf')
		for i in schema.allOf.size():
			var subschema = schema.allOf[i]
			append_sub(all_of, validate_instance(
				data, subschema, d, s, prop_join('allOf', i)
			))
		append_sub(result, all_of)
	if &'anyOf' in schema and schema.anyOf is Array:
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
	if &'oneOf' in schema and schema.oneOf is Array:
		var one_of = new_result(1, d, s, 'oneOf')
		var passed = 0
		for i in schema.oneOf.size():
			var subschema = schema.oneOf[i]
			var sub_result = validate_instance(
				data, subschema, d, s, prop_join('oneOf', i)
			) # also add valid results, since they may cause oneOf to fail
			append_sub(one_of, sub_result, true)
			passed += sub_result.valid
		one_of.valid = int(passed == 1)
		append_sub(result, one_of)
	if &'not' in schema and (schema['not'] is Dictionary or schema['not'] is bool):
		var sub_result = validate_instance(data, schema['not'])
		append_sub(result, report(
			!sub_result.valid, E.not_not_valid(), d, s, 'not'
		))
	
	# any-type validation
	# http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-any
	if &'type' in schema:
		if schema.type is String:
			append_sub(result, report(
				matches_type(schema.type, data),
				E.type_mismatch_single(schema.type, data_type),
				d, s, 'type'
			))
		elif schema.type is Array:
			append_sub(result, report(
				schema.type.any(matches_type.bind(data)),
				E.type_mismatch_plural(schema.type, data_type),
				d, s, 'type'
			))
	if &'enum' in schema and schema['enum'] is Array and !schema['enum'].is_empty():
		append_sub(result, report(
			schema['enum'].any(Callable(U, 'deep_equals').bind(data)),
			E.enum_mismatch(schema['enum'], data),
			d, s, 'enum'
		))
	if &'const' in schema:
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

## Calls [method validate_number]; there are no json-schema keywords specific
## to integers.  This function exists because we call type-specific validator
## functions by typename, and we identify integer values as type
## [code]"integer"[/code] so we can validate that they are actually integers.
## This means we will call [method validate_integer] for them (see the end of
## [method validate_instance]) instead of [method validate_number].
func validate_integer(
	data, schema, d: String = "", s: Dictionary = {}
) -> Dictionary:
	return validate_number(data, schema, d, s)

## [url]http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-num[/url]
func validate_number(
	data, schema, d: String = "", s: Dictionary = {}
) -> Dictionary:
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

## [url]http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-str[/url]
func validate_string(
	data, schema, d: String = "", s: Dictionary = {}
) -> Dictionary:
	var result = new_result(1, d, s)
	if &'maxLength' in schema and is_non_negative_int(schema.maxLength):
		append_sub(result, report(
			data.length() <= schema.maxLength,
			E.max_length_exceeded(schema.maxLength, data.length()),
			d, s, 'maxLength'
		))
	if &'minLength' in schema and is_non_negative_int(schema.minLength):
		append_sub(result, report(
			data.length() >= schema.minLength,
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
			matches_format(schema.format, data),
			E.format_mismatch(schema.format, data),
			d, s, 'format'
		))
	Log.verbose(log_name, ["(validate_string) ", d, " | result: ", result])
	return result

# --------------------------------------------------------------------------- #

## [url=http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-arr]Validation Keywords for Arrays[/url] / 
## [url=https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschema]Keywords for Applying Subschemas to Arrays[/url]
## (TODO: maxContains & minContains)
func validate_array(
	data, schema, d: String = "", s: Dictionary = {}
) -> Dictionary:
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
				dupes.push_back(sorted[i])
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

## [url=http://json-schema.org/draft/2020-12/json-schema-validation.html#name-validation-keywords-for-obj]Validation Keywords for Objects[/url] / 
## [url=https://json-schema.org/draft/2020-12/json-schema-core.html#name-keywords-for-applying-subschemas]Keywords for Applying Subschemas to Objects[/url]
func validate_dictionary(
	data, schema, d: String = "", s: Dictionary = {}
) -> Dictionary:
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

## Maps internal datatypes to a json type string.
func get_type(data):
	return {
		TYPE_DICTIONARY: &'dictionary',
		TYPE_ARRAY: &'array',
		TYPE_INT: &'integer',
		TYPE_FLOAT: &'number',
		TYPE_NIL: &'null',
		TYPE_STRING: &'string',
		TYPE_BOOL: &'boolean'
	}[typeof(data)]

# --------------------------------------------------------------------------- #

## Returns true if [param x] is an integer greater than 0.
func is_non_negative_int(x):
	return x is int and x >= 0

## Returns true if [param x] is an integer or a float.
func is_number(x):
	return x is int or x is float

# --------------------------------------------------------------------------- #

## Returns true if [param data]'s type matches the [param type] param, a json
## type string (object, array, integer, number, string, boolean, or null).
func matches_type(type: StringName, data: Variant) -> bool:
	match type:
		&'object': return data is Dictionary
		&'array': return data is Array
		&'integer': return data is int
		&'number': return (data is float or data is int)
		&'string': return data is String
		&'boolean': return data is bool
		&'null': return data == null
	return true

# --------------------------------------------------------------------------- #

## Validates [param data] against one of three supported format types:
## [param regex], [param filepath], or [param date] (not implemented yet).
func matches_format(format: StringName, data: String):
	match format:
		&'regex': return RegEx.create_from_string(data).is_valid()
		&'filepath': return ResourceLoader.exists(data)
		&'date': return true # TODO
		&'tag': return data in Tags.TAGS.keys()

# --------------------------------------------------------------------------- #

## Joins a path to a property or index using brackets, ie [code]path[prop][/code].
## (Json-schema uses [code]/[/code] for all joins, even indices, but I think this
## looks better.)
func prop_join(path, prop): return str(path, '[', prop, ']')
