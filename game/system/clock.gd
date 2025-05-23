extends Node

const DAY_NAMES: Array[StringName] = [
	T.MONDAY, T.TUESDAY, T.WEDNESDAY, T.THURSDAY,
	T.FRIDAY, T.SATURDAY, T.SUNDAY
]
const MONTH_NAMES: Array[StringName] = [
	T.VERNE, T.TEMPEST, T.ZENITH, T.SOL,
	T.HEARTH, T.HALLOW, T.AURORA, T.RIME 
]

const UNITS: Array[StringName] = [&'tick', &'hour', &'day', &'month', &'year']
const RELATIONS: Array[int] = [TICKS_IN_HOUR, HOURS_IN_DAY, DAYS_IN_MONTH, MONTHS_IN_YEAR]

const ACTUAL_SECONDS_IN_TICK := 0.5
const TICKS_IN_HOUR := 12
const HOURS_IN_DAY := 24
const DAYS_IN_WEEK := 7
const DAYS_IN_MONTH := 21
const MONTHS_IN_YEAR := 8

var actual_seconds: float = 0.0
var tick: int = 0: set = _set_tick
var hour: int = 0: set = _set_hour
var day: int = 0: set = _set_day
# weekday is derived from the current time
var weekday: int = 0:
	set(_x): return
	get(): return calculate_weekday()
var month := 0: set = _set_month
var year := 0: set = _set_year

# for dispatching time events after all our updates are done
var units_to_dispatch: Array[StringName] = []

# --------------------------------------------------------------------------- #

## time only moves in the garden, so it should be stopped on init,
## and starting & stopping it should be managed by the garden scene.
func _ready(): stop()

func start(): set_process(true)
func stop(): set_process(false)

func _process(delta):
	actual_seconds += delta
	if try_rollover(actual_seconds, ACTUAL_SECONDS_IN_TICK, &'tick'):
		actual_seconds -= ACTUAL_SECONDS_IN_TICK

# =========================================================================== #
#                                  S T A T E                                  #
# --------------------------------------------------------------------------- #

func _set_tick(new):
	tick = 0 if try_rollover(new, TICKS_IN_HOUR, &'hour') else int(new)
	dispatch_updates()

func _set_hour(new):
	hour = 0 if try_rollover(new, HOURS_IN_DAY, &'day') else int(new)

func _set_day(new):
	day = 0 if try_rollover(new, DAYS_IN_MONTH, &'month') else int(new)

func _set_month(new):
	month = 0 if try_rollover(new, MONTHS_IN_YEAR, &'year') else int(new)

func _set_year(new):
	year = int(new)

# --------------------------------------------------------------------------- #

## self[unit] += 1 will call the setget setter for self.unit (and it lets us
## pass the variable name as a string). each tier of unit, when modified, calls
## try_rollover for the next; in this way, the last tick of year 1 will trigger
## a cascade of rollovers that ends by incrementing year to 2.
func try_rollover(new_value: float, units_per_next_unit: float, next_unit: StringName):
	if new_value >= units_per_next_unit:
		set(next_unit, get(next_unit) + 1)
		units_to_dispatch.push_back(next_unit)
		return true
	else:
		return false

# --------------------------------------------------------------------------- #

## to ensure that the day of the week remains consistent with the date, it is
## calculated from the total elapsed days.
func calculate_weekday(input = null, unit: StringName = &'tick'):
	var total_days = duration(&'day', input, unit)
	return int(total_days) % DAYS_IN_WEEK

# --------------------------------------------------------------------------- #

## because try_rollover() pushes the update method for the NEXT unit to the
## callstack before it resolves (which must happen before we update the CURRENT
## unit), our units are actually updated in largest-to-smallest order.
##
## this is problematic for dispatching time events from within the update logic,
## as the lesser units (eg. `tick` and `hour`) have not yet been updated when a
## greater unit (eg. `day`) finishes updating and sends its dispatch. so other
## classes that listen to eg. `day` will see a Clock gobal with the correct day,
## but incorrect hours and ticks, at the time of the dispatch.
##
## to solve this, we queue all the units we need to dispatch updates for, and
## then dispatch them all at once at the end of _set_tick(), which is the last
## step of the update logic. this ensures that all our units have been fully
## updated by the time anyone else receives a dispatch.
func dispatch_updates():
	while units_to_dispatch:
		var unit = units_to_dispatch.pop_front()
		Dispatcher.emit_signal(str(unit, "_changed"))


# =========================================================================== #
#                          S E R I A L I Z A T I O N                          #
# --------------------------------------------------------------------------- #
# methods to format and return class data for saving to file, and to parse and
# load saved data into the class.  called from the save and load entrypoints
# in game.gd.

## we used to serialize clock to a timestamp, but now we use a dict for better
## clarity when viewing/editing a save file.
func serialize() -> Dictionary[StringName, int]:
	var dict: Dictionary[StringName, int] = {}
	for key in [&'tick', &'hour', &'day', &'month', &'year']:
		dict[key] = get(key) as int
	return dict

# --------------------------------------------------------------------------- #

## accepts a timestamp or time dict and uses it to set internal state.
func deserialize(time):
	var dict = to_dict(time)
	for key in dict.keys():
		set(key, dict[key])
	log_time()

# --------------------------------------------------------------------------- #

func reset():
	stop()
	deserialize(0)


# =========================================================================== #
#                       T Y P E   C O N V E R S I O N S                       #
# --------------------------------------------------------------------------- #
# these methods operate on time values which can be given in one of two formats:
# a dict with `{ tick, hour, day, month, year }` (ie the output of `serialize`),
# or a total duration represented by an integer and a unit (`tick` by default).
# the input can also be omitted, in which case we use the clock's current value.

## returns a time dict (`{ tick, hour, day, month, year }`).
## clock state (ie the current in-game time) is serialized in this format.
## the second argument is used when passing an int to be parsed as a duration.
func to_dict(input = null, unit: StringName = &'tick') -> Dictionary[StringName, int]:
	if input == null: return serialize()
	if input is Dictionary:
		var dict: Dictionary[StringName, int] = {}
		for u in UNITS:
			dict[u] = input.get(u, 0) as int
		return dict
	return parse_duration(input, unit)

# --------------------------------------------------------------------------- #

## returns the input time (or current time)'s duration in the given unit.  eg,
## `duration(&'day', { tick = 5, day = 1, month = 2, year = 3 })` would return
## `1 + (2 * DAYS_IN_MONTH) + (3 * DAYS_IN_MONTH * MONTHS_IN_YEAR)`.  note that
## lesser units (eg, days and ticks in the case of month durations) are omitted
## from the result, meaning only tick durations can be re-parsed losslessly.
func duration(unit: StringName, input = null, input_unit: StringName = &'tick'):
	assert(unit in UNITS, str("(get_duration) invalid unit: ", unit,
			" (should be one of ", UNITS, ")"))
	var dict = to_dict(input, input_unit)
	
	var units: Array[StringName] = U.reverse(UNITS)
	var relations: Array[int] = U.reverse(RELATIONS)
	var scale: int = units.find(unit)
	var dur: int = 0

	for i in scale + 1:
		# add this unit to total
		dur += dict[units[i]]
		# convert running total to next unit
		if i < scale: dur *= relations[i]
		else: break

	return dur

# --------------------------------------------------------------------------- #

## static function to parse a duration to a time dict. 
static func parse_duration(dur: int, unit: StringName = &'tick') -> Dictionary[StringName, int]:
	assert(unit in UNITS, str("(parse_duration) invalid unit: ", unit,
			" (should be one of ", UNITS, ")"))
	var dict: Dictionary[StringName, int] = {}
	var scale: int = UNITS.find(unit)
	for i in UNITS.size():
		if i < scale:
			dict[UNITS[i]] = 0
			continue
		if i < RELATIONS.size():
			dict[UNITS[i]] = int(dur) % RELATIONS[i]
			dur /= RELATIONS[i]
		else:
			dict[UNITS[i]] = int(dur)
	return dict

# =========================================================================== #
#                          P R I N T   M E T H O D S                          #
# --------------------------------------------------------------------------- #
# each takes an optional input, either a time dict or a duration integer.
# if no input is given, it uses the current time instead (see to_dict).

func format_time(input = null, unit: StringName = &'tick'):
	var dict = to_dict(input, unit)
	var ampm = "a.m." if dict.hour < 12 else "p.m."
	var ampm_hour: int = dict.hour if dict.hour < 12 else dict.hour - 12
	if ampm_hour == 0: ampm_hour = 12
	var minutes = dict.tick * 60 / TICKS_IN_HOUR
	return (str(ampm_hour) + ":" + str(minutes).pad_zeros(2) + ampm)

func format_day(input = null, unit: StringName = &'tick'):
	var d = to_dict(input, unit).day
	return U.ordinalize(d + 1)

func format_weekday(input = null, unit: StringName = &'tick'):
	var wd = calculate_weekday(input, unit)
	return tr(DAY_NAMES[wd]).capitalize()

func format_weekday_abbr(input = null, unit: StringName = &'tick'):
	var wd = calculate_weekday(input, unit)
	return tr(DAY_NAMES[wd]).substr(0, 3).to_upper()

func format_month(input = null, unit: StringName = &'tick'):
	var m = to_dict(input, unit).month
	return tr(MONTH_NAMES[m]).capitalize()

func format_year(input = null, unit: StringName = &'tick'):
	var y = to_dict(input, unit).year
	return str(tr(T.YEAR).capitalize(), " ", y + 1)

func format_date(input = null, unit: StringName = &'tick'):
	return str(
		format_month(input, unit), " ",
		format_day(input, unit), ", ",
		format_year(input, unit)
	)

func format_datetime(input = null, unit: StringName = &'tick'):
	return str(format_time(input, unit), ", ", format_date(input, unit))


# TODO: add trans text for unit names
func format_duration(
	precision: StringName, input = null, input_unit: StringName = &'tick'
):
	assert(precision in UNITS, str("(format_duration) invalid precision: ",
			precision, " (should be one of ", UNITS, ")"))
	var dict = to_dict(input, input_unit)
	var units = U.reverse(UNITS)
	var last = units.find(precision)
	
	var parts = []
	for i in units.size():
		if i > last and not parts.is_empty(): break
		var unit = units[i]
		var dur = dict[unit]
		if dur <= 0: continue
		if unit == &'tick':
			dur *= 60 / TICKS_IN_HOUR
			unit = 'minute'
		if dur > 1: unit += "s"
		parts.append(str(dur, " ", unit))
	
	return ", ".join(parts)

# --------------------------------------------------------------------------- #

func log_time():
	Log.info(self, ["CURRENT TIME || tick: ", tick, " | hour: ",  hour,
			" | day: ", day,  " (", weekday, ": ",
			format_weekday(), ")", " | month: ", month,
			" (", format_month(), ")", " | year: ", year])
