extends Node

# TODO: put these somewhere they can be localized
const days = [ "monday", "tuesday", "wednesday", 
	"thursday", "friday", "saturday", "sunday" ]
const months = [ "verne", "tempest", "zenith", 
	"sol", "hearth", "hallow", "aurora", "rime" ]

# qualifiers for get_total_time
const YEAR = "year"
const MONTH = "month"
const DATE = "date"
const HOUR = "hour"
const TICK = "tick"

const ACTUAL_SECONDS_IN_TICK = 0.5
const TICKS_IN_HOUR = 12
const HOURS_IN_DAY = 24
const DAYS_IN_WEEK = 7
const DAYS_IN_MONTH = 21
const MONTHS_IN_YEAR = 8

var actual_seconds = 0
var tick = 0 setget _set_tick
var hour = 0 setget _set_hour
var date = 0 setget _set_date
var day = 0 setget _set_day
var month = 0 setget _set_month
var year = 0 setget _set_year

# -----------------------------------------------------------

# time only moves in the garden, so it should be stopped on
# init, and starting & stopping it should be managed by the
# garden scene.
func _ready(): stop()

func start(): set_process(true)
func stop(): set_process(false)

func _process(delta):
	actual_seconds += delta
	if try_rollover(actual_seconds, ACTUAL_SECONDS_IN_TICK, "tick") == 0:
		actual_seconds -= ACTUAL_SECONDS_IN_TICK

# ----------------------------------------------------------- #
#                U N I T   M A N A G E M E N T                #
# ----------------------------------------------------------- #

func _set_tick(new):
	tick = int(try_rollover(new, TICKS_IN_HOUR, "hour"))
	Dispatcher.emit_signal("tick_changed", tick, false)

func _set_hour(new):
	hour = int(try_rollover(new, HOURS_IN_DAY, "date"))
	Dispatcher.emit_signal("hour_changed", hour, false)

func _set_date(new):
	date = int(try_rollover(new, DAYS_IN_MONTH, "month"))
	_set_day()
	Dispatcher.emit_signal("date_changed", date)

func _set_day(new = 0):
	day = get_day()

func _set_month(new):
	month = int(try_rollover(new, MONTHS_IN_YEAR, "year"))
	Dispatcher.emit_signal("month_changed", month)

func _set_year(new):
	year = int(new)
	Dispatcher.emit_signal("year_changed", year)

# ----------------------------------------------------------- #

# self[unit] += 1 will call the setget setter for self.unit 
# (and it lets us pass the variable name as a string). each
# tier of unit, when modified, calls try_rollover for the 
# next; in this way, the last tick of year 1 will trigger a
# cascade of rollovers that ends by incrementing year to 2. 
func try_rollover(new_value, units_per_next_unit, next_unit):
	if new_value >= units_per_next_unit:
		self[next_unit] += 1
		return 0
	else: return new_value

# -----------------------------------------------------------

# to ensure that the date of the week remains consistent, it
# is calculated from the total elapsed days.
func get_day(input = null):
	var total_days = get_total_time(input, "date")
	return int(total_days) % DAYS_IN_WEEK

# =========================================================== #
#                  S E R I A L I Z A T I O N                  #
# ----------------------------------------------------------- #
# methods to format and return class data for saving to file, 
# and to parse and load saved data into the class. called by
# SaveManager's save_file and load_file, or if applicable, by
# a parent class's serialize and deserialize methods.

func serialize():
	return get_total_time()

func deserialize(time):
	if typeof(time) != TYPE_DICTIONARY:
		time = parse_total_time(time)
	load_dict(time)
	log_time()

# =========================================================== #
#                T I M E   F O R M A T T I N G                #
# ----------------------------------------------------------- #
# public Time methods should accept an optional input time,
# either as a time_dict or a total_time integer. if no input
# is given, they should use the current values from the Time
# class itself.

func get_dict():
	var dict = {}
	for key in ["tick", "hour", "date", "month", "year"]:
		dict[key] = self[key]
	return dict

func load_dict(dict):
	for key in dict.keys():
		self[key] = dict[key]

# -----------------------------------------------------------

# checks if the input is a time_dict, an integer total_time, 
# or neither, and processes it accordingly. if a unit is 
# given, returns only the value for that unit. otherwise, it
# returns a time_dict.
func to_dict(dict, unit = null):
	if dict == null:
		dict = get_dict()
	elif typeof(dict) == TYPE_STRING:
		unit = dict
		dict = get_dict()
	elif typeof(dict) != TYPE_DICTIONARY:
		dict = parse_total_time(dict, unit) if unit else parse_total_time(dict)
	
	if dict.has(unit):
		return dict[unit]
	else:
		return dict

# -----------------------------------------------------------

func get_total_time(dict = null, unit = "tick"):
	if dict == null:
		dict = get_dict()
	elif typeof(dict) == TYPE_STRING:
		unit = dict
		dict = get_dict()
	
	var units = ["year", "month", "date", "hour", "tick"]
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

# -----------------------------------------------------------

func parse_total_time(time, unit = "year"):
	var dict = {}
	var units = ["tick", "hour", "date", "month", "year"]
	var relations = [TICKS_IN_HOUR, HOURS_IN_DAY, DAYS_IN_MONTH, MONTHS_IN_YEAR]
	var scale = units.find(unit)
	for i in scale + 1:
		if relations.size() > i: 
			dict[units[i]] = int(time) % relations[i]
			time = time / relations[i]
		else:
			dict[units[i]] = int(time)
		if units[i] == "date":
			dict["day"] = int(time) % DAYS_IN_WEEK
	return dict

# ----------------------------------------------------------- #
#                  P R I N T   M E T H O D S                  #
# ----------------------------------------------------------- #
# each takes an optional input, either a time_dict or a
# total_time integer. if no input is given, it uses the 
# current time instead (see to_dict).

func get_printable_hour(input = null):
	var h = to_dict(input, "hour")
	var ampm = "a.m." if h < 12 else "p.m."
	var ampm_hour = h if h < 12 else h - 12
	if ampm_hour == 0: ampm_hour = 12
	var t = to_dict(input, "tick")
	var minutes = t * 60 / TICKS_IN_HOUR
	return (str(ampm_hour) + ":" + str(minutes).pad_zeros(2) + ampm)

func get_printable_date(input = null):
	var d = to_dict(input, "date")
	return Utils.ordinalize(d + 1)

func get_printable_day(input = null):
	var d_of_w = get_day(input)
	return days[d_of_w].capitalize()

func get_printable_day_abbr(input = null):
	var d_of_w = get_day(input)
	return days[d_of_w].substr(0, 3).to_upper()

func get_printable_month(input = null):
	var m = to_dict(input, "month")
	return months[m].capitalize()

func get_printable_year(input = null):
	var y = to_dict(input, "year")
	return "Year " + str(y + 1)

# -----------------------------------------------------------

func get_printable_time(dict = null):
	var printable_time = ""
	printable_time += get_printable_hour(dict)
	printable_time += ", " + get_printable_month(dict)
	printable_time += " " + get_printable_date(dict)
	printable_time += ", " + get_printable_year(dict)
	return printable_time

func log_time():
	Log.info(self, ["CURRENT TIME || tick: ", tick, " | hour: ",  hour,  
			" | date: ", date,  " (", day, ": ", 
			get_printable_day(), ")", " | month: ", month, 
			" (", get_printable_month(), ")", " | year: ", year])