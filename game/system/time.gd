extends Timer

signal tick_changed
signal hour_changed
signal day_changed
signal week_changed
signal month_changed
signal year_changed

const ACTUAL_SECONDS_IN_TICK = 0.666
const TICKS_IN_HOUR = 12
const HOURS_IN_DAY = 24
const DAYS_IN_WEEK = 7
const DAYS_IN_MONTH = 21
const MONTHS_IN_YEAR = 8

const days = [ "monday", "tuesday", "wednesday", 
	"thursday", "friday", "saturday", "sunday" ]

const months = [ "verne", "tempest", "zenith", 
	"sol", "hearth", "hallow", "aurora", "rime" ]

var actual_seconds = 0
var tick = 0 setget _set_tick
var hour = 6 setget _set_hour
var day = 0 setget _set_day
var day_of_week = 0
var month = 1 setget _set_month
var year = 0 setget _set_year

func _ready(): set_process(true)

func _process(delta):
	actual_seconds += delta
	if try_rollover(actual_seconds, ACTUAL_SECONDS_IN_TICK, "tick") == 0:
		actual_seconds -= 1

func try_rollover(new_value, units_per_next_unit, next_unit):
	if new_value >= units_per_next_unit:
		self[next_unit] += 1
		return 0
	else: return new_value

func _set_tick(new):
	tick = try_rollover(new, TICKS_IN_HOUR, "hour")
	emit_signal("tick_changed", tick)

func _set_hour(new):
	hour = try_rollover(new, HOURS_IN_DAY, "day")
	emit_signal("hour_changed", hour)

func _set_day(new):
	var next_day = day_of_week + 1
	print(next_day)
	day_of_week = 0 if (next_day >= DAYS_IN_WEEK) else next_day
	day = try_rollover(new, DAYS_IN_MONTH, "month")
	emit_signal("day_changed", day)

func _set_month(new):
	month = try_rollover(new, MONTHS_IN_YEAR, "year")
	emit_signal("month_changed", month)

func _set_year(new):
	year += new
	emit_signal("year_changed", year)

func get_day():
	return days[day_of_week]

func get_month():
	return months[month]