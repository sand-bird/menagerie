# script: hud

extends ReferenceFrame

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
	'T': ['.', ',', '/', '_', 'O', 'a', 'c', 'd', 'e', 'g', 'o', 's'],
	'U': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'V': ['.', ',', '/', '_'],
	'Y': ['.', ',', '/', '_', 'O', 'a', 'c', 'd', 'e', 'g', 'o', 's'],
	'W': ['.', ',', '/', '_'],
	'X': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	'Z': ['"', "'", '~', 'T', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
	
	'a': ['"', "'", '~', 'T', 'W', 'Y', 'b', 'f', 'h', 'i', 'j', 'k', 'l', 'm', 'p', 't', 'u', 'w', 'y'],
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
}

# 'j': ['g' -1]

const font = preload("res://assets/fonts/font.fnt")
const font_kerned = preload("res://assets/fonts/font_kerned.fnt")

func _ready():
	var button = get_node("button")
	if button:
		print(button)
		button.connect("pressed", self, "process_pairs")
	var button_switch = get_node("button_switch")
	if button_switch:
		button_switch.connect("pressed", self, "switch_fonts")
	pass
	
func switch_fonts():
	var label = get_node("test_label")
	label.add_font_override("font", font_kerned)

func kern(a, b, value):
	font.add_kerning_pair(a.ord_at(0), b.ord_at(0), value)
	pass

func process_pairs():
	for pair_first in kern_pairs:
		for pair_second in kern_pairs[pair_first]:
			kern(pair_first, pair_second, 1)
	font.update_changes()
	ResourceSaver.save("res://assets/fonts/font_kerned.fnt", font)
