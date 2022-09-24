extends Control

const LOGGED_LINE_HEIGHT = 13
const MAX_LOGGED_LINES = 20

var logged_lines = []
var user_input = ""

func cmd_test(args):
	self.log('test test test')

func cmd_data(args = null):
	self.log(String(Data.data))

func _ready():
	visible = false
	Dispatcher.connect("toggle_dev_console", self, "toggle")

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
		


func handle_user_input():
	"""
	User chose to enter their current input. Try to execute a command.
	"""
	self.log(user_input)
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


func log(str_to_log: String):
	for line in str_to_log.split("\n"):
		log_line(line)


func log_line(line: String):
	var l = $console
	l.add_text(line)
	l.newline()
	#l.scroll_to_line(l.get_line_count() - 1)

func toggle():
	if visible: hide()
	else: show()


func show():
	user_input = ""
	update_user_input()
#	get_tree().set_paused(true)
	.show()


func hide():
	.hide()
#	get_tree().set_paused(false)
