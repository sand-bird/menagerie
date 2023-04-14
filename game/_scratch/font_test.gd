extends Control

const kern_pairs = {
	'A': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'B': ['"', "'", 'T', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'C': ['"', "'", '~', 'T', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'D': ['"', "'", 'b', 'h', 'k', 'l'],
	'E': ['"', "'", '~', 'T', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'F': ['.', ',', '/', '_', 'O', 'a', 'c', 'd', 'e', 'g', 'o', 's'],
	'J': ['.', ',', '/', '_', 'O', 'a', 'c', 'd', 'e', 'g', 'o', 's'],
	'L': ['"', "'", '~', 'T', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'M': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'P': ['.', ',', '/', '_'],
	'Q': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'R': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'S': ['"', "'", 'T', 'Y', 'b', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'T': ['.', ',', '/', '_', 'O', 'a', 'c', 'd', 'e', 'g', 'h', 'o', 's'],
	'U': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'V': ['.', ',', '/', '_'],
	'Y': ['.', ',', '/', '_', 'O', 'a', 'c', 'd', 'e', 'g', 'o', 's'],
	'W': ['.', ',', '/', '_'],
	'X': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'Z': ['"', "'", '~', 'T', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	
	'a': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'v', 'w', 'y'],
	'b': ['"', "'", 'b', 'h', 'k', 'l'],
	'c': ['"', "'", 'b', 'h', 'k', 'l'],
	'd': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'e': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'f': ['.', ',', '_', 'o'],
	'g': ['.', ',', '_', '!', 'b', 'f', 'h', 'k', 'l', 'o'],
	'h': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'i': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'l': ['"', "'", '~', 'T', 'W', 'Y', 'a', 'b', 'c', 'e', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'o', 'p', 'q', 's', 't', 'u', 'v', 'w', 'y'],
	'm': ['"', "'", 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'n': ['"', "'", 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'o': ['"', "'", 'b', 'h', 'k', 'l'],
	'r': ['b', 'h', 'k', 'l'],
	's': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	't': ['b', 'h', 'k', 'l'],
	'u': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'v': ['.', ',', '/', '_'],
	'z': ['"', "'", '~', 'T', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	
	'.': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'~': ['J', 'b', 'h', 'k', 'l']
#	'-': ['-'],
#	' ': ['f', 't']
}

const kern_pairs_2 = {
	'e': ['v'],
	'k': ['l']
}

@export var base_font: String = "res://assets/other/fonts_old/menagerieheartsm.ttf"
@export var already_kerned: String = "res://assets/other/fonts_old/menagerieheartsm_fixed.ttf"

@onready var font: FontFile = load(base_font)
@onready var font_kerned: FontFile = load(already_kerned)

var label_font = 'font'
var cache = 0
var vsize
var font_size

func _ready():
	vsize = font.get_size_cache_list(cache)[0]
	font_size = vsize.x
	print('size cache list', font_size)
	print('glyphs ', font.get_glyph_list(cache, vsize))
	$test_label.add_theme_font_override("font", font)
	var button = get_node("button")
	if button:
		print(button)
		button.connect("pressed", Callable(self, "process_pairs"))
	var button_switch = get_node("button_switch")
	if button_switch:
		button_switch.connect("pressed", Callable(self, "switch_fonts"))
	pass
	
func switch_fonts():
	$test_label.add_theme_font_override("font", font_kerned)

func kern(a, b, value):
	
	font.set_kerning(cache, font_size, Vector2i(a.unicode_at(0), b.unicode_at(0)), Vector2(value, 0))
	pass

func process_pairs():
	print('before kerning ', font.get_kerning_list(cache, font_size))
	# apply kernings
	for pair_first in kern_pairs:
		for pair_second in kern_pairs[pair_first]:
			kern(pair_first, pair_second, 1)
	# second pass: double these if necessary
	for pair_first in kern_pairs_2:
		for pair_second in kern_pairs_2[pair_first]:
			if (font.get_kerning(cache, font_size, Vector2i(pair_first.unicode_at(0), pair_second.unicode_at(0)))):
				kern(pair_first, pair_second, 2)
			else: kern(pair_first, pair_second, 1)
	$test_label.queue_redraw()
	print('after kerning', font.get_kerning_list(cache, font_size))
#	font.update_changes()
#	ResourceSaver.save("res://assets/fonts/menagerie_kerned.fnt", font)
