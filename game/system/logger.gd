# Copyright (c) 2016 KOBUGE Games
# Distributed under the terms of the MIT license.
# https://github.com/KOBUGE-Games/godot-logger/blob/master/LICENSE.md
#
# Upstream repo: https://github.com/KOBUGE-Games/godot-logger

extends Node # Needed to work as a singleton

##================##
## Inner classes  ##
##================##

class Logfile:
	# TODO: Godot doesn't support docstrings for inner classes, GoDoIt (GH-1320)
	# """Class for log files that can be shared between various modules."""
	var file = null
	var path = ""
	var queue_mode = QUEUE_NONE
	var buffer = PoolStringArray()
	var buffer_idx = 0

	func _init(_path, _queue_mode = QUEUE_NONE):
		file = File.new()
		if validate_path(_path):
			path = _path
		queue_mode = _queue_mode
		buffer.resize(FILE_BUFFER_SIZE)
		var err = file.open(path, File.WRITE)
		if err:
			print("[ERROR] [logger] Could not open the '%s' log file; exited with error %d." \
					% [path, err])
			return
		file.store_string("")
		file.close()

	func get_path():
		return path

	func set_queue_mode(new_mode):
		queue_mode = new_mode

	func get_queue_mode():
		return queue_mode

	func get_write_mode():
		if not file.file_exists(path):
			return File.WRITE # create
		else:
			return File.READ_WRITE # append

	func validate_path(path):
		"""Validate the path given as argument, making it possible to write to
		the designated file or folder. Returns whether the path is valid."""
		if !(path.is_abs_path() or path.is_rel_path()):
			print("[ERROR] [logger] The given path '%s' is not valid." % path)
			return false
		var dir = Directory.new()
		var base_dir = path.get_base_dir()
		if not dir.dir_exists(base_dir):
			# TODO: Move directory creation to the function that will actually *write*
			var err = dir.make_dir_recursive(base_dir)
			if err:
				print("[ERROR] [logger] Could not create the '%s' directory; exited with error %d." \
						% [base_dir, err])
				return false
			else:
				print("[INFO] [logger] Successfully created the '%s' directory." % base_dir)
		return true

	func flush_buffer():
		"""Flush the buffer, i.e. write its contents to the target file."""
		if buffer_idx == 0:
			return # Nothing to write
		var err = file.open(path, get_write_mode())
		if err:
			print("[ERROR] [logger] Could not open the '%s' log file; exited with error %d." \
					% [path, err])
			return
		file.seek_end()
		for i in range(buffer_idx):
			file.store_line(buffer[i])
		file.close()
		buffer_idx = 0 # We don't clear the memory, we'll just overwrite it

	func write(output, level):
		"""Write the string at the end of the file (append mode), following
		the queue mode."""
		var queue_action = queue_mode
		if queue_action == QUEUE_SMART:
			if level >= WARN: # Don't queue warnings and errors
				queue_action = QUEUE_NONE
				flush_buffer()
			else: # Queue the log, not important enough for "smart"
				queue_action = QUEUE_ALL

		if queue_action == QUEUE_NONE:
			var err = file.open(path, get_write_mode())
			if err:
				print("[ERROR] [logger] Could not open the '%s' log file; exited with error %d." \
						% [path, err])
				return
			file.seek_end()
			file.store_line(output)
			file.close()

		if queue_action == QUEUE_ALL:
			buffer[buffer_idx] = output
			buffer_idx += 1
			if buffer_idx >= FILE_BUFFER_SIZE:
				flush_buffer()

	func get_config():
		return {
			"path": get_path(),
			"queue_mode": get_queue_mode()
		}

##=============##
##  Constants  ##
##=============##

const PLUGIN_NAME = "logger"

# Logging levels - the array and the integers should be matching
const LEVELS = ["VERBOSE", "DEBUG", "INFO", "WARN", "ERROR"]
const VERBOSE = 0
const DEBUG = 1
const INFO = 2
const WARN = 3
const ERROR = 4

# Output strategies
const STRATEGY_MUTE = 0
const STRATEGY_PRINT = 1
const STRATEGY_FILE = 2
const STRATEGY_MEMORY = 4
const MAX_STRATEGY = STRATEGY_MEMORY*2 - 1

# Output format identifiers
const FORMAT_IDS = {
	"date": "{DATE}",
	"level": "{LVL}",
	"node": "{NODE}",
	"message": "{MSG}"
}

# Queue modes
const QUEUE_NONE = 0
const QUEUE_ALL = 1
const QUEUE_SMART = 2

const FILE_BUFFER_SIZE = 30


##=============##
##  Variables  ##
##=============##

# Configuration
var output_level = VERBOSE
# TODO: Find (or implement in Godot) a more clever way to achieve that
var output_strategies = [
	STRATEGY_FILE,
	STRATEGY_FILE,
	STRATEGY_FILE | STRATEGY_PRINT,
	STRATEGY_FILE | STRATEGY_PRINT,
	STRATEGY_FILE | STRATEGY_PRINT
]
var logfile_path = "user://%s.log" % ProjectSettings.get_setting("application/name")
var configfile_path = "user://%s.cfg" % PLUGIN_NAME

# e.g. "[INFO] [main] The young alpaca started growing a goatie."
var output_format = "{DATE} {LVL} [{NODE}] {MSG}"

# Specific to STRATEGY_MEMORY
var max_memory_size = 30
var memory_buffer = []
var memory_idx = 0
var memory_first_loop = true
var memory_cache = []
var invalid_memory_cache = false

# Holds default and custom modules and logfiles defined by the user
# Default modules are initialized in _init via add_module
var logfile = Logfile.new(logfile_path)


##=============##
##  Functions  ##
##=============##

func get_output_strategy(level):
	match typeof(output_strategies):
		TYPE_INT:
			return output_strategies
		TYPE_ARRAY:
			return output_strategies[level]

func put(level, node, message):
	if typeof(node) == TYPE_OBJECT and "name" in node:
		node = node.name

	var output_strategy = get_output_strategy(level)

	if output_strategy == STRATEGY_MUTE or output_level > level:
		return # Out of scope

	var output = format(output_format, level, node, format_message(message))

	if output_strategy & STRATEGY_PRINT:
		print(output)

	if output_strategy & STRATEGY_FILE:
		logfile.write(output, level)

	if output_strategy & STRATEGY_MEMORY:
		memory_buffer[memory_idx] = output
		memory_idx += 1
		invalid_memory_cache = true
		if memory_idx >= max_memory_size:
			memory_idx = 0
			memory_first_loop = false


# Helper functions for each level
# -------------------------------

func verbose(node, message):
	put(VERBOSE, node, message)

func debug(node, message):
	put(DEBUG, node, message)

func info(node, message):
	put(INFO, node, message)

func warn(node, message):
	put(WARN, node, message)

func error(node, message):
	put(ERROR, node, message)


# Output formatting
# -----------------

static func get_date():
	var date = OS.get_datetime()
	var output = str(date.year)
	output += "-" + str(date.month).pad_zeros(2)
	output += "-" + str(date.day).pad_zeros(2)
	output += " " + str(date.hour).pad_zeros(2)
	output += ":" + str(date.minute).pad_zeros(2)
	output += ":" + str(date.second).pad_zeros(2)
	return output

func format_message(message):
	if typeof(message) == TYPE_ARRAY:
		var formatted_message = ""
		for arg in message:
			formatted_message += format_arg(arg)
		return formatted_message
	else: return format_arg(message)

func format_arg(arg):
	if typeof(arg) == TYPE_STRING: return arg
	elif typeof(arg) == TYPE_DICTIONARY: return to_json(arg)
	else: return str(arg)

static func format(template, level, nodename, message):
	var output = template.replace(FORMAT_IDS.date, get_date())
	output = output.replace(FORMAT_IDS.level, LEVELS[level])
	output = output.replace(FORMAT_IDS.node, nodename)
	output = output.replace(FORMAT_IDS.message, message)
	return output

func set_output_format(new_format):
	"""Set the output string format using the following identifiers:
	{LVL} for the level, {MOD} for the module, {MSG} for the message.
	The three identifiers should be contained in the output format string.
	"""
	for key in FORMAT_IDS:
		if new_format.find(FORMAT_IDS[key]) == -1:
			error("Invalid output string format. It lacks the '%s' identifier." \
					% FORMAT_IDS[key], PLUGIN_NAME)
			return
	output_format = new_format
	info("Successfully changed the output format to '%s'." % output_format, PLUGIN_NAME)

func get_output_format():
	"""Get the output string format."""
	return output_format


# Strategy "memory"
# -----------------

func set_max_memory_size(new_size):
	"""Set the maximum amount of messages to be remembered when
	using the STRATEGY_MEMORY output strategy."""
	if new_size <= 0:
		error("The maximum amount of remembered messages must be a positive non-null integer. Received %d." \
				% new_size, PLUGIN_NAME)
		return

	var new_buffer = []
	var new_idx = 0
	new_buffer.resize(new_size)

	# Better algorithm welcome :D
	if memory_first_loop:
		var offset = 0
		if memory_idx > new_size:
			offset = memory_idx - new_size
			memory_first_loop = false
		else:
			new_idx = memory_idx
		for i in range(0, min(memory_idx, new_size)):
			new_buffer[i] = memory_buffer[i + offset]
	else:
		var delta = 0
		if max_memory_size > new_size:
			delta = max_memory_size - new_size
		else:
			new_idx = max_memory_size
			memory_first_loop = true
		for i in range(0, min(max_memory_size, new_size)):
			new_buffer[i] = memory_buffer[(memory_idx + delta + i) % max_memory_size]

	memory_buffer = new_buffer
	memory_idx = new_idx
	invalid_memory_cache = true
	max_memory_size = new_size
	info("Successfully set the maximum amount of remembered messages to %d." % max_memory_size, PLUGIN_NAME)

func get_max_memory_size():
	"""Get the maximum amount of messages to be remembered when
	using the STRATEGY_MEMORY output strategy."""
	return max_memory_size

func get_memory():
	"""Get an array of the messages remembered following STRATEGY_MEMORY.
	The messages are sorted from the oldest to the newest."""
	if invalid_memory_cache: # Need to recreate the cached ordered array
		memory_cache = []
		if not memory_first_loop: # else those would be uninitialized
			for i in range(memory_idx, max_memory_size):
				memory_cache.append(memory_buffer[i])
		for i in range(0, memory_idx):
			memory_cache.append(memory_buffer[i])
		invalid_memory_cache = false
	return memory_cache

func clear_memory():
	"""Clear the buffer or remembered messages."""
	memory_buffer.clear()
	memory_idx = 0
	memory_first_loop = true
	invalid_memory_cache = true


# Configuration loading/saving
# ----------------------------

func save_config(configfile = configfile_path):
	"""Save the default configuration as well as the set of modules and
	their respective configurations.
	The ConfigFile API is used to generate the config file passed as argument.
	A unique section is used, so that it can be merged in a project's engine.cfg.
	Returns an error code (OK or some ERR_*)."""
	var config = ConfigFile.new()

	config.set_value(PLUGIN_NAME, "output_level", output_level)
	config.set_value(PLUGIN_NAME, "output_strategies", output_strategies)
	config.set_value(PLUGIN_NAME, "logfile_path", logfile_path)
	config.set_value(PLUGIN_NAME, "max_memory_size", max_memory_size)

	# Save and return the corresponding error code
	var err = config.save(configfile)
	if err:
		error("Could not save the config in '%s'; exited with error %d." \
				% [configfile, err], PLUGIN_NAME)
		return err
	info("Successfully saved the config to '%s'." % configfile, PLUGIN_NAME)
	return OK

func load_config(configfile = configfile_path):
	"""Load the configuration as well as the set of defined modules and
	their respective configurations. The expect file contents must be those
	produced by the ConfigFile API.
	Returns an error code (OK or some ERR_*)."""
	# Look for the file
	var dir = Directory.new()
	if not dir.file_exists(configfile):
		warn("Could not load the config in '%s', the file does not exist." % configfile, PLUGIN_NAME)
		return ERR_FILE_NOT_FOUND

	# Load its contents
	var config = ConfigFile.new()
	var err = config.load(configfile)
	if err:
		warn("Could not load the config in '%s'; exited with error %d." \
				% [configfile, err], PLUGIN_NAME)
		return err

	# Load default config
	output_level = config.get_value(PLUGIN_NAME, "output_level", output_level)
	output_strategies = config.get_value(PLUGIN_NAME, "output_strategies", output_strategies)
	logfile_path = config.get_value(PLUGIN_NAME, "logfile_path", logfile_path)
	max_memory_size = config.get_value(PLUGIN_NAME, "max_memory_size", max_memory_size)
	logfile = Logfile.new(logfile_path)

	info("Successfully loaded the config from '%s'." % configfile, PLUGIN_NAME)
	return OK


##=============##
##  Callbacks  ##
##=============##

func _init():
	memory_buffer.resize(max_memory_size)

func _exit_tree():
	# Flush non-empty buffers
	logfile.flush_buffer()