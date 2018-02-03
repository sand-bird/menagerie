extends Node

# TODO: put these somewhere they can be localized
const days = [ "monday", "tuesday", "wednesday", 
	"thursday", "friday", "saturday", "sunday" ]
const months = [ "verne", "tempest", "zenith", 
	"sol", "hearth", "hallow", "aurora", "rime" ]

signal tick_changed
signal hour_changed
signal day_changed
signal week_changed
signal month_changed
signal year_changed

# qualifiers for get_total_time
const YEAR = "year"
const MONTH = "month"
const DAY = "day"
const HOUR = "hour"
const TICK = "tick"

const ACTUAL_SECONDS_IN_TICK = 0.4
const TICKS_IN_HOUR = 12
const HOURS_IN_DAY = 24
const DAYS_IN_WEEK = 7
const DAYS_IN_MONTH = 21
const MONTHS_IN_YEAR = 8

var actual_seconds = 0
var tick = 0 setget _set_tick
var hour = 6 setget _set_hour
var day = 0 setget _set_day
var day_of_week = 0 setget _set_day_of_week
var month = 0 setget _set_month
var year = 0 setget _set_year

# -----------------------------------------------------------

func _ready(): set_process(true)

func _process(delta):
	actual_seconds += delta
	if try_rollover(actual_seconds, ACTUAL_SECONDS_IN_TICK, "tick") == 0:
		actual_seconds -= 1

# -----------------------------------------------------------

func _set_tick(new):
	tick = int(try_rollover(new, TICKS_IN_HOUR, "hour"))
	emit_signal("tick_changed", tick)

func _set_hour(new):
	hour = int(try_rollover(new, HOURS_IN_DAY, "day"))
	emit_signal("hour_changed", hour)

func _set_day(new):
	day = int(try_rollover(new, DAYS_IN_MONTH, "month"))
	_set_day_of_week()
	emit_signal("day_changed", day)

func _set_day_of_week(new = 0):
	print("set weekday | total days: ", get_total_time("day"))
	day_of_week = int(get_total_time("day")) % DAYS_IN_WEEK

func _set_month(new):
	month = int(try_rollover(new, MONTHS_IN_YEAR, "year"))
	emit_signal("month_changed", month)

func _set_year(new):
	year = int(new)
	emit_signal("year_changed", year)

# -----------------------------------------------------------

func stop():
	set_process(false)

func start():
	set_process(true)

func try_rollover(new_value, units_per_next_unit, next_unit):
	if new_value >= units_per_next_unit:
		self[next_unit] += 1
		return 0
	else: return new_value

# -----------------------------------------------------------

func serialize():
	return get_total_time()

func deserialize(time):
	if typeof(time) != TYPE_DICTIONARY:
		time = parse_total_time(time)
	load_dict(time)
	log_time()

# -----------------------------------------------------------

func to_dict():
	var dict = {}
	for key in ["tick", "hour", "day", "month", "year"]:
		dict[key] = self[key]
	return dict

func load_dict(dict):
	for key in dict.keys():
		self[key] = dict[key]

func get_total_time(dict = null, unit = "tick"):
	if dict == null:
		dict = to_dict()
	elif typeof(dict) == TYPE_STRING:
		unit = dict
		dict = to_dict()
	
	var units = ["year", "month", "day", "hour", "tick"]
	var relations = [MONTHS_IN_YEAR, DAYS_IN_MONTH, HOURS_IN_DAY, TICKS_IN_HOUR]
	var scale = units.find(unit)
	var total_time = 0
	
	for i in scale + 1:
		# add this unit to total
		total_time += dict[units[i]]
		# convert running total to next unit
		if i < scale: 
			total_time = total_time * relations[i]
		else: break
	
	return total_time

func parse_total_time(time, unit = "year"):
	var dict = {}
	var units = ["tick", "hour", "day", "month", "year"]
	var relations = [TICKS_IN_HOUR, HOURS_IN_DAY, DAYS_IN_MONTH, MONTHS_IN_YEAR, 1]
	var scale = units.find(unit)
	
	for i in scale + 1:
		dict[units[i]] = int(time) % relations[i]
		time = time / relations[i]
		if units[i] == "day":
			dict["day_of_week"] = int(time) % DAYS_IN_WEEK
	
	return dict

func check_dict(dict, unit):
	if dict != null:
		if dict[unit] == null: 
			dict = parse_total_time(dict, unit)
		return dict[unit]
	else:
		return self[unit]

# -----------------------------------------------------------

func get_printable_hour(input = null):
	var h = check_dict(input, "hour")
	var ampm = " AM" if h < 12 else " PM"
	var ampm_hour = h if h < 12 else h - 12
	if ampm_hour == 0: ampm_hour = 12
	var t = check_dict(input, "tick")
	var minutes = t * 60 / TICKS_IN_HOUR
	return (str(ampm_hour) + ":" + str(minutes).pad_zeros(2) + ampm)

func get_printable_date(input = null):
	var d = check_dict(input, "day")
	return Utils.ordinalize(d + 1)

func get_printable_day_of_week(input = null):
	var d_of_w = check_dict(input, "day_of_week")
	return days[d_of_w].capitalize()

func get_printable_day_of_week_abbr(input = null):
	var d_of_w = check_dict(input, "day_of_week")
	return days[d_of_w].substr(0, 3).to_upper()

func get_printable_month(input = null):
	var m = check_dict(input, "month")
	return months[m].capitalize()

func get_printable_year(input = null):
	var y = check_dict(input, "year")
	return "Year " + str(y + 1)

# -----------------------------------------------------------

func log_time():
	print("CURRENT TIME || tick: ", str(tick), " | hour: ",  str(hour),  
			" | day: ", str(day),  " (", str(day_of_week), ": ", 
			get_printable_day_of_week(), ")", " | month: ", str(month), 
			" (", get_printable_month(), ")", " | year: ", str(year))