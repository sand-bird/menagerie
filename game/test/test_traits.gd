extends GutTest

func test_initial_value_equals_mean():
	assert_eq(Trait.new().value, 0.5)
	assert_eq(Trait.new({ mean = 0.1 }).value, 0.1)

func test_init_clamps_value():
	assert_eq(Trait.new({}, 10).value, 1.0)
	assert_eq(Trait.new({}, -10).value, 0.0)
	assert_eq(Trait.new({}, 0.1).value, 0.1)

func test_set_clamps_value():
	var t = Trait.new()
	t.value = 10
	assert_eq(t.value, 1.0)
	t.value = -10
	assert_eq(t.value, 0.0)
	t.value = 0.1
	assert_eq(t.value, 0.1)


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
	var t = Trait.new()
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
			t.value = randf_range(min, max)
			if t.value < min_test: min_test = t.value
			if t.value > max_test: max_test = t.value
			assert_eq(t.ilerp(from, to), from + i)
		prints("min_test:", min_test, " max_test:", max_test)
