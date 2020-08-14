extends CanvasModulate

# we will probably want to tint locales too, so it should be
# independent from the garden.
var colors = {
	3: Color("db9ab4"),  # dawn
	4: Color("dbc2b8"),  # morning
	5: Color("fbffe6"),  # midday
	7: Color("fcdec3"),  # afternoon
	9: Color("e48b9a"),  # evening
	10: Color("b268dc"), # dusk
	11: Color("66588c")  # night
}

# --------------------------------------------------------------------------- #

func _ready():
	load_colors()
	$anim.play("tint")

# --------------------------------------------------------------------------- #

func load_colors():
	var tint_anim = $anim.get_animation("tint")
	tint_anim.set_length(12)
	var seconds_in_hour = float(Time.ACTUAL_SECONDS_IN_TICK * Time.TICKS_IN_HOUR)
	$anim.playback_speed = 1.0 / seconds_in_hour
	for hour in colors:
		tint_anim.track_insert_key(0, hour, colors[hour])
