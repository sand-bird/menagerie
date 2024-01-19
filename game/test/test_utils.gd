extends GutTest

# actually more like a gdscript test but w/e
func test_dict_get():
	var dict = { a = null }
	assert_eq(dict.get('a', 'some'), null)
	assert_eq(dict.get('b', 'some'), 'some')
