extends AnimationPlayer

var current = null
var queue = []
var facing = Vector2(0, 1) setget _update_facing
var loop_counter = 0

func _ready():
	connect("animation_finished", self, "_play_next")

# =========================================================================== #
#                               P L A Y B A C K                               #
# --------------------------------------------------------------------------- #

# calling this will immediately start playing the new anim. currently, this
# leaves the queue intact, so that previously queued animtions will resume
# after the current one is over. doesn't matter right now; can change it later
# if necessary.
func play_anim(anim_id = null, loops = null):
	if anim_id: current = anim_id
	if loops: loop_counter = loops
	play(str(current, "_", facing.y, "_", facing.x))

# --------------------------------------------------------------------------- #
func queue_anim(anim_id, loops = 0):
	queue.push_back({"id": anim_id, "loops": loops})
	if !current: _play_next()

# --------------------------------------------------------------------------- #

# we execute this on our own `animation_finished` signal, which passes the
# finished animation's id. no choice but to accept the argument, even though we
# don't need it.
func _play_next(old_anim = null):
	if loop_counter - 1 > 0:
		loop_counter = loop_counter - 1
	elif !queue.empty():
		var new_anim = queue.pop_front()
		current = new_anim.id
		loop_counter = new_anim.loops
	# else: current = "idle"
	play_anim()

# --------------------------------------------------------------------------- #

# each facing direction is a separate animation, so when our direction changes,
# we need to start playing the animation for the new one. in order to prevent
# it starting over from the beginning, we save our position from the old
# animation and seek to it in the new one.
func _update_facing(new_facing):
	# important because rotation produces values of -0, which throw off our
	# string interpolation (x and y should be either 0 or 1)
	facing = new_facing.abs()
	var anim_pos = current_animation_position
	current_animation = str(current, "_", facing.y, "_", facing.x)
	seek(anim_pos)


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

# creates four animations for a given `anim_id` - one in each facing direction
# - which are added to the AnimationPlayer for our sprite.
#
# the resulting animations are identified by a string in "{anim_id}_{y}_{x}"
# format, where y and x are either 0 or 1, and represent the monster's
# front-back and left-right orientation, respectively.
func add_anim(anim_id, anim_data):
	for y in anim_data.size():
		var anim = anim_data[y]
		if typeof(anim) == TYPE_ARRAY:
			for x in anim:
				_add_facing(anim[x], str(anim_id, "_", y, "_", x))
		else:
			_add_facing(anim, str(anim_id, "_", y, "_0"))
			_add_facing(anim, str(anim_id, "_", y, "_1"), true)

# --------------------------------------------------------------------------- #

# creates an animation for a specific facing direction, using an `anim_info`
# object from the monster's data definition, and adds it to the AnimationPlayer
# for our sprite.
func _add_facing(anim_info, anim_name, flip = false):
	# set the step and length parameters of the new animation depending on the
	# frame count and fps specified in the data definition. the `step` parameter
	# will determine the delay between frames when we insert them.
	var anim = Animation.new()
	anim.step = 1.0 / anim_info.fps
	anim.length = anim.step * anim_info.frames
#	anim.loop = anim_info.loop if anim_info.has("loop") else true
	anim.loop = false

	# add a track to set our texture to the spritesheet specified in the datafile
	anim.add_track(0)
	anim.track_set_path(0, ".:texture")
	var spritesheet = ResourceLoader.load(anim_info.sprites)
	anim.track_insert_key(0, 0.0, spritesheet)

	# add a track to set the hframes value of our texture
	anim.add_track(0)
	anim.track_set_path(1, ".:hframes")
	anim.track_insert_key(1, 0.0, anim_info.frames)

	# add a track to set whether our sprite is h-flipped (for right-facing
	# animations without unique spritesheets).
	# the data definition can optionally also specify whether the sprite should
	# be flipped - in that case, a true value for the `flip` argument will cancel
	# it out (boolean XOR).
	var should_flip = (anim_info.flip != flip
			if anim_info.has("flip") else flip)
	anim.add_track(0)
	anim.track_set_path(1, ".:flip_h")
	anim.track_insert_key(1, 0.0, should_flip)

	# add the animation track, with a keyframe for each frame in the spritesheet
	# at intervals determined by the `step` parameter we calculated earlier
	anim.add_track(0)
	anim.track_set_path(2, ".:frame")
	anim.track_set_interpolation_loop_wrap(2, false)
	for frame in range(anim_info.frames):
		var time = anim.step * frame
		anim.track_insert_key(2, time, frame)

	add_animation(anim_name, anim)
