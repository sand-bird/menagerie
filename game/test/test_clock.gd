extends GutTest
"""tests for Clock"""

# pads out a time dict with 0-values, so we don't have to type these every time
func fill_dict(dict: Dictionary):
	return dict.merged({ tick = 0, hour = 0, day = 0, month = 0, year = 0 })

# these two should be equivalent
const TOTAL_TIME = 1237328
const TIME_DICT = { tick = 8, hour = 6, day = 12, month = 4, year = 25 }

# --------------------------------------------------------------------------- #

func test_to_dict_fills_missing_keys():
	assert_eq(Clock.to_dict(1), fill_dict({ tick = 1 }))
	assert_eq(Clock.to_dict(1, &'day'), fill_dict({ day = 1 }))

func test_to_dict_drops_extra_keys():
	assert_eq(
		Clock.to_dict(TIME_DICT.merged({ foo = 1, bar = 2, baz = 3 })),
		TIME_DICT
	)

# --------------------------------------------------------------------------- #

func test_duration():
	var total_years = TIME_DICT.year
	assert_eq(Clock.duration(&'year', TIME_DICT), total_years)
	var total_months = TIME_DICT.month + (total_years * Clock.MONTHS_IN_YEAR)
	assert_eq(Clock.duration(&'month', TIME_DICT), total_months)
	var total_days = TIME_DICT.day + (total_months * Clock.DAYS_IN_MONTH)
	assert_eq(Clock.duration(&'day', TIME_DICT), total_days)
	assert_eq(Clock.duration(&'tick', TIME_DICT), TOTAL_TIME)

func test_duration_with_duration():
	assert_eq(Clock.duration('year', 1, 'year'), 1)
	# get the duration in months of 1 year
	assert_eq(Clock.duration('month', 1, 'year'), Clock.MONTHS_IN_YEAR)
	# get the duration in days of 1 year
	assert_eq(Clock.duration('day', 1, 'year'), Clock.DAYS_IN_MONTH * Clock.MONTHS_IN_YEAR)

# --------------------------------------------------------------------------- #

func test_parse_duration():
	var dict = { year = 1, month = 4, day = 12, hour = 18, tick = 3 }
	var day_duration = Clock.duration('day', dict)
	assert_eq(
		Clock.parse_duration(day_duration, 'day'),
		dict.merged({ hour = 0, tick = 0 }, true)
	)
	# tick durations can be re-parsed losslessly
	var tick_duration = Clock.duration('tick', dict)
	assert_eq(
		Clock.parse_duration(tick_duration),
		dict
	)

# --------------------------------------------------------------------------- #

func test_format_duration_precision():
	var dict = { year = 1, month = 1, day = 1, hour = 1, tick = 1 }
	assert_eq(Clock.format_duration(&'year', dict), "1 year")
	assert_eq(Clock.format_duration(&'month', dict), "1 year, 1 month")
	assert_eq(Clock.format_duration(&'day', dict), "1 year, 1 month, 1 day")
	assert_eq(Clock.format_duration(&'hour', dict), "1 year, 1 month, 1 day, 1 hour")
	assert_eq(Clock.format_duration(&'tick', dict), "1 year, 1 month, 1 day, 1 hour, 5 minutes")

func test_format_duration_partial():
	var dict = { year = 0, month = 1, day = 0, hour = 1, tick = 1 }
	assert_eq(Clock.format_duration(&'year', dict), "1 month")
	assert_eq(Clock.format_duration(&'month', dict), "1 month")
	assert_eq(Clock.format_duration(&'day', dict), "1 month")
	assert_eq(Clock.format_duration(&'hour', dict), "1 month, 1 hour")
	assert_eq(Clock.format_duration(&'tick', dict), "1 month, 1 hour, 5 minutes")
