extends Control

const LOGGED_LINE_HEIGHT = 13
const MAX_LOGGED_LINES = 20

var logged_lines = []
var user_input = ""

func cmd_time(args = null):
	self.log([Clock.tick, Clock.hour, Clock.date, Clock.month, Clock.year])

func cmd_settime(args):
	Clock.tick = int(args[0] if args.size() > 0 else Clock.tick)
	Clock.hour = int(args[1] if args.size() > 1 else Clock.hour)
	Clock.date = int(args[2] if args.size() > 2 else Clock.date)
	Clock.month = int(args[3] if args.size() > 3 else Clock.month)
	Clock.year = int(args[4] if args.size() > 4 else Clock.year)

func cmd_test(args):
	self.log('test test test')

func cmd_data(args = null):
	self.log(Data.data.keys())

func cmd_inventory(args):
	self.log(Player.inventory)

func cmd_getitem(args: Array):
	var id = args[0]
	if (!id or !Data.get(id)):
		self.log("Error - '" + id + "' is not a valid id")
	var qty = args[1] if args.size() > 1 else 1
	Player.inventory.append({ id = id, qty = qty })

func _input(event):
	if visible and event.is_pressed() and event is InputEventKey:
		# Typing
		if event.unicode:
			var event_str = char(event.unicode)
			if event_str in ["~", "`"]: return
			user_input += event_str
			get_tree().set_input_as_handled()
		elif event.scancode == KEY_BACKSPACE:
			user_input = user_input.substr(0, len(user_input)-1)
			get_tree().set_input_as_handled()
		# Entering the command
		elif event.scancode == KEY_ENTER:
			handle_user_input()
		update_user_input()
		

# User chose to enter their current input. Try to execute a command.
func handle_user_input():
	self.log('> ' + user_input)
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
		self.log('Unknown command "' + command_name + '"')


func update_user_input():
	$input.text = "> " + user_input


func log(x):
	for line in String(x).split("\n"):
		$output.add_text(line)
		$output.newline()
