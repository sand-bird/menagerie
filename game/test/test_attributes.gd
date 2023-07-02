extends GutTest

func test_initial_value_equals_mean():
	assert_eq(Attribute.new().value, 0.5)
	assert_eq(Attribute.new({ mean = 0.1 }).value, 0.1)

func test_init_clamps_value():
	assert_eq(Attribute.new({}, 10).value, 1.0)
	assert_eq(Attribute.new({}, -10).value, 0.0)
	assert_eq(Attribute.new({}, 0.1).value, 0.1)

func test_set_clamps_value():
	var a = Attribute.new()
	a.value = 10
	assert_eq(a.value, 1.0)
	a.value = -10
	assert_eq(a.value, 0.0)
	a.value = 0.1
	assert_eq(a.value, 0.1)


func test_ilerp():
	ilerp_case(0, 1)
	ilerp_case(1, 1)
	ilerp_case(2, 8)
	ilerp_case(50, 500)

# each int in the range should cover an equal span of possible values, so split
# 0..1 into n partitions where n is `to` - `from`, and test that values in each
# partition yield the expected result.
func ilerp_case(from: int, to: int):
	print("-----------------------------------")
	prints("testing ilerp from", from, "to", to)
	var a = Attribute.new()
	var num_partitions = to - from + 1
	var partition_size = 1.0 / float(num_partitions)
	prints("partitions:", num_partitions, " size:", partition_size)
	for i in num_partitions:
		var min: float = partition_size * i
		var max: float = partition_size * (i + 1)
		prints("i:", i, " min:", min,  "max:", max, " expected:", from + i)
		var min_test: float = max
		var max_test: float = min
		for j in 10:
			a.value = randf_range(min, max)
			if a.value < min_test: min_test = a.value
			if a.value > max_test: max_test = a.value
			assert_eq(a.ilerp(from, to), from + i)
		prints("min_test:", min_test, " max_test:", max_test)
