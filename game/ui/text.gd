extends Control

onready var font = theme.default_font

enum BufType {
	CHAR,START_POS
	IMAGE,
	NEWLINE
}

export var line_spacing: int = 2
export var text: String = '{_1.0}We can do syntax-based pauses... (or not\\.\\.\\.){n}Insert newlines and {_0.5}manual pauses{_1.0}, {>0.2}change the{/} {>1.5}speeeeeeed{/}, and use {#FF00FF}colors{/} and {~}effects!{/}'

onready var FONT_HEIGHT = font.get_height()
onready var LINE_HEIGHT = FONT_HEIGHT + line_spacing

var _buf = []

# =========================================================================== #
#                          I N P U T   P A R S I N G                          #
# --------------------------------------------------------------------------- #
const TOKENS = {
	'+': { key = 'anim', value = 'shaky' },
	'~': { key = 'anim', value = 'wavy' },
	'#': { key = 'color' },
	'>': { key = 'speed', apply = 'float' },
	'_': { key = 'pause', apply = 'float' }
}

const PAUSES = {
	'.': 0.2,
	',': 0.1,
	'?': 0.3,
	'!': 0.3,
	'-': 0.1
}

#warning-ignore:unused_class_variable
onready var DEFAULT_COLOR = theme.get_color('font_color', 'Label')
onready var MAX_WIDTH = rect_size.x
onready var MAX_LINES = get_max_lines(FONT_HEIGHT, line_spacing, rect_size.y)
onready var CHAR_DELAY = 1 / Options.text_speed

onready var MOD_DEFAULTS = {
	'anim': false,
	'color': DEFAULT_COLOR,
	'speed': 1,
	'pause': 0
}

onready var _modifiers = MOD_DEFAULTS.duplicate(true)
var _last_modifiers = [] # for automatically closing

var _last_space = 0
var _current_line = ''
var _line_count = 1

# --------------------------------------------------------------------------- #

func _ready(): tokenize(text)

# --------------------------------------------------------------------------- #

func tokenize(raw: String) -> void:
	var current_at = 0
	var is_escaped = false

	var i = 0
	while i < raw.length():
		# if '\', escape the next character. `is_escaped` is reset to false after
		# each character is processed.
		if raw[i] == '\\' and !is_escaped:
			is_escaped = true
			i += 1
			continue

		# if it's a tag, we parse it, then continue processing the string from the
		# end of the tag. if the tag is a substitution, it manipulates `raw`, and
		# sets i to the beginning of the substitution string. if somebody sets up
		# recursive looping substitutions, we are in trouble
		elif raw[i] == '{' and !is_escaped:
			i = parse_tag(i, raw) + 1
			continue

		# if it's anything else, we can consider it a character
		current_at += CHAR_DELAY / _modifiers.speed + _modifiers.pause
		_modifiers.pause = 0

		_buf.push_back({
			type = BufType.CHAR,
			uni = raw.ord_at(i),
			at = current_at,
			anim = _modifiers.anim,
			color = (_modifiers.color if _modifiers.color
					else DEFAULT_COLOR)
		})

		# if this character has associated pause data, we add it to `current_at`
		# AFTER pushing the character to the render buffer, so that the pause
		# occurs between the current character and the next one.
		if raw[i] in PAUSES and !is_escaped:
			current_at += PAUSES[raw[i]]

		if raw[i] == ' ':
			_last_space = _buf.size() - 1

		# if we pass individual characters to get_string_size(), it can't account
		# for kerning, so we give it the whole string so far at once. as we process
		# each character, we dump it into `current_line`, then measure the result.
		_current_line += raw[i]
		if font.get_string_size(_current_line).x > MAX_WIDTH:
			insert_newline(true)

		# housekeeping
		is_escaped = false
		i += 1

# --------------------------------------------------------------------------- #

func insert_newline(use_last_space = false):
	_current_line = ''
	if use_last_space and _last_space:
		_buf[_last_space] = { type = BufType.NEWLINE }
		for i in _buf.size() - _last_space:
			if 'uni' in _buf[i]:
				print(char(_buf[i].uni))
				_current_line += char(_buf[i].uni)
	else:
		_buf.push_back({ type = BufType.NEWLINE })
	_last_space = 0
	_line_count += 1

# --------------------------------------------------------------------------- #

func parse_tag(i: int, raw: String) -> int:
	# find the bounds of our tag. we always skip over the tab opener unless it
	# was explicitly escaped; but if the tag is invalid, we can return without
	# doing anything else.
	var end_of_tag: int = raw.find('}', i)
	var start_of_next_tag: int = raw.find('{', i + 1)
	if end_of_tag < 0 or (start_of_next_tag > 0
			and end_of_tag > start_of_next_tag):
		return i

	var tag = raw.substr(i + 1, end_of_tag - i - 1).replace(' ', '')
	# if tag is blank, we can safely skip it
	if !tag: return end_of_tag

	# whatever is not the token is the argument
	var arg: String = tag.right(1)

	if tag[0] in TOKENS:
		set_modifier(tag[0], arg)
	elif tag[0] == '/':
		if arg: reset_modifier(arg)
		elif !_last_modifiers.empty():
			reset_modifier(_last_modifiers.pop_back())
	elif tag[0] == 'n':
		insert_newline()

	return end_of_tag

# --------------------------------------------------------------------------- #

func set_modifier(token, arg):
	var mod = TOKENS[token]
	if arg:
		_modifiers[mod.key] = (
			call(mod.apply, arg)
			if exists_in('apply', mod)
			else arg
		)
	else:
		_modifiers[mod.key] = (
			mod.value
			if 'value' in mod
			else MOD_DEFAULTS[mod.key]
		)
	_last_modifiers.push_back(token)

func reset_modifier(token):
	var modkey = TOKENS[token].key
	_modifiers[modkey] = MOD_DEFAULTS[modkey]


# =========================================================================== #
#                              R E N D E R I N G                              #
# --------------------------------------------------------------------------- #
onready var rid = get_canvas_item()
onready var START_POS = Vector2(0, font.get_ascent())

var time = 0.0

func _physics_process(delta: float):
	time += delta
	update()

# --------------------------------------------------------------------------- #

func _draw():
	var pos = START_POS
	for i in _buf.size():
		if 'at' in _buf[i] and time < _buf[i].at: return
		match _buf[i].type:
			BufType.NEWLINE:
				pos.x = START_POS.x
				pos.y += LINE_HEIGHT
			BufType.CHAR:
				pos.x += do_draw_char(i, pos)


#                       r e n d e r   f u n c t i o n s
# --------------------------------------------------------------------------- #

func do_draw_char(i: int, pos: Vector2) -> int:
	return font.draw_char(
		rid, do_anim(i, pos),
		_buf[i].uni, next_char(i),
		_buf[i].color
	)

# TODO
func draw_image(i: int, pos: Vector2) -> int:
	return 0

#                                h e l p e r s
# --------------------------------------------------------------------------- #

func next_char(i):
	return _buf[i + 1].uni if (i < _buf.size() - 1
			and 'uni' in _buf[i + 1]) else -1

func do_anim(i, pos) -> Vector2:
	return (call(_buf[i].anim, i, pos)
			if exists_in('anim', _buf[i]) else pos)


#                             a n i m a t i o n s
# --------------------------------------------------------------------------- #

func wavy(i, pos) -> Vector2:
	return pos + Vector2(
		0, # cos((time * 10) - i),
		sin((time * 10) - i * 0.5) * 1
	)

func wavy2(i, pos):
	return pos + Vector2(
		cos((time * 10) - i * 1.5) * 1,
		sin((time * 10) - i * 1.5) * 2
	)

func shaky(i, pos):
	return pos + Vector2(
		0 if sin(i * 2 + time) < 2 % (i + 4) - 1.2
				else sin(time * 8 + i) * 0.7,
		0 if sin(i * 2 + time) > 2 % (i + 4) - 1.8
				else sin(time * 8 + i) * 0.7
	)

# seriously why do we have to do this
func float(x): return float(x)


# =========================================================================== #
#                                  U T I L S                                  #
# --------------------------------------------------------------------------- #
func get_max_lines(font_height, line_spacing, max_height):
	var max_lines = 0
	var total_height = font_height
	while total_height < max_height:
		total_height += font_height + line_spacing
		max_lines += 1
	return max_lines

# --------------------------------------------------------------------------- #

# note: apparently we care about whether dict[prop] is truthy, not just whether
# it exists. (not sure why though - there doesn't seem to be any usage here
# where it would matter)
func exists_in(prop, dict):
	return prop in dict and dict[prop]
