extends GutTest

const E = Validator.E
const OutputFormat = Validator.OutputFormat

# =========================================================================== #
#                                 U T I L S                                   #
# --------------------------------------------------------------------------- #

func p(result):
	print(JSON.stringify(result, "\t", false))

func assert_valid(result):
	assert_typeof(result, TYPE_DICTIONARY)
	assert_eq(result.valid, 1)
	assert_eq(result.get('errors', []), [])
	assert_does_not_have(result, 'error')

func assert_invalid(result, e = null):
	assert_typeof(result, TYPE_DICTIONARY)
	assert_eq(result.valid, 0)
	if e != null:
		if e is String: match_error_string(e, result)
		if e is Array: match_errors(e, result)

# --------------------------------------------------------------------------- #

# simple error message checking.  matches recursively, so will validate if the
# error message matches any leaf in the tree.
func match_error_string(error: String, result: Dictionary):
	if 'error' in result: assert_eq(error, result.error)
	if 'errors' in result: for r in result.errors: match_error_string(error, r)

# check that all keys in the expected input match keys in the result.
# does not care about keys present in result but not in expected.
func match_result(expected: Dictionary, result: Dictionary):
	for key in expected: assert_eq(expected[key], result.get(key))

# if the input is an array, we expect result to have `errors`.
# expected values can be either strings which match directly on `error` in the
# corresponding child, or dicts which can match on multiple properties.
func match_errors(expected: Array, result: Dictionary):
	assert_false(result.get('errors', []).is_empty())
	for i in expected.size():
		var error = expected[i]
		if error is String: match_error_string(error, result.errors[i])
		if error is Dictionary: match_result(error, result.errors[i])


# =========================================================================== #
#                            C O L L E C T I O N S                            #
# --------------------------------------------------------------------------- #

func test_bool_schema():
	var v = Validator.new({})
	var result = v.validate_instance(1, true)
	assert_valid(result)
	result = v.validate_instance(1, false)
	assert_invalid(result, E.rejected())

# --------------------------------------------------------------------------- #

func test_sibling_props_combine_with_refs():
	print("test_sibling_props_combine_with_refs")
	var v = Validator.new({ "req_a": { "required": ["a"] } })
	var schema = {
		"$ref": "req_a",
		"required": ["b"]
	}
	
	var result = v.validate_instance({ "a": 1 }, schema)
	assert_invalid(result, E.missing_required(["b"]))
	result = v.validate_instance({ "b": 1 }, schema)
	assert_invalid(result, E.missing_required(["a"]))
	
	result = v.validate_instance({ "a": 1, "b": 1 }, schema)
	assert_valid(result)

# --------------------------------------------------------------------------- #

func test_anyof():
	var schema = {
		"anyOf": [
			{ "const": 1 },
			{ "const": 2 },
			{ "const": 3 },
		]
	}
	var v = Validator.new({})
	
	var result = v.validate_instance(3, schema)
	assert_valid(v.validate_instance(3, schema))
	
	result = v.validate_instance(4, schema)
	var expected_errors = range(3).map(func(i): return {
		"keywordLocation": "anyOf[%s]/const" % i,
		"error": "has the wrong value (should be %s, but is 4)" % (i + 1)
	})
	assert_invalid(result, expected_errors)

# --------------------------------------------------------------------------- #

func test_oneof():
	var schema = {
		"oneOf": [
			{ "multipleOf": 2 },
			{ "multipleOf": 3 },
		]
	}
	var v = Validator.new({})
	
	# not valid against any subschemas
	var result = v.validate_instance(1, schema)
	var expected_errors = U.mapi([2, 3], func(v, i): return {
		"keywordLocation": "oneOf[%s]/multipleOf" % i,
		"error": E.not_divisible(v, 1)
	})
	assert_invalid(result, expected_errors)
	
	# valid against exactly one subschema
	result = v.validate_instance(2, schema)
	assert_valid(result)
	result = v.validate_instance(3, schema)
	assert_valid(result)
	
	# valid against both subschemas
	result = v.validate_instance(6, schema)
	expected_errors = range(2).map(func(i): return {
		"valid": 1,
		"keywordLocation": "oneOf[%s]" % i
	})
	assert_invalid(result, expected_errors)

# --------------------------------------------------------------------------- #

func test_not():
	var v = Validator.new({})
	var expected_error = {
		"keywordLocation": "not",
		"error": E.not_not_valid()
	}
	
	var result = v.validate_instance(1, { "not": true })
	assert_invalid(result, expected_error)
	result = v.validate_instance(1, { "not": false })
	assert_valid(result)
	result = v.validate_instance(1, { "not": { "const": 1 } })
	assert_invalid(result, expected_error)
	result = v.validate_instance(1, { "not": { "const": 2 } })
	assert_valid(result)
