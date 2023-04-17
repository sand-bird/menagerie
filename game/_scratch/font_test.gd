extends Control

const kern_pairs_old = {
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

const kern_pairs = {
	'p': ['o'],
	'o': ['s']
}

const font_dir = "res://assets/font/"
const input_filename = "menagerie.ttf"
#var output_filename = str(input_filename.get_basename(), '-kerned.fnt')

var input_path = font_dir.path_join(input_filename)
#var output_path = font_dir.path_join(output_filename)

@onready var font: FontFile = load(input_path)
@onready var input_file = FileAccess.open(input_path, FileAccess.READ)
#var output_file: FileAccess

var label_font = 'font'
var cache = 0
var vsize
var font_size

func _ready():
	font_size = font.msdf_size
	print(font_size)
	$test_label.add_theme_font_override("font", font)
	$button.pressed.connect(process_pairs)
	$button2.pressed.connect(unkern)

func unkern():
	font.clear_kerning_map(0, font_size)

#var show_output = false
#func switch_fonts():
#	show_output = !show_output
#	var show_font = load(output_path) if show_output else font
	
#	$test_label.add_theme_font_override("font", show_font)
#	$button_switch.text = str('show ', 'original' if show_output else 'output')

func kern(a, b, value):
	var chars = Vector2i(a.unicode_at(0), b.unicode_at(0))
	var kern_string = str('kerning first=', chars.x, ' second=', chars.y, ' amount=', value)
	print(kern_string)
#	output_file.store_line(kern_string)
	font.set_kerning(0, font_size, chars, Vector2(value, 0))
	$test_label.add_theme_font_override("font", font)
	print('get kerning: ', font.get_kerning(cache, font_size, chars))

func process_pairs():
#	DirAccess.copy_absolute(input_path, output_path)
#	output_file = FileAccess.open(output_path, FileAccess.READ_WRITE)
#	output_file.seek_end()
#	print('before kern ', output_file.get_as_text())
	# apply kernings
	for pair_first in kern_pairs_old:
		for pair_second in kern_pairs_old[pair_first]:
			kern(pair_first, pair_second, -1)
	# second pass: double these if necessary
#	for pair_first in kern_pairs_2:
#		for pair_second in kern_pairs_2[pair_first]:
#			kern(pair_first, pair_second, 1)
#	output_file.close()
#	var kerned_font: FontFile = load(output_path)
#	var font_size = kerned_font.get_fixed_size()
#	print('fixed size ', font_size)
#	print('kerning pairs ', kerned_font.get_kerning_list(0, font_size))
#	var kerning = kerned_font.get_kerning(0, font_size, Vector2i(113, 117))
#	print('qu kerning ', kerning)
	# if !show_output: switch_fonts()
