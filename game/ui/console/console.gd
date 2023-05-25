extends Control

const input_color = 'yellow'
const output_color = 'green'

const LOGGED_LINE_HEIGHT = 13
const MAX_LOGGED_LINES = 20

var logged_lines = []
var user_input = ""

# previously executed commands
var previous_commands = []
# the current index of prev_commands
var prev_index = null
# the command that was in progress before we started going through prev commands
var stored_command = ''

# =========================================================================== #
#                              H E L P   T E X T                              #
# --------------------------------------------------------------------------- #

var help = {
	help = "...",
	
	time = """Get and set the in-game time.
Call it with no arguments to print the time without changing it.
Accepts up to 5 integer arguments:
  1. tick: 0 - {t}
  2. hour: 0 - {h}
  3. date: 0 - {d}
  4. month: 0 - {m}
  5. year: 0+
(In order to set the month, you must also set the tick, hour, and date.)
Prints the current time after modification.""".format({
		t = Clock.TICKS_IN_HOUR - 1,
		h = Clock.HOURS_IN_DAY - 1,
		d = Clock.DAYS_IN_MONTH - 1,
		m = Clock.MONTHS_IN_YEAR - 1
	}),
	
	data = """Display info about data definitions.
When called with no arguments, prints the IDs of all currently loaded data definitions.
Call it with an ID to print the keys of that data definition instead.
Accepts an arbitrary number of arguments; subsequent arguments can be used to inspect nested properties of a data definition.""",
	
	inventory = """Print the contents of the player's inventory.""",
	
	get = """Add stuff to the inventory.
Requires a single argument: the ID of the thing to add (look up valid IDs with the {c}data{/c} command).
Takes an optional second argument for quantity (defaults to 1).""",
	
	save = """Save the game (assuming a safe file is loaded).""",
	
	quit = """Quits the game.
Does not ask for confirmation. Don't do this by accident!""",
	
	clear = """Clear the dev console output.""",
	
	exit = """Close the console. Just like a real shell :)""",
}

# =========================================================================== #
#                               C O M M A N D S                               #
# --------------------------------------------------------------------------- #

func cmd_help(args = []):
	if args.size() == 0:
		self.log("The following commands are available:")
		self.log("  " + ', '.join(help.keys().map(
			func (key): return '{c}' + key + '{/c}'
		)))
		self.log("\nTry {c}help <name>{/c} for help with a specific command.")
		self.log("Most commands can be called with arguments separated by spaces, eg {c}time 11 23{/c}.")
	elif help.has(args[0]):
		self.log(help[args[0]])


func cmd_time(args):
	Clock.tick = int(args[0] if args.size() > 0 else Clock.tick)
	Clock.hour = int(args[1] if args.size() > 1 else Clock.hour)
	Clock.date = int(args[2] if args.size() > 2 else Clock.date)
	Clock.month = int(args[3] if args.size() > 3 else Clock.month)
	Clock.year = int(args[4] if args.size() > 4 else Clock.year)
	
	self.log([Clock.tick, Clock.hour, Clock.date, Clock.month, Clock.year])
	self.log(Clock.get_printable_time())


func cmd_test(args):
	self.log('test test test')


func cmd_data(args = []):
	var data = Data.data
	if args.size() >= 1:
		data = Data.fetch(args)
	
	if args.size() < 1:
		self.log('{ ' + ', '.join(data.keys()) + ' }')
	# log out the keys if the element is a dict of dicts
#	if typeof(data) == TYPE_DICTIONARY and data.values().any(
#		func (v): return typeof(v) == TYPE_DICTIONARY
#	):
#		self.log('{ ' + ', '.join(data.keys()) + ' }')
	else:
		self.log(JSON.stringify(data, "  ", false))


func cmd_inventory(args):
	self.log(Player.inventory)


func cmd_get(args: Array):
	if args.size() <= 0:
		self.log("Error: {c}get{/c} requires a data ID")
		return
	var id = args[0]
	if (Data.fetch(id) == null):
		self.log("Error: '" + id + "' is not a valid id")
	var qty = args[1] if args.size() > 1 else 1
#	Player.inventory.append({ id = id, qty = qty })

func cmd_save(_args):
	if SaveManager.current_save_dir == null:
		self.log("No save file loaded!")
		return
	Dispatcher.emit('save_game')

func cmd_exit(_args):
	Dispatcher.emit("ui_toggle", "console")

func cmd_quit(_args):
	Dispatcher.emit('quit_game')

# quick n dirty way to clear _after_ we append the post-command newline
func cmd_clear(_args):
	get_tree().create_timer(0.01).timeout.connect($output.clear)

# --------------------------------------------------------------------------- #

func _ready():
	$input.add_theme_color_override(
		"default_color",
		Color.from_string(output_color, Color(1, 1, 1))
	)
	$output.add_theme_color_override(
		"default_color",
		Color.from_string(output_color, Color(1, 1, 1))
	)
	cmd_help()
	$output.newline()

# --------------------------------------------------------------------------- #

func _input(event):
	if visible and event.is_pressed() and event is InputEventKey:
		# Typing
		if event.unicode:
			var event_str = char(event.unicode)
			if event_str in ["~", "`"]: return
			user_input += event_str
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			user_input = user_input.substr(0, len(user_input)-1)
			get_viewport().set_input_as_handled()
		# Entering the command
		elif event.keycode == KEY_ENTER:
			handle_user_input()
		elif event.keycode == KEY_UP:
			user_input = load_previous_command(user_input)
		elif event.keycode == KEY_DOWN:
			user_input = load_next_command(user_input)
		update_user_input()

func load_previous_command(current_command):
	if previous_commands.is_empty() or prev_index == 0:
		return current_command
	if prev_index == null:
		stored_command = current_command
		prev_index = previous_commands.size()
	prev_index -= 1
	return previous_commands[prev_index]

func load_next_command(current_command):
	if previous_commands.is_empty() or prev_index == null:
		return current_command
	if prev_index >= previous_commands.size() - 1:
		prev_index = null
		return stored_command
	prev_index += 1
	return previous_commands[prev_index]

# User chose to enter their current input. Try to execute a command.
func handle_user_input():
	$output.push_color(Color.from_string(input_color, Color(1, 1, 1)))
	self.log('> ' + user_input)
	$output.push_color(Color.from_string(output_color, Color(1, 1, 1)))
	
	# save the command to history unless it is an exact dupe
	if user_input != previous_commands.back():
		previous_commands.push_back(user_input)
	prev_index = null
	
	# Split into space-separated tokens
	var tokens = Array(user_input.split(" "))
	user_input = ""
	if len(tokens) == 0: return
	
	# Separate the tokens into a command name and arguments
	var command_name = tokens[0]
	var arglist = []
	for t in tokens.slice(1, len(tokens)):
		if t != "":
			arglist.append(t)
	# Try to execute the command
	var method_name = "cmd_" + command_name
	if has_method(method_name):
		call(method_name, arglist)
	else:
		self.log('Unknown command {c}' + command_name + '{/c}')
	$output.newline()


func update_user_input():
	$input.text = "> [color=" + input_color + "]" + user_input + "[/color]|"

# substituting color bbcode for commands is so common that we do it every log,
# so that text only needs to wrap the command in {c}...{/c}
func log(x):
	for line in str(x).split("\n"):
		$output.append_text(line.format({
			'c': '[color=' + input_color + ']',
			'/c': '[/color]'
		}))
		$output.newline()
