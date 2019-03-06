extends Control

onready var font = theme.default_font
onready var color = theme.get_color('font_color', 'Label')
onready var rid = get_canvas_item()
var start_pos = Vector2(10, 14)

enum BufType {
	CHAR,
	IMAGE,
	NEWLINE
}

const TEXT_SPEED = 9.0 # characters per second
var seconds_per_char = 1.0 / TEXT_SPEED

const text = "H{}el{ # ff00ff }lo {~}Wo{/#}rld!{/~}"

const parsed = [
	"Hello ",
	{ "id": "~" },
	"World!",
	{ "id": "/" }
]

const buf_test = [
	{ type = BufType.CHAR, uni = 72, at = 0.0, color = '#FF00FF' },
	{ type = BufType.CHAR, uni = 72, at = 0.0, color = '#FF00FF' },
	{ type = BufType.NEWLINE, at = 0.25 },
	{ type = BufType.CHAR, uni = 101, at = 0.25 },
	{ type = BufType.CHAR, uni = 32, at = 1.25 },
	{ type = BufType.CHAR, uni = 87, at = 1.5, mod = 'wavy' },
	{ type = BufType.CHAR, uni = 111, at = 1.75, mod = 'wavy' },
	{ type = BufType.CHAR, uni = 33, at = 2.75, mod = 'wavy' }
]

var buf := []

func _ready():
	tokenize(text)

const TOKENS = {
	'~': {'anim': 'wavy'},
	'#': {'color': '#$1'},
	'/': null,
	'>>': null
}

# =========================================================== #
#                  I N P U T   P A R S I N G                  #
# ----------------------------------------------------------- #

var current_at = 0
var current_line_length = 0
var tokens = {
	'anim': true,
	'#': false,
	'speed_mod': [0.1, 0.5]
}

var modifiers := {}
var last_modifier: String # for automatically closing

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
		escaped = false
		current_line_length += font.get_string_size(raw[i]).x
		buf.push_back({
			type = BufType.CHAR,
			uni = raw.ord_at(i),
			at = current_at
		})
		current_at += seconds_per_char

		# remember the location of our last space so we can
		# insert a newline if we need to
		if raw[i] == ' ':
			last_space = buf.size()

		i += 1


func parse_tag(i: int, raw: String) -> int:
	var end_of_tag: int = raw.find('}', i)
	if end_of_tag < 0: return i + 1

	var tag = raw.substr(i + 1, end_of_tag - i - 1)
	print(tag)

	return end_of_tag + 1

# =========================================================== #
#                      R E N D E R I N G                      #
# ----------------------------------------------------------- #

var time := 0.0

func _physics_process(delta: float):
	time += delta
	update()

# -----------------------------------------------------------

func _draw():
	var pos = start_pos
	for i in buf.size():
		if 'at' in buf[i] and time < buf[i].at: return
		match buf[i].type:
			BufType.NEWLINE:
				pos.x = start_pos.x
				pos.y += font.get_height()
			BufType.CHAR:
				pos.x += do_draw_char(i, pos)


#               r e n d e r   f u n c t i o n s
# -----------------------------------------------------------

func do_draw_char(i, pos) -> int:
	return font.draw_char(
		rid, mod(i, pos),
		buf[i].uni, next_char(i),
		buf[i].color if 'color' in buf[i] else color
	)


#                        h e l p e r s
# -----------------------------------------------------------

func next_char(i):
	return buf[i + 1].uni if (i < buf.size() - 1
			and 'uni' in buf[i + 1]) else -1

func mod(i, pos) -> Vector2:
	return call(buf[i].mod, i, pos) if 'mod' in buf[i] else pos


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
