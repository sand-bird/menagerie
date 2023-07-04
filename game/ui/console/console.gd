extends Control

const input_color = 'yellow'
const output_color = 'green'

const LOGGED_LINE_HEIGHT = 13
const MAX_LOGGED_LINES = 20

var logged_lines = []
var user_input = ""

# previously executed commands
var prev_commands = []
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
Call it with an ID to print the content of that data definition instead.
Accepts an arbitrary number of arguments; subsequent arguments can be used to inspect nested properties of a data definition.""",
	
	inventory = """Print a summary of the player's inventory.
Each key has two values:
  1. the total quantity of that item in the inventory
  2. the number of unique (unstackable) instances of that item.""",
	
	get = """Add stuff to the inventory.
Takes 3 arguments, the first of which is required:
  1. the ID of the thing to add (look up valid IDs with the {c}data{/c} command)
  2. quantity to add (default is 1)
  3. custom state (must be JSON-parseable, and cannot include any spaces)""",
	
	save = """Save the game (assuming a safe file is loaded).""",
	
	quit = """Quits the game.
Does not ask for confirmation. Don't do this by accident!""",
	
	clear = """Clear the dev console output.""",
	
	exit = """Close the console. Just like a real shell :)""",
}

# =========================================================================== #
#                               C O M M A N D S                               #
# --------------------------------------------------------------------------- #

func cmd_test(_args):
	put('test test test')

# --------------------------------------------------------------------------- #

func cmd_help(args = []):
	if args.size() == 0:
		put("The following commands are available:")
		put("  " + ', '.join(help.keys().map(
			func (key): return '{c}' + key + '{/c}'
		)))
		put("\nTry {c}help <name>{/c} for help with a specific command.")
		put("Most commands can be called with arguments separated by spaces, eg {c}time 11 23{/c}.")
	elif help.has(args[0]):
		put(help[args[0]])


#                               m o n s t e r s                               #
# --------------------------------------------------------------------------- #

func cmd_monsters(_args):
	if Player.garden == null:
		put("Error: no garden is loaded")
		return
	var mons = Player.garden.monsters.values().map(
		func (x: Monster): return x.serialize()
	)
	put(JSON.stringify(mons, "  ", false, false))

# --------------------------------------------------------------------------- #

func cmd_spawn_monster(args = []):
	if Player.garden == null:
		put("Error: no garden is loaded")
		return
	var data = JSON.parse_string(args[0]) if args.size() > 0 else {}
	var times = int(args[1]) if args.size() > 1 else 1
	for i in times: Player.garden.load_monster(data)

# --------------------------------------------------------------------------- #

func cmd_rename_monsters(args):
	if Player.garden == null:
		put("Error: no garden is loaded")
		return
	var names = []
	for uuid in Player.garden.monsters:
		var m: Monster = Player.garden.monsters[uuid]
		m.sex = m.generate_sex()
		m.monster_name = m.generate_monster_name()
		names.push_back(m.monster_name)
	put("Renamed monsters:")
	put(names)

#                           g l o b a l   s t a t e                           #
# --------------------------------------------------------------------------- #

func cmd_time(args):
	Clock.tick = int(args[0] if args.size() > 0 else Clock.tick)
	Clock.hour = int(args[1] if args.size() > 1 else Clock.hour)
	Clock.date = int(args[2] if args.size() > 2 else Clock.date)
	Clock.month = int(args[3] if args.size() > 3 else Clock.month)
	Clock.year = int(args[4] if args.size() > 4 else Clock.year)
	
	# QOL: immediately update the garden tint
	if Player.garden: Player.garden.get_node('tint').sync_anim()
	
	put([Clock.tick, Clock.hour, Clock.date, Clock.month, Clock.year])
	put(Clock.get_printable_time())

# --------------------------------------------------------------------------- #

func cmd_data(args = []):
	var data = Data.data
	if args.size() >= 1:
		data = Data.fetch(args)
	# log out the keys if the element is a dict of dicts
#	if typeof(data) == TYPE_DICTIONARY and data.values().any(
#		func (v): return typeof(v) == TYPE_DICTIONARY
#	):
	if args.size() < 1: put('{ ' + ', '.join(data.keys()) + ' }')
	else: put(JSON.stringify(data, "  ", false))


#                              i n v e n t o r y                              #
# --------------------------------------------------------------------------- #

func cmd_inventory(_args):
	var summary = {}
	for key in Player.inventory:
		var items = Player.inventory[key]
		summary[key] = [
			items.reduce(func (acc, i): return acc + i.qty, 0), # total
			items.size() # unique
		]
	put(summary)

# --------------------------------------------------------------------------- #

func cmd_get(args: Array):
	if args.size() <= 0:
		put("Error: {c}get{/c} requires a data ID")
		return
	var id = args[0]
	if Data.missing(id):
		put("Error: '" + id + "' is not a valid ID")
		return
	var qty = int(args[1]) if args.size() > 1 else 1
	var state = JSON.parse_string(args[2]) if args.size() > 2 else {}
	state.merge({ id = id }, true)
	Player.inventory_add(state, qty)


#                          g a m e   c o n t r o l s                          #
# --------------------------------------------------------------------------- #

func cmd_save(_args):
	if get_tree().current_scene.current_save_dir == null:
		put("No save file loaded!")
		return
	Dispatcher.emit('save_game')

func cmd_quit(_args):
	Dispatcher.emit('quit_game')

func cmd_reset(_args):
	Dispatcher.emit('reset_game')

# --------------------------------------------------------------------------- #

# quick n dirty way to clear _after_ we append the post-command newline
func cmd_clear(_args):
	get_tree().create_timer(0.01).timeout.connect($output.clear)

func cmd_exit(_args):
	visible = false


# =========================================================================== #
#                          O T H E R   M E T H O D S                          #
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
	if event.is_action_pressed('ui_console'):
		visible = !visible
	if visible and event.is_pressed() and event is InputEventKey:
		# Typing
		if event.unicode:
			var event_str = char(event.unicode)
			if event_str in ["~", "`"]: return
			user_input += event_str
		elif event.keycode == KEY_BACKSPACE:
			user_input = user_input.substr(0, len(user_input)-1)
		# Entering the command
		elif event.keycode == KEY_ENTER:
			handle_user_input()
		elif event.keycode == KEY_UP:
			user_input = load_previous_command(user_input)
		elif event.keycode == KEY_DOWN:
			user_input = load_next_command(user_input)
		get_viewport().set_input_as_handled()
		update_user_input()

# --------------------------------------------------------------------------- #

func load_previous_command(current_command):
	if prev_commands.is_empty() or prev_index == 0:
		return current_command
	if prev_index == null:
		stored_command = current_command
		prev_index = prev_commands.size()
	prev_index -= 1
	return prev_commands[prev_index]

func load_next_command(current_command):
	if prev_commands.is_empty() or prev_index == null:
		return current_command
	if prev_index >= prev_commands.size() - 1:
		prev_index = null
		return stored_command
	prev_index += 1
	return prev_commands[prev_index]

# --------------------------------------------------------------------------- #

# User chose to enter their current input. Try to execute a command.
func handle_user_input():
	$output.push_color(Color.from_string(input_color, Color(1, 1, 1)))
	put('> ' + user_input)
	$output.push_color(Color.from_string(output_color, Color(1, 1, 1)))
	
	# save the command to history unless it is an exact dupe
	if prev_commands.is_empty() or user_input != prev_commands.back():
		prev_commands.push_back(user_input)
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
		put('Unknown command {c}' + command_name + '{/c}')
	$output.newline()

# --------------------------------------------------------------------------- #

func update_user_input():
	$input.clear()
	$input.append_text( "> [color=" + input_color + "]" + user_input + "[/color]|")

# --------------------------------------------------------------------------- #

# substituting color bbcode for commands is so common that we do it every log,
# so that text only needs to wrap the command in {c}...{/c}
func put(x):
	for line in str(x).split("\n"):
		$output.append_text(line.format({
			'c': '[color=' + input_color + ']',
			'/c': '[/color]'
		}))
		$output.newline()

# --------------------------------------------------------------------------- #

func arget(i: int, args: Array[String], default = null):
	return args[i] if args != null and args.size() > i else default
