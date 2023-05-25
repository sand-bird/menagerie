extends Control

"""
custom text rendering, meant to be used for dialogue boxes.

- renders text character-by-character, with delays after punctuation
- automatically inserts newlines when tokenizing text, so that words which would
  extend past the container's width are pushed to the next line
- supports various tags to modify the rendered text

TAGS & TOKENS
-------------
tokens are special characters in the input text that are not rendered as regular
text, and instead control how the text is to be rendered.

tags are tokens wrapped in curly braces, and may have argments.  some tags apply
modifiers to subsequent text until they are closed.

the {/} tag closes the last modifier applied.  you can also close a specific
modifier by adding its token as an argument, eg {/#} to close a color modifier.

the following tags are supported:
* animation modifier: {+} {~} {o}
* color modifier: {#f0f}
  - requires a hex color code as an argument
* text speed modifier: {>0.5}
  - requires a numeric argument.  this is a multipler of the default text speed.
* pause: {_1.0}
  - requires a numeric argument for how long to pause (in seconds, i think)
* newline: {n}

you can escape tokens with '\'.  in godot you also have to escape the backslash,
so `\\{` will render `{` (which would otherwise be ignored).

you can also avoid built-in pauses after puncutation by escaping the punctuation
mark - eg, `\\.\\.\\.` will render an ellipsis at the same speed as normal text.

EXECUTION
---------
first the input text is tokenized.  this populates the buffer (_buf) with dicts
having the following properties (only `type` is relevant for NEWLINEs):

* type - BufType (CHAR or NEWLINE, IMAGE isn't fully supported yet)
* uni - the unicode value of the character
* at - time at which to render the character
* anim - animation modifier, if applicable
* color - color of the text, either from modifier or DEFAULT_COLOR

RENDERING
---------
we rerender the entire buffer on every frame.  characters first appear when the
time is greater than their `at` value.  if the character has an animation, its
position is modified when we rerender it so that it appears to move around.

rendering a character uses the bitmap font's `draw_char` method, which draws the
character to the given position relative to its parent container, and returns
the position for the next character with kerning applied.  (i am not sure why
animations that move the character horizontally don't affect subsequent chars,
but it seems to work fine.)

NOTES
-----
* no support for pagination yet - we can calculate the max number of lines based
  on the size of the parent container, but we don't currently use it.
* forever incrementing `time` might cause integer overflow errors eventually
* no support yet for clearing or replacing/appending text.  appending is tricky
  because rendering depends on `time` - if we reset it, it resets animations,
  but if we don't reset it then the appended text may appear instantly.
"""

@onready var font = theme.default_font

enum BufType {
	CHAR,
	IMAGE,
	NEWLINE
}

@export var line_spacing: int = 2
@export var text: String = '{_1.0}We can do syntax-based pauses... (or not\\.\\.\\.){n}Insert newlines and {_0.5}manual pauses{_1.0}, {>0.2}change the{/} {>1.5}speeeeeeed{/}, and use {#FF00FF}colors{/} and {~}effects!{/}'

@onready var font_height = font.get_height()
@onready var line_height = font_height + line_spacing

var _buf = []

# =========================================================================== #
#                          I N P U T   P A R S I N G                          #
# --------------------------------------------------------------------------- #
const TOKENS = {
	'+': { key = 'anim', value = 'shaky' },
	'~': { key = 'anim', value = 'wavy' },
	'o': { key = 'anim', value = 'loopy' },
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
@onready var DEFAULT_COLOR = theme.get_color('font_color', 'Label')
@onready var MAX_WIDTH = size.x
@onready var MAX_LINES = get_max_lines(size.y)
@onready var CHAR_DELAY = 1 / Options.text_speed

@onready var MOD_DEFAULTS = {
	'anim': false,
	'color': DEFAULT_COLOR,
	'speed': 1,
	'pause': 0
}

# modifiers to apply to the next character we push to the buffer
@onready var _modifiers = MOD_DEFAULTS.duplicate(true)
# used for automatically closing modifiers. if we get a close tag without a
# token, pop off the last (most recent) one from here.
var _mod_tokens = []

# used during tokenization for automatic newlines. `_current_line` tells us if
# the line is too long for the container, while `_last_space` holds the index of
# the last space character in the buffer, which is replaced by a newline.
var _last_space = 0
var _current_line = ''
var current_at = 0

# updated during tokenization.
# this would be used for pagination but it's not implemented yet.
var _line_count = 1

# --------------------------------------------------------------------------- #

func _ready(): tokenize(text)

# --------------------------------------------------------------------------- #

func tokenize(raw: String) -> void:
	# time at which to render the current character. this is incremented by the
	# standard amount for each character we push to the buffer, plus any extra
	# pauses (either from punctuation or from pause tokens).
	var is_escaped = false

	var i = 0
	while i < raw.length():
		# if '\', escape the next character. `is_escaped` is reset to false after
		# each character is processed.
		if raw[i] == '\\' and !is_escaped:
			is_escaped = true
			i += 1
			continue

		# if it's a tag, we parse it, then continue processing the string from
		# the end of the tag. if the tag is a substitution, it manipulates `raw`,
		# and sets i to the beginning of the substitution string. if somebody
		# sets up recursive looping substitutions, we are in trouble
		elif raw[i] == '{' and !is_escaped:
			i = parse_tag(i, raw) + 1
			continue

		# if it's anything else, we can consider it a character
		current_at += CHAR_DELAY / _modifiers.speed + _modifiers.pause
		_modifiers.pause = 0

		_buf.push_back({
			type = BufType.CHAR,
			uni = raw.unicode_at(i),
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

		# track the position of the last space so that we can replace it with a
		# newline if the following word is too big to fit on the same line.
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

# adds a newline to the buffer. if use_last_space is true, it replaces the last
# space in the buffer with the newline, so that all text after the last space
# gets rendered to the next line. otherwise, it just appends the newline to the
# end of the buffer.
func insert_newline(use_last_space = false):
	_current_line = ''
	if use_last_space and _last_space:
		_buf[_last_space] = { type = BufType.NEWLINE }
		for i in _buf.size() - _last_space:
			if 'uni' in _buf[i]:
				_current_line += char(_buf[i].uni)
	else:
		_buf.push_back({ type = BufType.NEWLINE })
	_last_space = 0
	_line_count += 1

# --------------------------------------------------------------------------- #

func parse_tag(i: int, raw: String) -> int:
	# find the bounds of our tag. we always skip over the tag opener unless it
	# was explicitly escaped; but if the tag is invalid, we can return without
	# doing anything else.
	var end_of_tag: int = raw.find('}', i)
	var start_of_next_tag: int = raw.find('{', i + 1)
	if end_of_tag < 0 or (start_of_next_tag > 0
			and end_of_tag > start_of_next_tag):
		return i

	var tag = raw.substr(i + 1, end_of_tag - i - 1).replace(' ', '')
	# if tag is blank, we can safely skip it
	if tag == null: return end_of_tag

	# whatever is not the token is the argument
	var arg: String = tag.substr(1)

	if tag[0] in TOKENS:
		set_modifier(tag[0], arg)
	elif tag[0] == '/':
		if arg:
			reset_modifier(arg)
		elif !_mod_tokens.is_empty():
			reset_modifier(_mod_tokens.pop_back())
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
	_mod_tokens.push_back(token)


func reset_modifier(token):
	var modkey = TOKENS[token].key
	_modifiers[modkey] = MOD_DEFAULTS[modkey]


# =========================================================================== #
#                              R E N D E R I N G                              #
# --------------------------------------------------------------------------- #
@onready var rid = get_canvas_item()
@onready var START_POS = Vector2(0, font.get_ascent())

var time = 0.0

func _physics_process(delta: float):
	time += delta
	queue_redraw()

# --------------------------------------------------------------------------- #

func _draw():
	var pos = START_POS
	for i in _buf.size():
		if 'at' in _buf[i] and time < _buf[i].at: return
		match _buf[i].type:
			BufType.NEWLINE:
				pos.x = START_POS.x
				pos.y += line_height
			BufType.CHAR:
				pos.x += do_draw_char(i, pos)


#                       r e n d e r   f u n c t i o n s
# --------------------------------------------------------------------------- #

# draw_char now takes a font size instead of the next char, meaning it doesn't
# support kerning anymore (godot recommends we not use it to draw text one
# character at a time).  screw them; we can keep using this if we can get the
# kerning for the pair and manually offset the next position.
# (note: line length calculation during tokenizing _does_ appear to work with
# kerning, so all we have to do is fix rendering)
func do_draw_char(i: int, pos: Vector2) -> int:
	return font.draw_char(
		rid,
		do_anim(i, pos),
		_buf[i].uni,
		16, # font size
#		next_char(i), # passing the next char allows the font to apply kerning
		_buf[i].color
	)

# TODO
func draw_image(i: int, pos: Vector2) -> int:
	return 0

#                                h e l p e r s
# --------------------------------------------------------------------------- #

# returns the unicode value of the next character in the buffer
func next_char(i):
	return _buf[i + 1].uni if (i < _buf.size() - 1
			and 'uni' in _buf[i + 1]) else -1

# returns the position at which we should render the character.
# this is modified by the animation on that character, if there is one.
func do_anim(i, pos) -> Vector2:
	return (call(_buf[i].anim, i, pos)
			if exists_in('anim', _buf[i]) else pos)


#                             a n i m a t i o n s
# --------------------------------------------------------------------------- #
# these take an index and a starting position, and return a modified position
# based on the index and the current time. using the index allows us to
# "stagger" the animation from one character to the next to create wavy effects.

func wavy(i, pos) -> Vector2:
	return pos + Vector2(
		0, # cos((time * 10) - i),
		sin((time * 10) - i * 0.5) * 1
	)

func loopy(i, pos):
	return pos + Vector2(
		cos((time * 10) - i * 0.4) * 1,
		sin((time * 10) - i * 0.4) * 2
	)

func shaky(i, pos):
	return pos + Vector2(
		0.0 if sin(i * 2 + time) < 2 % (i + 4) - 1.2
				else sin(time * 8 + i) * 0.7,
		0.0 if sin(i * 2 + time) > 2 % (i + 4) - 1.8
				else sin(time * 8 + i) * 0.7
	)

# seriously why do we have to do this
func float(x): return float(x)


# =========================================================================== #
#                                  U T I L S                                  #
# --------------------------------------------------------------------------- #

func get_max_lines(max_height):
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
