extends Button

func initialize(m: Monster):
	$name.text = m.monster_name
	$sex.update(m)
	$loyalty/hearts.value = m.attributes.loyalty.lerp(0, 10)

#                              b g   c o l o r s                              #
# --------------------------------------------------------------------------- #
# the default background colors of the sex and loyalty panels are the same color
# as the background of the button when it is focused, so while the button is
# focused we update them to a lighter shade (the background color of the menu).

const default_color = Color("e6b5a1")
const focused_color = Color("fad6b8")

func _ready():
	focus_entered.connect(func(): update_bgcolors(true))
	focus_exited.connect(func(): update_bgcolors(false))

func update_bgcolors(focused: bool):
	for child in [$sex, $loyalty]:
		var panel_theme = child.get_theme_stylebox("panel")
		panel_theme.bg_color = focused_color if focused else default_color
