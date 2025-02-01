extends CanvasModulate

var tint_anim: Animation

const OUTLINE_COLOR = Color("fad6b8")

# we will probably want to tint locales too, so it should be
# independent from the garden.
const COLORS = {
	0: Color("342659"),  # night
	4: Color("473493"),  # dawn
	8: Color("db9ab4"),  # morning
	11: Color("fbffe6"),  # midday
	14: Color("fcdec3"),  # afternoon
	18: Color("e48b9a"),  # evening
	20: Color("b268dc"), # dusk
	23: Color("42336c")  # night 42336c
}
#var colors = {
#	0: Color("42336c"),  # still night / 0e0720
#	4: Color("473493"),  # still night / 6b3493
##	6: Color("db9ab4"),  # dawn
#	8: Color("db9ab4"),  # morning / dbc2b8
#	11: Color("fbffe6"),  # midday
#	14: Color("fcdec3"),  # afternoon
#	18: Color("e48b9a"),  # evening
#	20: Color("b268dc"), # dusk
#	23: Color("342659")  # night 42336c
#}

# --------------------------------------------------------------------------- #

func _process(_delta):
	var outline_shader = preload("res://outline_material.tres")
	var base_color = OUTLINE_COLOR * color
	outline_shader.set_shader_parameter(&'line_color',
		Color(base_color, 0.7).blend(Color(OUTLINE_COLOR, 0.1)) # Color(color, 0.5).blend(OUTLINE_COLOR)
	)

func _ready():
	load_colors()
	$anim.play("tint")
	Dispatcher.hour_changed.connect(sync_anim)

# --------------------------------------------------------------------------- #

func load_colors():
	tint_anim = $anim.get_animation("tint")
	tint_anim.loop_mode = Animation.LOOP_LINEAR
	tint_anim.set_length(Clock.HOURS_IN_DAY)
	var actual_seconds_in_hour: float = float(Clock.ACTUAL_SECONDS_IN_TICK) * float(Clock.TICKS_IN_HOUR)
	$anim.speed_scale = 1.0 / actual_seconds_in_hour
	for hour in COLORS:
		tint_anim.track_insert_key(0, hour, COLORS[hour])

func sync_anim():
	$anim.seek(float(Clock.hour))
