extends Control

onready var font = theme.default_font
onready var DEFAULT_COLOR = theme.get_color('font_color', 'Label')
onready var rid = get_canvas_item()

enum BufType {
	CHAR,START_POS
	IMAGE,
	NEWLINE
}

const MAX_WIDTH = 200
const TEXT_SPEED = 12.0 # characters per second
var seconds_per_char = 1.0 / TEXT_SPEED

export var text = "Hel{_0.5}{ # ff00ff }lo {~}World{/#}!{/~}"

var _buf := []

func _ready():
	tokenize(text)

# =========================================================== #
#                  I N P U T   P A R S I N G                  #
# ----------------------------------------------------------- #

const TOKENS = {
	'~': { key = 'anim', value = 'wavy' },
	'#': { key = 'color' },
	'>': { key = 'speed', apply = 'float' },
	'_': { key = 'pause', apply = 'float' }
}

var MOD_DEFAULTS = {
	'anim': false,
	'color': DEFAULT_COLOR,
	'speed': 1,
	'pause': 0
}

var _current_at = 0
var _current_line_length = 0
var _last_space = -1

# todo: test if this passes by reference
var _modifiers = MOD_DEFAULTS.duplicate(true)
var _last_modifier: String # for automatically closing

func tokenize(raw: String) -> void:
	var i := 0
	var last_space := -1
	var escaped := false

	while i < raw.length():
		# should we escape the next tag character?
		if raw[i] == '\\' and !escaped:
			escaped = true
			i += 1
			continue
		# if it's a tag, we parse it, then continue processing
		# the string from the end of the tag
		if raw[i] == '{' and !escaped:
			i = parse_tag(i, raw)
			continue
		# if it's anything else, we can consider it a character
		push_to_buf(i, raw)

		_current_line_length += font.get_string_size(raw[i]).x

		escaped = false
		i += 1

# -----------------------------------------------------------

func push_to_buf(i, raw) -> void:
	var uni = raw.ord_at(i)

	var at_inc: float = seconds_per_char * _modifiers.speed
	if _modifiers.pause:
		at_inc += _modifiers.pause
		_modifiers.pause = 0
	_current_at += at_inc

	_buf.push_back({
		type = BufType.CHAR,
		uni = uni,
		at = _current_at,
		anim = _modifiers.anim,
		color = _modifiers.color if _modifiers.color else DEFAULT_COLOR
	})

# -----------------------------------------------------------

func parse_tag(i: int, raw: String) -> int:
	var end_of_tag: int = raw.find('}', i)
	var start_of_next_tag: int = raw.find('{', i + 1)
	if end_of_tag < 0 or (start_of_next_tag > 0
			and end_of_tag > start_of_next_tag):
		return i + 1

	var tag = raw.substr(i + 1, end_of_tag - i - 1).replace(' ', '')
	if !tag: return end_of_tag + 1

	var arg: String = tag.right(1)
	print('arg: ', arg)

	if tag[0] in TOKENS:
		set_modifier(tag[0], arg)
		_last_modifier = tag[0]
	elif tag[0] == '/':
		if arg: reset_modifier(arg)
		elif _last_modifier: reset_modifier(_last_modifier)

	return end_of_tag + 1

# -----------------------------------------------------------

func set_modifier(token, arg):
	var mod = TOKENS[token]
	if arg:
		_modifiers[mod.key] = call(mod.apply, arg) if safe_truthy('apply', mod) else arg
	else:
		_modifiers[mod.key] =  mod.value if 'value' in mod else MOD_DEFAULTS[mod.key]


func reset_modifier(token):
	var modkey = TOKENS[token].key
	_modifiers[modkey] = MOD_DEFAULTS[modkey]


# =========================================================== #
#                      R E N D E R I N G                      #
# ----------------------------------------------------------- #

onready var START_POS = Vector2(0, font.get_ascent()) # rect_global_position + Vector2(0, font.get_height())

var time := 0.0

func _physics_process(delta: float):
	time += delta
	update()

# -----------------------------------------------------------

func _draw():
	var pos = START_POS
	for i in _buf.size():
		if 'at' in _buf[i] and time < _buf[i].at: return
		match _buf[i].type:
			BufType.NEWLINE:
				pos.x = START_POS.x
				pos.y += font.get_height()
			BufType.CHAR:
				pos.x += do_draw_char(i, pos)


#               r e n d e r   f u n c t i o n s
# -----------------------------------------------------------

func do_draw_char(i: int, pos: Vector2) -> int:
	return font.draw_char(
		rid, do_anim(i, pos),
		_buf[i].uni, next_char(i),
		_buf[i].color
	)

func draw_image(i: int, pos: Vector2) -> int:
	return 0

#                        h e l p e r s
# -----------------------------------------------------------

func next_char(i):
	return _buf[i + 1].uni if (i < _buf.size() - 1
			and 'uni' in _buf[i + 1]) else -1

func do_anim(i, pos) -> Vector2:
	return call(_buf[i].anim, i, pos) if safe_truthy('anim', _buf[i]) else pos

func safe_truthy(prop, dict):
	return prop in dict and dict[prop]


#                     a n i m a t i o n s
# -----------------------------------------------------------

func wavy(i, pos) -> Vector2:
	return pos + Vector2(
		0,
		cos((time * 10) - i) * 2
	)

func wavy2(i, pos):
	return pos + Vector2(
		cos((time * 10) - i * 1.5) * 1,
		sin((time * 10) - i * 1.5) * 2
	)

# seriously why do we have to do this
func float(x): return float(x)
